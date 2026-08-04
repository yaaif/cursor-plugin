# YAAIF Cursor Plugin

Cursor plugin that authenticates to YAAIF and exposes MCP tools + agent skills to:

1. Create skills and load them into the tenant catalog
2. Scaffold / deploy MCP servers and register tools
3. Create ambient workflows and test-trigger them

## Layout

```text
integrations/cursor-plugin/
├── .cursor-plugin/plugin.json
├── mcp.json
├── rules/yaaif-platform.mdc
├── skills/
│   ├── yaaif-auth/
│   ├── yaaif-create-skill/
│   ├── yaaif-create-mcp/
│   └── yaaif-create-ambient/
└── mcp-server/                 # stdio MCP bridge (Go)
```

## Local install

```bash
ln -s /Users/kn/Works/BeezLabs/yaaif-platform/integrations/cursor-plugin \
  ~/.cursor/plugins/local/yaaif
```

Reload Cursor (`Developer: Reload Window`). Configure env for the MCP server (Customize → MCP / plugin env), or export before launching Cursor:

```bash
export YAAIF_OIDC_AUTHORITY=http://localhost:8080/auth/realms/yaaif
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_API_BASE_URL=http://localhost:8084
export YAAIF_AGENT_BASE_URL=http://localhost:8086
export YAAIF_DEFAULT_TENANT_ID=<tenant-uuid>   # optional
```

Copy [`mcp-server/.env.example`](mcp-server/.env.example) to `mcp-server/.env` for `go run` defaults.

### Build the bridge (optional)

```bash
cd integrations/cursor-plugin/mcp-server
go build -o bin/yaaif-cursor-mcp ./cmd/yaaif-cursor-mcp
```

`run.sh` prefers the built binary, otherwise `go run`.

## Auth

- Keycloak public client: `yaaif-cursor` (PKCE S256)
- Tokens cached at `~/.yaaif/cursor/session.json`
- API calls send `Authorization: Bearer` + `X-Tenant-ID`

First agent step: `yaaif_login` → `yaaif_set_tenant` → `yaaif_whoami`.

## MCP tool groups

| Group | Tools |
|-------|--------|
| Auth | `yaaif_login`, `yaaif_logout`, `yaaif_whoami`, `yaaif_list_tenants`, `yaaif_set_tenant` |
| Skills | `yaaif_skill_create`, `yaaif_skill_write_file`, `yaaif_skill_enable`, `yaaif_skill_map_agents`, `yaaif_skill_validate`, `yaaif_skill_refresh`, `yaaif_skill_runtime_reload`, `yaaif_skill_list`, `yaaif_skill_get` |
| MCP deploy | `yaaif_mcp_scaffold`, `yaaif_mcp_deployment_create`, `yaaif_mcp_deployment_deploy`, `yaaif_mcp_deployment_register`, `yaaif_mcp_deployment_status`, `yaaif_mcp_deployment_logs`, `yaaif_mcp_link_or_create`, `yaaif_mcp_server_refresh`, `yaaif_mcp_tools_list` |
| Ambient | `yaaif_agent_create`, `yaaif_ambient_agent_create`, `yaaif_ambient_workflow_create`, `yaaif_ambient_workflow_update`, `yaaif_ambient_workflow_get`, `yaaif_ambient_workflow_list`, `yaaif_ambient_test_trigger`, `yaaif_ambient_runs_list`, `yaaif_ambient_run_get` |

## Docs

- [Install & smoke checklist](docs/install-and-smoke.md)
- Platform Keycloak: [`docs/auth/keycloak.md`](../../docs/auth/keycloak.md)
