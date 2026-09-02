# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| `1.0.x` | Yes |
| `0.6.x` | Yes |
| `0.5.x` | Yes |
| `< 0.5` | Best-effort |

## Threat model (summary)

This Cursor plugin ships:

- Markdown skills, rules, commands, and docs
- A local **stdio** MCP bridge (`packages/mcp`) that authenticates to a customer-configured YAA\F environment
- Optional **native installer packages** (`.pkg` / `.msi` / `.deb`) that copy those files into `~/.cursor/plugins/local/yaaif` and, when the machine has no Node.js ≥ 20, also copy an official Node.js 22 LTS runtime from `https://nodejs.org/dist/` (checksums pinned in `installer/runtime-manifest.json`)

It does **not** ship custom/opaque runtimes, remote `curl | bash` installers, or embedded credentials. Marketplace installs still run the committed TypeScript `dist/` with whatever `node` is on `PATH`.

### Auth

- Uses Keycloak OIDC authorization code + PKCE (S256) with a loopback redirect (`http://127.0.0.1:<ephemeral>/callback`)
- Optional device-code login for headless/CI (`yaaif_login_device`) when enabled on the Keycloak client
- Tokens are stored at `~/.yaaif/cursor/session.json` with mode `0600`
- Session also records `profile_id` + `oidc_authority` (issuer mismatch forces re-login)
- API calls send `Authorization: Bearer` + `X-Tenant-ID` only
- Does **not** use platform S2S secrets, desktop connection keys, or AI-gateway keys
- Tenant **API keys** (`yaaif_api_key_*`) are the supported credential for MCP → platform APIs; plaintext is returned once on create/rotate and should be bound (deployment `secret_env` / skill field_map), not committed to repos
- Tool diagnostics use `redactSecrets` so access/refresh tokens are not echoed
- Optional local telemetry (`telemetry.json`) is **opt-in**, counters only, never uploaded
- Shared machines: delete `~/.yaaif/cursor/session.json` after use; prefer per-user home directories

### MCP surface

Tools can create/update skills, MCP deployments, and ambient workflows on the configured tenant. Treat enablement like granting Admin UI access for the signed-in user.

Cursor MCP allowlist / disable toggles apply unchanged.

## Reporting a vulnerability

Email **security@yaaif.com** (or your BeezLabs security contact) with reproduction steps. Do not open public issues for undisclosed vulnerabilities.

## Marketplace review notes

- Runtime is Node executing committed TypeScript `dist/` (or `npx @yaaif/cursor-mcp` from the public npm registry)
- Source under `packages/mcp/src/` can be cross-checked against `dist/`
- Plugin variables hold environment URLs only; no secrets are required in the plugin repo

## Native installer notes

- Packages are built from `installer/` in this repository (see `installer/README.md`)
- Bundled Node.js is the official `nodejs.org` archive for the target OS/arch, verified against `SHASUMS256.txt` and the SHA-256 in `installer/runtime-manifest.json`
- The installer writes `~/.yaaif/cursor/install-manifest.json` (`plugin_version`, `node_source` = `system` | `bundled`, absolute `node_command`). It does not modify Cursor’s undocumented plugin registry
- Installed `mcp.json` always uses an **absolute** Node path so Cursor does not depend on `PATH`
- `~/.yaaif/cursor/session.json` and profiles are left in place on update and uninstall
- Release assets include `SHA256SUMS`. macOS notarization / Windows Authenticode run only when signing env vars are set (see `installer/README.md`)
