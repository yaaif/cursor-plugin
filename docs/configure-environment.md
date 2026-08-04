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

## Validation

Call `yaaif_configure_check` or `yaaif_ensure_session`. Expect OIDC discovery OK, issuer match, and a selected tenant.
