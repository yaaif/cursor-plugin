# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| `1.3.x` | Yes |
| `1.1.x` | Yes |
| `1.0.x` | Yes |
| `0.6.x` | Yes |
| `0.5.x` | Yes |
| `< 0.5` | Best-effort |

## Threat model (summary)

This Cursor plugin ships:

- Markdown skills, rules, commands, and docs
- A local **stdio** MCP bridge (`packages/mcp`, published as `@yaaif/platform-mcp`) that authenticates to a customer-configured YAA\F environment
- A Node CLI (`--install` / `--setup`) that copies plugin files and writes `mcp.json`

It does **not** ship custom/opaque runtimes, native OS packages, remote `curl | bash` installers, or embedded credentials. Installs require Node.js ≥ 20 on `PATH`.

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

- Runtime is Node executing `npx @yaaif/platform-mcp@<version> --client cursor` (or `--offline` absolute `node` + `cli.js`)
- Source under `packages/mcp/src/` can be cross-checked against the published package
- Plugin variables hold environment URLs only; no secrets are required in the plugin repo
- `--install` does not modify Cursor’s undocumented plugin registry; first install still needs **Add local plugin**
- `~/.yaaif/cursor/session.json` and profiles are left in place on update
