package client

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"yaaif-cursor-mcp/internal/auth"
	"yaaif-cursor-mcp/internal/config"
)

type API struct {
	cfg    config.Config
	auth   *auth.Client
	http   *http.Client
}

func New(cfg config.Config, authClient *auth.Client) *API {
	return &API{
		cfg:  cfg,
		auth: authClient,
		http: &http.Client{Timeout: 120 * time.Second},
	}
}

func (a *API) Config() config.Config { return a.cfg }

type RequestOptions struct {
	Query url.Values
}

func (a *API) AgentJSON(ctx context.Context, method, path string, body any, out any) error {
	return a.doJSON(ctx, a.cfg.AgentBaseURL, method, path, body, out)
}

func (a *API) APIJSON(ctx context.Context, method, path string, body any, out any) error {
	return a.doJSON(ctx, a.cfg.APIBaseURL, method, path, body, out)
}

func (a *API) doJSON(ctx context.Context, base, method, path string, body any, out any) error {
	token, sess, err := a.auth.AccessToken(ctx)
	if err != nil {
		return err
	}
	tenantID := strings.TrimSpace(sess.TenantID)
	if tenantID == "" {
		tenantID = strings.TrimSpace(a.cfg.DefaultTenantID)
	}
	if tenantID == "" && !isTenantBootstrapPath(path) {
		return fmt.Errorf("tenant not set; call yaaif_set_tenant or set YAAIF_DEFAULT_TENANT_ID")
	}

	var reader io.Reader
	if body != nil {
		raw, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = bytes.NewReader(raw)
	}

	full := strings.TrimRight(base, "/") + "/" + strings.TrimLeft(path, "/")
	req, err := http.NewRequestWithContext(ctx, method, full, reader)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Accept", "application/json")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if tenantID != "" {
		req.Header.Set("X-Tenant-ID", tenantID)
	}

	resp, err := a.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	if resp.StatusCode >= 300 {
		return fmt.Errorf("%s %s failed (%d): %s", method, path, resp.StatusCode, strings.TrimSpace(string(respBody)))
	}
	if out == nil || resp.StatusCode == http.StatusNoContent || len(bytes.TrimSpace(respBody)) == 0 {
		return nil
	}
	if err := json.Unmarshal(respBody, out); err != nil {
		return fmt.Errorf("decode response for %s: %w; body=%s", path, err, string(respBody))
	}
	return nil
}

func isTenantBootstrapPath(path string) bool {
	p := strings.TrimSpace(path)
	return strings.HasPrefix(p, "/api/users/me/tenants") ||
		strings.HasPrefix(p, "/api/rbac/me") ||
		strings.HasPrefix(p, "/api/users/me/last-tenant") ||
		strings.HasPrefix(p, "/api/users/me/active-tenant")
}
