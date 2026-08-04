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
export YAAIF_DEFAULT_TENANT_ID=<tenant-uuid>   # optional
```

| Variable | Default |
|----------|---------|
| `YAAIF_OIDC_AUTHORITY` | `https://platform.yaaif.ai/auth/realms/yaaif` |
| `YAAIF_API_BASE_URL` | `https://platform.yaaif.ai` |
| `YAAIF_AGENT_BASE_URL` | `https://platform.yaaif.ai/agent-service` |
| `YAAIF_DEFAULT_TENANT_ID` | optional UUID |
| `YAAIF_OIDC_CLIENT_ID` | `yaaif-cursor` |

Your YAAIF operator must enable the public Keycloak client `yaaif-cursor` (see platform script `scripts/keycloak/ensure-yaaif-cursor-client.sh`).

### Local Traefik (`platform.yaaif.local`)

```bash
export YAAIF_OIDC_AUTHORITY=https://platform.yaaif.local/auth/realms/yaaif
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_API_BASE_URL=https://platform.yaaif.local
export YAAIF_AGENT_BASE_URL=https://platform.yaaif.local/agent-service
export YAAIF_DEFAULT_TENANT_ID=<tenant-uuid>   # optional
```

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
npx -y @yaaif/cursor-mcp@0.2.0
```

Requires **Node.js ≥ 20**. No Go toolchain.

## Skills and commands

| Skill / command | Purpose |
|-----------------|--------|
| `yaaif-auth` / `/yaaif-login` | Login + tenant |
| `yaaif-create-skill` / `/yaaif-new-skill` | Author + load skill |
| `yaaif-create-mcp` / `/yaaif-new-mcp` | Scaffold + deploy MCP |
| `yaaif-create-ambient` / `/yaaif-new-workflow` | Ambient workflows |

## Docs

- [Getting started](docs/getting-started.md)
- [Configure environment](docs/configure-environment.md)
- [Partner workflows](docs/partner-workflows.md)
- [Threat model](docs/threat-model.md)
- [SECURITY.md](SECURITY.md)

## License

Apache-2.0 — see [LICENSE](LICENSE).
