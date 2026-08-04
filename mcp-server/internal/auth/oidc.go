package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"golang.org/x/oauth2"
)

type OIDCConfig struct {
	Authority string
	ClientID  string
	Scopes    []string
}

type Client struct {
	cfg   OIDCConfig
	store *Store
}

func NewClient(cfg OIDCConfig, store *Store) *Client {
	return &Client{cfg: cfg, store: store}
}

func (c *Client) Login(ctx context.Context) (*Session, error) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return nil, fmt.Errorf("start callback listener: %w", err)
	}
	defer listener.Close()

	port := listener.Addr().(*net.TCPAddr).Port
	redirectURI := fmt.Sprintf("http://127.0.0.1:%d/callback", port)

	verifier, challenge, err := newPKCE()
	if err != nil {
		return nil, err
	}
	state, err := randomURLString(24)
	if err != nil {
		return nil, err
	}

	oauthCfg := c.oauthConfig(redirectURI)
	authURL := oauthCfg.AuthCodeURL(
		state,
		oauth2.SetAuthURLParam("code_challenge", challenge),
		oauth2.SetAuthURLParam("code_challenge_method", "S256"),
	)

	codeCh := make(chan string, 1)
	errCh := make(chan error, 1)
	mux := http.NewServeMux()
	mux.HandleFunc("/callback", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Query().Get("state") != state {
			http.Error(w, "invalid state", http.StatusBadRequest)
			errCh <- errors.New("invalid oauth state")
			return
		}
		if errMsg := r.URL.Query().Get("error"); errMsg != "" {
			desc := r.URL.Query().Get("error_description")
			http.Error(w, errMsg, http.StatusBadRequest)
			errCh <- fmt.Errorf("oauth error: %s (%s)", errMsg, desc)
			return
		}
		code := r.URL.Query().Get("code")
		if code == "" {
			http.Error(w, "missing code", http.StatusBadRequest)
			errCh <- errors.New("missing authorization code")
			return
		}
		_, _ = io.WriteString(w, "<html><body><h2>YAAIF login complete</h2><p>You can close this window and return to Cursor.</p></body></html>")
		codeCh <- code
	})

	srv := &http.Server{Handler: mux}
	go func() { _ = srv.Serve(listener) }()
	defer func() {
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		_ = srv.Shutdown(shutdownCtx)
	}()

	if err := openBrowser(authURL); err != nil {
		return nil, fmt.Errorf("open browser for login (%s): %w", authURL, err)
	}

	var code string
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	case err := <-errCh:
		return nil, err
	case code = <-codeCh:
	case <-time.After(5 * time.Minute):
		return nil, errors.New("login timed out waiting for browser callback")
	}

	tok, err := oauthCfg.Exchange(
		ctx,
		code,
		oauth2.SetAuthURLParam("code_verifier", verifier),
	)
	if err != nil {
		return nil, fmt.Errorf("token exchange: %w", err)
	}

	sess := &Session{
		Tokens: tokenSetFromOAuth(tok),
	}
	if idTok, ok := tok.Extra("id_token").(string); ok {
		sess.Tokens.IDToken = idTok
		subj, email, name := parseIDTokenClaims(idTok)
		sess.Subject = subj
		sess.Email = email
		sess.Name = name
	}
	if err := c.store.Save(sess); err != nil {
		return nil, err
	}
	return sess, nil
}

func (c *Client) Logout() error {
	return c.store.Clear()
}

func (c *Client) Session() (*Session, error) {
	return c.store.Load()
}

func (c *Client) SetTenant(tenantID string) (*Session, error) {
	sess, err := c.store.Load()
	if err != nil {
		return nil, err
	}
	if sess == nil || sess.Tokens.AccessToken == "" {
		return nil, errors.New("not authenticated; call yaaif_login first")
	}
	sess.TenantID = strings.TrimSpace(tenantID)
	if err := c.store.Save(sess); err != nil {
		return nil, err
	}
	return sess, nil
}

