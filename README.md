# YAA\F Cursor Plugin

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Official Cursor plugin for **customers and partner developers** to build on [YAA\F](https://yaaif.com):

1. Authenticate to a YAA\F environment (Keycloak OIDC + PKCE)
2. Create skills and load them into the tenant catalog
3. Scaffold / deploy MCP servers and register tools
4. Create ambient workflows and test-trigger them

**Repository:** https://github.com/yaaif/cursor-plugin  
**Marketplace name:** `yaaif`

This repo is also consumed by [yaaif-platform](https://github.com/yaaif/yaaif-platform) as a git submodule at `integrations/cursor-plugin`.

## Install

### Cursor Marketplace / Team Marketplace

Install **yaaif**, then configure plugin variables (Customize → Plugins → Configure). Defaults point at hosted YAA\F:

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

Your YAA\F operator must enable the public Keycloak client `yaaif-cursor` (see platform script `scripts/keycloak/ensure-yaaif-cursor-client.sh`).

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

### Local install (developers)

Prefer a **real directory copy** (Cursor can ignore/break on symlinks/junctions for logos + plugin discovery). Requires **Git** and **Node.js ≥ 20**.

#### macOS

```bash
git clone https://github.com/yaaif/cursor-plugin.git
cd cursor-plugin/packages/mcp && npm install && npm run build && cd ../..
mkdir -p ~/.cursor/plugins/local
rsync -a --delete --exclude '.git' --exclude 'packages/mcp/node_modules' \
  "$PWD/" ~/.cursor/plugins/local/yaaif/
```

Then in Cursor **Plugins → + Add → Add local plugin** and select `~/.cursor/plugins/local/yaaif` (or the clone path). Reload the window.

Symlink (`ln -sf "$PWD" ~/.cursor/plugins/local/yaaif`) can work for MCP/skills but often fails logo rendering; use rsync if the icon stays a generic cube.

#### Ubuntu desktop (and other Linux)

```bash
# Prereqs (once)
sudo apt update
sudo apt install -y git rsync curl
# Node.js ≥ 20 (NodeSource example; use nvm/fnm if you prefer)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

git clone https://github.com/yaaif/cursor-plugin.git ~/src/cursor-plugin
cd ~/src/cursor-plugin
cd packages/mcp && npm install && npm run build && cd ../..
mkdir -p ~/.cursor/plugins/local
rsync -a --delete --exclude '.git' --exclude 'packages/mcp/node_modules' \
  "$PWD/" ~/.cursor/plugins/local/yaaif/
```

Then in Cursor **Plugins → + Add → Add local plugin** and select `~/.cursor/plugins/local/yaaif`. Reload the window.

Prefer `rsync` over `ln -s` (same logo/discovery caveat as macOS).

#### Windows (PowerShell)

```powershell
git clone https://github.com/yaaif/cursor-plugin.git $env:USERPROFILE\src\cursor-plugin
cd $env:USERPROFILE\src\cursor-plugin

cd packages\mcp
npm install
npm run build
cd ..\..

$dest = Join-Path $env:USERPROFILE ".cursor\plugins\local\yaaif"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

# Mirror tree (like rsync --delete); skip .git and node_modules
robocopy . $dest /MIR /XD .git "packages\mcp\node_modules" /NFL /NDL /NJH /NJS /nc /ns /np
# robocopy exit codes 0–7 are success
if ($LASTEXITCODE -ge 8) { throw "robocopy failed: $LASTEXITCODE" }
```

Then in Cursor **Plugins → + Add → Add local plugin** and select  
`C:\Users\<you>\.cursor\plugins\local\yaaif`. Reload the window.

Logo: `assets/logo.svg` (also `assets/logo.png`). Relative path in `plugin.json` — do not rely on a GitHub raw URL for local installs.

For local platform stacks, see [configure-environment.md](docs/configure-environment.md) (`local-hybrid` + ClickHouse for ops telemetry).

## Update (already installed PCs)

### Marketplace / Team Marketplace

1. Cursor → **Plugins → yaaif** → Update (or remove + reinstall **yaaif**)
2. **Developer: Reload Window**
3. Run `/yaaif-doctor`

Marketplace PCs only receive a new version after that release is **published** to the Cursor marketplace. Local monorepo or git changes do not auto-reach them.

### Local plugin install

Re-pull, rebuild, and re-copy into `~/.cursor/plugins/local/yaaif` (Windows: `%USERPROFILE%\.cursor\plugins\local\yaaif`), then reload.

#### macOS

```bash
cd /path/to/cursor-plugin   # or clone https://github.com/yaaif/cursor-plugin.git
git pull
cd packages/mcp && npm install && npm run build && cd ../..
mkdir -p ~/.cursor/plugins/local
rsync -a --delete --exclude '.git' --exclude 'packages/mcp/node_modules' \
  "$PWD/" ~/.cursor/plugins/local/yaaif/
```

#### Ubuntu desktop (and other Linux)

```bash
cd ~/src/cursor-plugin   # or your clone path
git pull
cd packages/mcp && npm install && npm run build && cd ../..
mkdir -p ~/.cursor/plugins/local
rsync -a --delete --exclude '.git' --exclude 'packages/mcp/node_modules' \
  "$PWD/" ~/.cursor/plugins/local/yaaif/
```

If `rsync` is missing: `sudo apt install -y rsync`.

#### Windows (PowerShell)

```powershell
cd $env:USERPROFILE\src\cursor-plugin   # or your clone path
git pull

cd packages\mcp
npm install
npm run build
cd ..\..

$dest = Join-Path $env:USERPROFILE ".cursor\plugins\local\yaaif"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
robocopy . $dest /MIR /XD .git "packages\mcp\node_modules" /NFL /NDL /NJH /NJS /nc /ns /np
if ($LASTEXITCODE -ge 8) { throw "robocopy failed: $LASTEXITCODE" }
```

Then **Developer: Reload Window** (or restart the yaaif MCP) and run `/yaaif-doctor`.

### After any update

- Prefer `yaaif_platform_use` + `yaaif_ensure_session` over hand-editing every URL.
- Local Traefik (`*.yaaif.local`): use profile `local-hybrid` (or `local`). The bridge auto-loads mkcert `rootCA.pem` when possible; otherwise set plugin var `YAAIF_EXTRA_CA_FILE` to the CA PEM:
  - macOS: `~/Library/Application Support/mkcert/rootCA.pem` (or copy to `~/.yaaif/cursor/mkcert-rootCA.pem`)
  - Ubuntu/Linux: `~/.local/share/mkcert/rootCA.pem` (after `mkcert -install`)
  - Windows: `C:\Users\<you>\.yaaif\cursor\mkcert-rootCA.pem` (or your mkcert `CAROOT`)
- Confirm with `/yaaif-doctor` until `ready: true`.

## Runtime

MCP bridge is TypeScript (`packages/mcp`), launched via:

```json
{ "command": "node", "args": ["packages/mcp/dist/cli.js"] }
```

After npm publish:

```bash
npx -y @yaaif/cursor-mcp@1.1.0
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
| `yaaif-ops-support` / `/yaaif-ops` | Read-only incident triage (session/ambient/desktop) |
| `yaaif-create-mcp` / `/yaaif-new-mcp` | Scaffold + deploy MCP (compose or k8s GitOps) + API key bind |
| `yaaif-create-ambient` / `/yaaif-new-workflow` | Ambient workflows |

### Read / browse tools

| Tool | Purpose |
|------|--------|
| `yaaif_catalog_overview` | Snapshot of agents, skills, MCPs, ambient, local tools |
| `yaaif_local_tools_list` / `yaaif_local_tool_get` / `yaaif_local_tool_call` | Agent-service built-in local tools (skill lifecycle, files, ambient, …) |
| `yaaif_dev_session_ensure` | Cursor authoring session (auto default skills agent) |
| `yaaif_skill_tools_check` | Verify skill tools against local + MCP catalogs |
| `yaaif_skill_validate_module` / `yaaif_skill_develop` / `yaaif_skill_guided_draft` / `yaaif_skill_update_module_files` / `yaaif_skill_edit_section` | Skill lifecycle locals |
| `yaaif_list_ambient_workflows` / `yaaif_trigger_ambient_workflow` | Ambient locals |
| `yaaif_files_list` / `yaaif_files_search` / `yaaif_file_load_context` / `yaaif_load_artifacts` / `yaaif_file_share_link` / `yaaif_generate_file` | File local tools (ADK artifact name + version) |
| `yaaif_session_files_list` / `yaaif_file_artifact_versions` / `yaaif_file_get_extracted` / `yaaif_file_artifact_delete` | File REST helpers (`/api/files…`) |
| `yaaif_ops_analyze` / `yaaif_ops_correlate` / `yaaif_ops_*_get` | Read-only ops incident correlation + failures |
| `yaaif_doctor` | Profile + OIDC + health + session + catalog + local tools + file registry/artifacts + ops_api + ops_telemetry |
| `yaaif_plan_verify` / `yaaif_plan_dry_run` / `yaaif_plan_execution_*` | Plan verify / dry-run / resume |
| `yaaif_platform_export` | Shell exports + Cursor variables JSON |
| `yaaif_agent_list` / `yaaif_agent_get` / `yaaif_agent_create` / `yaaif_agent_update` | Agents |
| `yaaif_skill_map_agents_merge` | Safe skill↔agent mapping (union) |
| `yaaif_skill_list` / `yaaif_skill_get` / `yaaif_skill_read_file` / `yaaif_skill_file_tree` | Skills + files |
| `yaaif_mcp_tools_list` / `yaaif_mcp_tool_get` / `yaaif_mcp_servers_list` / `yaaif_mcp_server_get` / `yaaif_mcp_deployments_list` | MCP catalog + deployments |
| `yaaif_mcp_deployment_create` / `deploy` / `update` / `redeploy` / `stop` / `delete` / `status` / `logs` / `k8s_status` / `register` | MCP deploy lifecycle (compose + kubernetes_gitops) |
| `yaaif_deployment_settings_get` / `yaaif_deployment_settings_status` | Deployment-service preflight (read-only) |
| `yaaif_api_key_list` / `yaaif_api_key_create` / `yaaif_api_key_bind_deployment` / `yaaif_api_key_*` | Scoped API keys for MCP → platform APIs (not S2S) |
| `yaaif_ambient_agent_list` / `yaaif_ambient_agent_get` / `yaaif_ambient_workflow_list` / `yaaif_ambient_workflow_get` / `yaaif_ambient_runs_list` | Ambient |
| `yaaif_approval_strategies_list` / `yaaif_approval_strategy_create` / `yaaif_approval_strategy_publish` | HITL strategies |
| `yaaif_desktop_workers_list` / `yaaif_desktop_skill_mapping_set` | Desktop workers + skill maps |

## Docs

- [Getting started](docs/getting-started.md)
- [Configure environment](docs/configure-environment.md)
- [Partner workflows](docs/partner-workflows.md)
- [Platform local tools](docs/platform-local-tools.md)
- [File artifacts](docs/file-artifacts.md)
- [Ops support (read-only)](docs/ops-support.md)
- [Threat model](docs/threat-model.md)
- [SECURITY.md](SECURITY.md)

## License

Apache-2.0 — see [LICENSE](LICENSE).
