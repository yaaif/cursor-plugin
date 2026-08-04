package tools

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

func (r *Registry) registerAuth(server *mcp.Server) {
	addTool(server, "yaaif_login", "Open a browser PKCE login against YAAIF Keycloak and persist tokens.",
		schemaObject(map[string]any{}),
		func(ctx context.Context, _ map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			sess, err := r.auth.Login(ctx)
			if err != nil {
				return nil, nil, err
			}
			if sess.TenantID == "" && r.cfg.DefaultTenantID != "" {
				sess, err = r.auth.SetTenant(r.cfg.DefaultTenantID)
				if err != nil {
					return nil, nil, err
				}
			}
			return textResult("Logged in to YAAIF.", map[string]any{
				"email":     sess.Email,
				"name":      sess.Name,
				"subject":   sess.Subject,
				"tenant_id": sess.TenantID,
				"expires":   sess.Tokens.Expiry.Format(time.RFC3339),
			})
		})

	addTool(server, "yaaif_logout", "Clear the local YAAIF Cursor session.",
		schemaObject(map[string]any{}),
		func(ctx context.Context, _ map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			if err := r.auth.Logout(); err != nil {
				return nil, nil, err
			}
			return textResult("Logged out.", map[string]any{"logged_out": true})
		})

	addTool(server, "yaaif_whoami", "Return current auth session, RBAC identity, and active tenant.",
		schemaObject(map[string]any{}),
		func(ctx context.Context, _ map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			sess, err := r.auth.Session()
			if err != nil {
				return nil, nil, err
			}
			if sess == nil || sess.Tokens.AccessToken == "" {
				return textResult("Not authenticated.", map[string]any{"authenticated": false})
			}
			var me any
			_ = r.api.APIJSON(ctx, "GET", "/api/rbac/me", nil, &me)
			var tenants any
			_ = r.api.APIJSON(ctx, "GET", "/api/users/me/tenants", nil, &tenants)
			return textResult("Authenticated YAAIF session.", map[string]any{
				"authenticated": true,
				"email":         sess.Email,
				"name":          sess.Name,
				"subject":       sess.Subject,
				"tenant_id":     firstNonEmpty(sess.TenantID, r.cfg.DefaultTenantID),
				"expires":       sess.Tokens.Expiry.Format(time.RFC3339),
				"rbac_me":       me,
				"tenants":       tenants,
				"api_base":      r.cfg.APIBaseURL,
				"agent_base":    r.cfg.AgentBaseURL,
			})
		})

	addTool(server, "yaaif_list_tenants", "List tenants available to the signed-in user.",
		schemaObject(map[string]any{}),
		func(ctx context.Context, _ map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			var tenants any
			if err := r.api.APIJSON(ctx, "GET", "/api/users/me/tenants", nil, &tenants); err != nil {
				return nil, nil, err
			}
			return textResult("Listed tenants.", map[string]any{"tenants": tenants})
		})

	addTool(server, "yaaif_set_tenant", "Set the active tenant id for subsequent YAAIF API calls.",
		schemaObject(map[string]any{
			"tenant_id": map[string]any{"type": "string", "description": "Tenant UUID"},
		}, "tenant_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			tenantID, err := requireString(args, "tenant_id")
			if err != nil {
				return nil, nil, err
			}
			sess, err := r.auth.SetTenant(tenantID)
			if err != nil {
				return nil, nil, err
			}
			// Best-effort active-tenant sync on api-server.
			_ = r.api.APIJSON(ctx, "POST", "/api/users/me/active-tenant", map[string]any{
				"tenant_id": tenantID,
			}, nil)
			return textResult(fmt.Sprintf("Active tenant set to %s.", tenantID), map[string]any{
				"tenant_id": sess.TenantID,
				"email":     sess.Email,
			})
		})
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return strings.TrimSpace(v)
		}
	}
	return ""
}
