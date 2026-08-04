package config

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	OIDCAuthority   string
	OIDCClientID    string
	OIDCScopes      string
	APIBaseURL      string
	AgentBaseURL    string
	DefaultTenantID string
	CursorHome      string
	LogLevel        string
}

func Load() Config {
	_ = godotenv.Load()
	_ = godotenv.Load(".env")

	home, _ := os.UserHomeDir()
	cursorHome := strings.TrimSpace(os.Getenv("YAAIF_CURSOR_HOME"))
	if cursorHome == "" {
		cursorHome = filepath.Join(home, ".yaaif", "cursor")
	}

	return Config{
		OIDCAuthority:   strings.TrimRight(envOr("YAAIF_OIDC_AUTHORITY", "http://localhost:8080/auth/realms/yaaif"), "/"),
		OIDCClientID:    envOr("YAAIF_OIDC_CLIENT_ID", "yaaif-cursor"),
		OIDCScopes:      envOr("YAAIF_OIDC_SCOPES", "openid profile email offline_access"),
		APIBaseURL:      strings.TrimRight(envOr("YAAIF_API_BASE_URL", "http://localhost:8084"), "/"),
		AgentBaseURL:    strings.TrimRight(envOr("YAAIF_AGENT_BASE_URL", "http://localhost:8086"), "/"),
		DefaultTenantID: strings.TrimSpace(os.Getenv("YAAIF_DEFAULT_TENANT_ID")),
		CursorHome:      cursorHome,
		LogLevel:        envOr("YAAIF_LOG_LEVEL", "INFO"),
	}
}

func envOr(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}
