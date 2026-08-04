---
name: yaaif-create-mcp
description: >-
  Scaffold a YAAIF MCP server, deploy it via mcp-deployments, and register tools
  in the tenant catalog. Use when the user asks to create/deploy MCP tools on
  YAAIF from Cursor.
---

# Create MCP tools and deploy on YAAIF

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

Run skill `yaaif-auth` first.

## Design

Write a short tool contract list (name, description, inputs). Names become catalog names — keep them stable and snake_case.

Templates:

- Go: https://github.com/yaaif/mcp-server-templates-go
- Python: https://github.com/yaaif/mcp-server-templates-py

Domain persistence should use context-store when applicable (see platform MCP README).

## Scaffold

Call `yaaif_mcp_scaffold` with:

- `name`: kebab id without `-mcp-service`
- `language`: `go` or `python`
- `workspace_root`: absolute workspace path
- `target_dir`: usually `mcp-servers`

Implement tools in the scaffolded tree. Build and push a container image the deployment-service can pull.

## Full deploy path

1. `yaaif_mcp_deployment_create` with:
   - `name`, `image`
   - `deployment_method`: `docker_compose` or `kubernetes_gitops`
   - `container_port` (often 8080)
   - `mcp_path`: `/mcp`
   - `endpoint_mode`: `docker_name` (local compose) unless host override needed
   - `transport_type`: `HTTP`
   - `auto_register`: true
   - `auto_import_tools`: true
2. `yaaif_mcp_deployment_deploy` with returned `deployment_id`.
3. Poll `yaaif_mcp_deployment_status` (and `yaaif_mcp_deployment_logs` on failure).
4. If tools are not imported, `yaaif_mcp_deployment_register`.

## Fallback (endpoint already running)

Use `yaaif_mcp_link_or_create` per tool and/or `yaaif_mcp_server_refresh` after creating a server entry.

## Verify

`yaaif_mcp_tools_list` with `q` matching the tool prefix. Confirm exact names before wiring skills/workflows.

## Hand-off

Report: service path, image tag, deployment id, registered tool names.
