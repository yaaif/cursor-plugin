package tools

import (
	"log/slog"
	"os"
	"testing"

	"yaaif-cursor-mcp/internal/auth"
	"yaaif-cursor-mcp/internal/client"
	"yaaif-cursor-mcp/internal/config"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

func TestRegisterAllTools(t *testing.T) {
	cfg := config.Config{
		OIDCAuthority: "http://localhost:8080/auth/realms/yaaif",
		OIDCClientID:  "yaaif-cursor",
		APIBaseURL:    "http://localhost:8084",
		AgentBaseURL:  "http://localhost:8086",
		CursorHome:    t.TempDir(),
	}
	store, err := auth.NewStore(cfg.CursorHome)
	if err != nil {
		t.Fatal(err)
	}
	authClient := auth.NewClient(auth.OIDCConfig{
		Authority: cfg.OIDCAuthority,
		ClientID:  cfg.OIDCClientID,
		Scopes:    []string{"openid"},
	}, store)
	api := client.New(cfg, authClient)
	reg := NewRegistry(cfg, authClient, api, slog.New(slog.NewTextHandler(os.Stderr, nil)))

	server := mcp.NewServer(&mcp.Implementation{Name: "test", Version: "0"}, nil)
	reg.Register(server)
}
