---
name: yaaif-create-mcp
description: >-
  Scaffold a YAA\F MCP server, deploy via mcp-deployments, and register tools.
  For customer/partner workspaces without monorepo access.
---

# Create MCP tools and deploy on YAA\F

```
Task Progress:
- [ ] 1. Auth + tenant
- [ ] 2. Design tool contracts
- [ ] 3. Scaffold service
- [ ] 4. Build/push image
- [ ] 5. Create + deploy + register
- [ ] 6. Verify catalog
```

## Prerequisites

`yaaif-auth` completed.

## Design

Write short contracts (name, description, inputs). Names become catalog names — keep them stable snake_case. See [references/templates.md](references/templates.md).

## Scaffold

`yaaif_mcp_scaffold` with kebab `name` (no `-mcp-service` suffix), `language` `go`|`python`, and absolute `workspace_root`.

Implement tools, build/push an image the customer's deployment-service can pull.

## Full deploy

1. `yaaif_mcp_deployment_create` (`auto_register` + `auto_import_tools` true)
2. `yaaif_mcp_deployment_deploy`
3. Poll `yaaif_mcp_deployment_status` / logs
4. `yaaif_mcp_deployment_register` if needed

## Fallback

`yaaif_mcp_link_or_create` against an already-running endpoint; optional `yaaif_mcp_server_refresh`.

## Verify

`yaaif_mcp_tools_list` — confirm exact tool names before wiring skills/workflows.