func (c *Client) AccessToken(ctx context.Context) (string, *Session, error) {
	sess, err := c.store.Load()
	if err != nil {
		return "", nil, err
	}
	if sess == nil || sess.Tokens.AccessToken == "" {
		return "", nil, errors.New("not authenticated; call yaaif_login first")
	}
	if time.Until(sess.Tokens.Expiry) > 45*time.Second {
		return sess.Tokens.AccessToken, sess, nil
	}
	if sess.Tokens.RefreshToken == "" {
		return "", nil, errors.New("access token expired; call yaaif_login again")
	}
	refreshed, err := c.refresh(ctx, sess)
	if err != nil {
		return "", nil, err
	}
	return refreshed.Tokens.AccessToken, refreshed, nil
}

func (c *Client) refresh(ctx context.Context, sess *Session) (*Session, error) {
	form := url.Values{}
	form.Set("grant_type", "refresh_token")
	form.Set("refresh_token", sess.Tokens.RefreshToken)
	form.Set("client_id", c.cfg.ClientID)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.tokenURL(), strings.NewReader(form.Encode()))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 300 {
		return nil, fmt.Errorf("refresh token failed (%d): %s", resp.StatusCode, string(body))
	}
	var tok oauth2.Token
	var raw map[string]any
	if err := json.Unmarshal(body, &raw); err != nil {
		return nil, err
	}
	access, _ := raw["access_token"].(string)
	refresh, _ := raw["refresh_token"].(string)
	tokenType, _ := raw["token_type"].(string)
	expiresIn, _ := raw["expires_in"].(float64)
	idToken, _ := raw["id_token"].(string)
	tok.AccessToken = access
	tok.RefreshToken = refresh
	tok.TokenType = tokenType
	if expiresIn > 0 {
		tok.Expiry = time.Now().Add(time.Duration(expiresIn) * time.Second)
	}
	if refresh == "" {
		tok.RefreshToken = sess.Tokens.RefreshToken
	}
	sess.Tokens = tokenSetFromOAuth(&tok)
	if idToken != "" {
		sess.Tokens.IDToken = idToken
		subj, email, name := parseIDTokenClaims(idToken)
		if subj != "" {
			sess.Subject = subj
		}
		if email != "" {
			sess.Email = email
		}
		if name != "" {
			sess.Name = name
		}
	}
	if err := c.store.Save(sess); err != nil {
		return nil, err
	}
	return sess, nil
}

func (c *Client) oauthConfig(redirectURI string) *oauth2.Config {
	return &oauth2.Config{
		ClientID:    c.cfg.ClientID,
		RedirectURL: redirectURI,
		Scopes:      c.cfg.Scopes,
		Endpoint: oauth2.Endpoint{
			AuthURL:  c.authority() + "/protocol/openid-connect/auth",
			TokenURL: c.tokenURL(),
		},
	}
}

func (c *Client) authority() string {
	return strings.TrimRight(c.cfg.Authority, "/")
}

func (c *Client) tokenURL() string {
	return c.authority() + "/protocol/openid-connect/token"
}

func tokenSetFromOAuth(tok *oauth2.Token) TokenSet {
	return TokenSet{
		AccessToken:  tok.AccessToken,
		RefreshToken: tok.RefreshToken,
		TokenType:    tok.TokenType,
		Expiry:       tok.Expiry,
	}
}

func newPKCE() (verifier, challenge string, err error) {
	verifier, err = randomURLString(32)
	if err != nil {
		return "", "", err
	}
	sum := sha256.Sum256([]byte(verifier))
	challenge = base64.RawURLEncoding.EncodeToString(sum[:])
	return verifier, challenge, nil
}

func randomURLString(n int) (string, error) {
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}

func parseIDTokenClaims(idToken string) (subject, email, name string) {
	parts := strings.Split(idToken, ".")
	if len(parts) < 2 {
		return "", "", ""
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return "", "", ""
	}
	var claims map[string]any
	if err := json.Unmarshal(payload, &claims); err != nil {
		return "", "", ""
	}
	subject, _ = claims["sub"].(string)
	email, _ = claims["email"].(string)
	name, _ = claims["name"].(string)
	if name == "" {
		name, _ = claims["preferred_username"].(string)
	}
	return subject, email, name
}

func openBrowser(rawURL string) error {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "darwin":
		cmd = exec.Command("open", rawURL)
	case "windows":
		cmd = exec.Command("rundll32", "url.dll,FileProtocolHandler", rawURL)
	default:
		cmd = exec.Command("xdg-open", rawURL)
	}
	return cmd.Start()
}
