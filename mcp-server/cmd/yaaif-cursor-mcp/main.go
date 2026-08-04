package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"yaaif-cursor-mcp/internal/auth"
	"yaaif-cursor-mcp/internal/client"
	"yaaif-cursor-mcp/internal/config"
	"yaaif-cursor-mcp/internal/tools"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

func main() {
	cfg := config.Load()
	logger := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: parseLevel(cfg.LogLevel)}))
	slog.SetDefault(logger)

	store, err := auth.NewStore(cfg.CursorHome)
	if err != nil {
		logger.Error("failed to init session store", "error", err)
		os.Exit(1)
	}

	scopes := splitScopes(cfg.OIDCScopes)
	authClient := auth.NewClient(auth.OIDCConfig{
		Authority: cfg.OIDCAuthority,
		ClientID:  cfg.OIDCClientID,
		Scopes:    scopes,
	}, store)
	api := client.New(cfg, authClient)
	registry := tools.NewRegistry(cfg, authClient, api, logger)

	server := mcp.NewServer(
		&mcp.Implementation{
			Name:    "yaaif-cursor",
			Version: "0.1.0",
		},
		&mcp.ServerOptions{Logger: logger},
	)
	registry.Register(server)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	logger.Info("yaaif cursor mcp ready",
		"oidc_authority", cfg.OIDCAuthority,
		"api_base", cfg.APIBaseURL,
		"agent_base", cfg.AgentBaseURL,
		"session_store", store.Path(),
	)

	transport := &mcp.IOTransport{
		Reader: os.Stdin,
		Writer: flushWriter{file: os.Stdout},
	}
	if err := server.Run(ctx, transport); err != nil {
		logger.Error("server failed", "error", err)
		os.Exit(1)
	}
	_, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
}

type flushWriter struct {
	file *os.File
}

func (w flushWriter) Write(p []byte) (int, error) {
	n, err := w.file.Write(p)
	if n > 0 {
		_ = w.file.Sync()
	}
	return n, err
}

func (w flushWriter) Close() error { return nil }

func parseLevel(level string) slog.Level {
	switch strings.ToUpper(strings.TrimSpace(level)) {
	case "DEBUG":
		return slog.LevelDebug
	case "WARN", "WARNING":
		return slog.LevelWarn
	case "ERROR":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

func splitScopes(raw string) []string {
	parts := strings.Fields(raw)
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	if len(out) == 0 {
		return []string{"openid", "profile", "email", "offline_access"}
	}
	return out
}
