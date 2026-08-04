# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| `0.6.x` | Yes |
| `0.5.x` | Yes |
| `< 0.5` | Best-effort |

## Threat model (summary)

This Cursor plugin ships:

- Markdown skills, rules, commands, and docs
- A local **stdio** MCP bridge (`packages/mcp`) that authenticates to a customer-configured YAAIF environment

It does **not** ship opaque binaries, remote install scripts, or embedded credentials.

### Auth

- Uses Keycloak OIDC authorization code + PKCE (S256) with a loopback redirect (`http://127.0.0.1:<ephemeral>/callback`)
- Optional device-code login for headless/CI (`yaaif_login_device`) when enabled on the Keycloak client
- Tokens are stored at `~/.yaaif/cursor/session.json` with mode `0600`
- Session also records `profile_id` + `oidc_authority` (issuer mismatch forces re-login)
- API calls send `Authorization: Bearer` + `X-Tenant-ID` only
- Does **not** use platform S2S secrets, desktop connection keys, or AI-gateway keys
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
