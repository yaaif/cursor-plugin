# Configure environment

## Quick path (recommended)

In Agent:

1. `yaaif_platform_list` — see `hosted`, `local-hybrid`, `local`, and any custom profiles
2. `yaaif_platform_use` with `profile_id` (e.g. `local-hybrid`)
3. `yaaif_ensure_session` with `login_if_needed: true` (optional `tenant` name/slug/uuid)

Or set plugin variable `YAAIF_PLATFORM_PROFILE` to `hosted` | `local-hybrid` | `local`.

Custom customer environments:

```
yaaif_platform_save
  id: customer-prod
  oidc_authority: https://customer.example/auth/realms/yaaif
  api_base_url: https://customer.example
  activate: true
```

Profiles persist under `~/.yaaif/cursor/` (`active-profile.json`, `profiles.json`).

## Builtin profiles

| Id | OIDC | APIs |
|----|------|------|
| `hosted` | `platform.yaaif.ai` | `platform.yaaif.ai` |
| `local-hybrid` | `platform.yaaif.com` | `platform.yaaif.local` |
| `local` | `platform.yaaif.local` | `platform.yaaif.local` |

**OIDC authority must match Keycloak `KC_HOSTNAME`.** Hybrid stacks (tunnel issuer `.com`, APIs `.local`) should use `local-hybrid`. Starting login on `.local` while Keycloak’s hostname is `.com` causes Keycloak’s **“Restart login cookie not found”** error — `yaaif_configure_check` probes OIDC discovery to catch mismatches.

## Manual env vars (optional)

```bash
export YAAIF_PLATFORM_PROFILE=hosted   # or local-hybrid / local
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_DEFAULT_TENANT_ID=<tenant-uuid>   # optional
# URL vars are filled by the profile; override only when needed:
# export YAAIF_OIDC_AUTHORITY=...
# export YAAIF_API_BASE_URL=...
# export YAAIF_AGENT_BASE_URL=...
# export YAAIF_CONTROL_PLANE_BASE_URL=...
# export YAAIF_APPROVAL_BASE_URL=...
```

Ensure Keycloak has client `yaaif-cursor` (realm import or `ensure-yaaif-cursor-client.sh`).

## TLS / corporate CA / mTLS

Local Traefik (`*.yaaif.local`) is usually issued by **mkcert**. Node does **not** use the macOS/Linux system trust store, so even after `mkcert -install` the Cursor MCP bridge must load `rootCA.pem` explicitly.

For `local` / `local-hybrid` profiles the bridge **auto-discovers** the mkcert CA from (first match wins):

1. `$CAROOT/rootCA.pem`
2. `~/Library/Application Support/mkcert/rootCA.pem` (macOS)
3. `~/.local/share/mkcert/rootCA.pem` (Linux)
4. `mkcert -CAROOT` / `rootCA.pem`

`yaaif_doctor` reports `ca_source: mkcert-auto` when this works. Override anytime with:

```bash
export YAAIF_EXTRA_CA_FILE=/path/to/corp-or-traefik-ca.pem
# optional client mTLS:
export YAAIF_CLIENT_CERT_FILE=/path/to/client.crt.pem
export YAAIF_CLIENT_KEY_FILE=/path/to/client.key.pem
```

Or set `extra_ca_file` / `client_cert_file` / `client_key_file` on a custom profile via `yaaif_platform_save`. The bridge applies these to HTTPS requests at startup (and after `yaaif_platform_use`).

On local profiles the bridge **also merges** the mkcert CA when an explicit/`NODE_EXTRA_CA_CERTS` bundle is set, so a corporate CA cannot shadow Traefik trust.

`NODE_EXTRA_CA_CERTS` is also honored when `YAAIF_EXTRA_CA_FILE` is unset (and is reported as `ca_source: explicit`; mkcert is still merged for `*.yaaif.local`).

**Profile precedence:** `yaaif_platform_use` writes `~/.yaaif/cursor/active-profile.json` and that file wins over the Cursor plugin variable `YAAIF_PLATFORM_PROFILE` (which defaults to `hosted`). After switching to `local-hybrid`, reload/restart the YAA\F MCP so the new binary + profile apply.
## Export for shells / Cursor variables

After `yaaif_platform_use`, call `yaaif_platform_export` for ready-to-paste `export …` lines and a Cursor plugin variables JSON map.

## Ops / telemetry (local-hybrid & local)

Read-only ops tools (`yaaif_ops_*`, `/yaaif-ops`) call **agent-service** `/api/ops/*`, which proxies api-server → **telemetry-service**.

For message/event/log drill-down to work on a local stack:

- `TELEMETRY_STORAGE=clickhouse` on api-server
- telemetry-service reachable (default `http://localhost:8078`)
- caller holds `api.metrics.read` (and `ops.support.read` or sessions/ambient read)

`yaaif_doctor` checks `ops_api` (correlate mounted) and `ops_telemetry` (flow-events proxy mounted). A 403 on `ops_telemetry` still counts as route-ok but means the role needs metrics read.

## Validation

Call `yaaif_doctor` or `yaaif_ensure_session`. Expect OIDC discovery OK, issuer match, a selected tenant, and (for ops) `ops_api` / `ops_telemetry` green.
