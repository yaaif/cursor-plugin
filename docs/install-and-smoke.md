# Install and smoke checklist

## Platform prerequisites

1. Keycloak realm includes public client `yaaif-cursor` (see `docker/keycloak/yaaif-realm.json`).
2. Local stack running: postgres, Keycloak, api-server (`:8084`), agent-service (`:8086`), deployment-service (for MCP deploy).
3. User can sign in and belongs to a tenant.

Re-import / recreate the Keycloak realm after pulling the client change, or add the client manually in the Keycloak admin console with PKCE S256 and redirect `http://127.0.0.1:*`.

## Plugin install

```bash
ln -sf "$PWD/integrations/cursor-plugin" ~/.cursor/plugins/local/yaaif
```

Reload Cursor. Confirm Customize shows plugin `yaaif` with skills + MCP server.

## Env

```bash
export YAAIF_OIDC_AUTHORITY=http://localhost:8080/auth/realms/yaaif
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_API_BASE_URL=http://localhost:8084
export YAAIF_AGENT_BASE_URL=http://localhost:8086
# export YAAIF_DEFAULT_TENANT_ID=...
```

Build optional binary:

```bash
cd integrations/cursor-plugin/mcp-server
go build -o bin/yaaif-cursor-mcp ./cmd/yaaif-cursor-mcp
```

## Smoke flow

In Cursor Agent (with plugin MCP enabled):

1. **Auth** — `yaaif_login` → `yaaif_list_tenants` → `yaaif_set_tenant` → `yaaif_whoami`
2. **Skill** — `yaaif_skill_create` lean skill → `yaaif_skill_enable` → `yaaif_skill_map_agents` → `yaaif_skill_refresh` → `yaaif_skill_runtime_reload`
3. **MCP** — either:
   - Full: `yaaif_mcp_scaffold` → build/push image → `yaaif_mcp_deployment_create` → `deploy` → `register` → `yaaif_mcp_tools_list`
   - Fallback: `yaaif_mcp_link_or_create` against an already-running local MCP endpoint
4. **Ambient** — `yaaif_agent_create` (`agent_type=workflow`) → `yaaif_ambient_agent_create` → `yaaif_ambient_workflow_create` (linear graph) → `yaaif_ambient_test_trigger` → `yaaif_ambient_runs_list`

## Offline compile check

```bash
cd integrations/cursor-plugin/mcp-server
go test ./...
go build -o bin/yaaif-cursor-mcp ./cmd/yaaif-cursor-mcp
```
