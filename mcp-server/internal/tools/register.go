package tools

import (
	"context"
	"log/slog"

	"yaaif-cursor-mcp/internal/auth"
	"yaaif-cursor-mcp/internal/client"
	"yaaif-cursor-mcp/internal/config"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

type Registry struct {
	cfg    config.Config
	auth   *auth.Client
	api    *client.API
	logger *slog.Logger
}

func NewRegistry(cfg config.Config, authClient *auth.Client, api *client.API, logger *slog.Logger) *Registry {
	if logger == nil {
		logger = slog.Default()
	}
	return &Registry{cfg: cfg, auth: authClient, api: api, logger: logger}
}

func (r *Registry) Register(server *mcp.Server) {
	r.registerAuth(server)
	r.registerSkills(server)
	r.registerAmbient(server)
	r.registerMCP(server)
}

func addTool(
	server *mcp.Server,
	name, description string,
	inputSchema map[string]any,
	handler func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error),
) {
	mcp.AddTool(server, &mcp.Tool{
		Name:        name,
		Description: description,
		InputSchema: inputSchema,
	}, func(ctx context.Context, _ *mcp.CallToolRequest, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
		if args == nil {
			args = map[string]any{}
		}
		return handler(ctx, args)
	})
}
