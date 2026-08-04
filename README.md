# YAAIF Cursor Plugin

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Official Cursor plugin for **customers and partner developers** to build on [YAAIF](https://yaaif.com):

1. Authenticate to a YAAIF environment (Keycloak OIDC + PKCE)
2. Create skills and load them into the tenant catalog
3. Scaffold / deploy MCP servers and register tools
4. Create ambient workflows and test-trigger them

**Repository:** https://github.com/yaaif/cursor-plugin  
**Marketplace name:** `yaaif`

This repo is also consumed by [yaaif-platform](https://github.com/yaaif/yaaif-platform) as a git submodule at `integrations/cursor-plugin`.

## Install

### Cursor Marketplace / Team Marketplace

Install **yaaif**, then configure plugin variables (Customize → Plugins → Configure). Defaults point at hosted YAAIF:

```bash
export YAAIF_OIDC_AUTHORITY=https://platform.yaaif.ai/auth/realms/yaaif
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_API_BASE_URL=https://platform.yaaif.ai
export YAAIF_AGENT_BASE_URL=https://platform.yaaif.ai/agent-service
export YAAIF_CONTROL_PLANE_BASE_URL=https://platform.yaaif.ai/control-plane-service
export YAAIF_APPROVAL_BASE_URL=https://platform.yaaif.ai/approval-service
export YAAIF_DEFAULT_TENANT_ID=<tenant-uuid>   # optional
```

| Variable | Default |
|----------|---------|
| `YAAIF_PLATFORM_PROFILE` | `hosted` (`local-hybrid` / `local` / custom id) |
| `YAAIF_OIDC_AUTHORITY` | `https://platform.yaaif.ai/auth/realms/yaaif` |
| `YAAIF_API_BASE_URL` | `https://platform.yaaif.ai` |
| `YAAIF_AGENT_BASE_URL` | `https://platform.yaaif.ai/agent-service` |
| `YAAIF_CONTROL_PLANE_BASE_URL` | `https://platform.yaaif.ai/control-plane-service` |
| `YAAIF_APPROVAL_BASE_URL` | `https://platform.yaaif.ai/approval-service` |
| `YAAIF_DEFAULT_TENANT_ID` | optional UUID |
| `YAAIF_OIDC_CLIENT_ID` | `yaaif-cursor` |

Prefer **`yaaif_platform_use`** + **`yaaif_ensure_session`** over hand-editing every URL.

Your YAAIF operator must enable the public Keycloak client `yaaif-cursor` (see platform script `scripts/keycloak/ensure-yaaif-cursor-client.sh`).

### Local Traefik (`platform.yaaif.local`)

Match OIDC to Keycloak `KC_HOSTNAME`. Hybrid stacks (tunnel issuer `.com`, APIs `.local`) should use:

```bash
export YAAIF_OIDC_AUTHORITY=https://platform.yaaif.com/auth/realms/yaaif
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_API_BASE_URL=https://platform.yaaif.local
export YAAIF_AGENT_BASE_URL=https://platform.yaaif.local/agent-service
export YAAIF_DEFAULT_TENANT_ID=<tenant-uuid>   # optional
```

Do not point OIDC at `.local` if Keycloak’s hostname is `.com` — that breaks the login cookie (`Restart login cookie not found`). See [configure-environment.md](docs/configure-environment.md).

### Local symlink (developers)

```bash
git clone https://github.com/yaaif/cursor-plugin.git
cd cursor-plugin/packages/mcp && npm install && npm run build && cd ../..
ln -sf "$PWD" ~/.cursor/plugins/local/yaaif
```

Reload Cursor. For local platform stacks, use the `platform.yaaif.local` exports above (see [configure-environment.md](docs/configure-environment.md)).

## Runtime

MCP bridge is TypeScript (`packages/mcp`), launched via:

```json
{ "command": "node", "args": ["packages/mcp/dist/cli.js"] }
```

After npm publish:

```bash
npx -y @yaaif/cursor-mcp@0.7.0
```

Requires **Node.js ≥ 20**. No Go toolchain.

## Skills and commands

| Skill / command | Purpose |
|-----------------|--------|
| `yaaif-auth` / `/yaaif-login` | Platform profile + login + tenant |
| `yaaif-doctor` / `/yaaif-doctor` | Connectivity / TLS / auth diagnostics |
| `yaaif-plan-usecase` / `/yaaif-plan` | Use-case plan → approve → create agents/skills/workflows |
| `yaaif-create-skill` / `/yaaif-new-skill` | Author + load skill (prefers platform local lifecycle tools) |
| `yaaif-platform-tools` / `/yaaif-platform-tools` | Discover/call agent-service built-in local tools |
| `yaaif-create-mcp` / `/yaaif-new-mcp` | Scaffold + deploy MCP |
| `yaaif-create-ambient` / `/yaaif-new-workflow` | Ambient workflows |

### Read / browse tools

| Tool | Purpose |
|------|--------|
| `yaaif_catalog_overview` | Snapshot of agents, skills, MCPs, ambient, local tools |
| `yaaif_local_tools_list` / `yaaif_local_tool_get` / `yaaif_local_tool_call` | Agent-service built-in local tools (skill lifecycle, files, ambient, …) |
| `yaaif_dev_session_ensure` | Cursor authoring session for `files_*` / state locals |
| `yaaif_skill_validate_module` / `yaaif_skill_develop` / `yaaif_skill_guided_draft` | Convenience wrappers for skill lifecycle locals |
| `yaaif_doctor` | Profile + OIDC + health + session + catalog + local tools |
| `yaaif_plan_verify` / `yaaif_plan_dry_run` / `yaaif_plan_execution_*` | Plan verify / dry-run / resume |
| `yaaif_platform_export` | Shell exports + Cursor variables JSON |
| `yaaif_agent_list` / `yaaif_agent_get` / `yaaif_agent_create` / `yaaif_agent_update` | Agents |
| `yaaif_skill_map_agents_merge` | Safe skill↔agent mapping (union) |
| `yaaif_skill_list` / `yaaif_skill_get` / `yaaif_skill_read_file` / `yaaif_skill_file_tree` | Skills + files |
| `yaaif_mcp_tools_list` / `yaaif_mcp_tool_get` / `yaaif_mcp_servers_list` / `yaaif_mcp_server_get` / `yaaif_mcp_deployments_list` | MCP catalog + deployments |
| `yaaif_ambient_agent_list` / `yaaif_ambient_agent_get` / `yaaif_ambient_workflow_list` / `yaaif_ambient_workflow_get` / `yaaif_ambient_runs_list` | Ambient |
| `yaaif_approval_strategies_list` / `yaaif_approval_strategy_create` / `yaaif_approval_strategy_publish` | HITL strategies |
| `yaaif_desktop_workers_list` / `yaaif_desktop_skill_mapping_set` | Desktop workers + skill maps |

## Docs

- [Getting started](docs/getting-started.md)
- [Configure environment](docs/configure-environment.md)
- [Partner workflows](docs/partner-workflows.md)
- [Threat model](docs/threat-model.md)
- [SECURITY.md](SECURITY.md)

## License

Apache-2.0 — see [LICENSE](LICENSE).
