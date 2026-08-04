# Configure environment

## Hosted / default (`platform.yaaif.ai`)

```bash
export YAAIF_OIDC_AUTHORITY=https://platform.yaaif.ai/auth/realms/yaaif
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_API_BASE_URL=https://platform.yaaif.ai
export YAAIF_AGENT_BASE_URL=https://platform.yaaif.ai/agent-service
export YAAIF_CONTROL_PLANE_BASE_URL=https://platform.yaaif.ai/control-plane-service
export YAAIF_APPROVAL_BASE_URL=https://platform.yaaif.ai/approval-service
export YAAIF_DEFAULT_TENANT_ID=<tenant-uuid>   # optional
```

These match the plugin variable defaults in `.cursor-plugin/plugin.json` and the MCP bridge.

## Local Traefik (`platform.yaaif.local`)

Use this on developer machines that run APIs behind local Traefik / mTLS.

**OIDC authority must match Keycloak `KC_HOSTNAME`**, not necessarily the Traefik API host. Most hybrid/local stacks set `KEYCLOAK_HOSTNAME=https://platform.yaaif.com/auth` (Cloudflare tunnel) while APIs stay on `*.yaaif.local` — same pattern as admin-ui / desktop-app. Starting login on `.local` while Keycloak’s hostname is `.com` causes Keycloak’s **“Restart login cookie not found”** error.

```bash
# Hybrid local (recommended when KEYCLOAK_HOSTNAME uses platform.yaaif.com)
export YAAIF_OIDC_AUTHORITY=https://platform.yaaif.com/auth/realms/yaaif
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_API_BASE_URL=https://platform.yaaif.local
export YAAIF_AGENT_BASE_URL=https://platform.yaaif.local/agent-service
export YAAIF_CONTROL_PLANE_BASE_URL=https://platform.yaaif.local/control-plane-service
export YAAIF_APPROVAL_BASE_URL=https://platform.yaaif.local/approval-service
export YAAIF_DEFAULT_TENANT_ID=<tenant-uuid>   # optional
```

Only use `.local` for OIDC when Keycloak itself is configured with `KC_HOSTNAME=https://platform.yaaif.local/auth` (default in `docker-compose.base.yml` when `KEYCLOAK_HOSTNAME` is unset):

```bash
export YAAIF_OIDC_AUTHORITY=https://platform.yaaif.local/auth/realms/yaaif
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_API_BASE_URL=https://platform.yaaif.local
export YAAIF_AGENT_BASE_URL=https://platform.yaaif.local/agent-service
export YAAIF_CONTROL_PLANE_BASE_URL=https://platform.yaaif.local/control-plane-service
export YAAIF_APPROVAL_BASE_URL=https://platform.yaaif.local/approval-service
```

Ensure Keycloak has client `yaaif-cursor` (realm import or `ensure-yaaif-cursor-client.sh`).

## Validation

Call `yaaif_configure_check` from Agent. It reports URL reachability and auth state.
