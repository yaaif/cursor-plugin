# Configure environment

## Hosted / default (`platform.yaaif.ai`)

```bash
export YAAIF_OIDC_AUTHORITY=https://platform.yaaif.ai/auth/realms/yaaif
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_API_BASE_URL=https://platform.yaaif.ai
export YAAIF_AGENT_BASE_URL=https://platform.yaaif.ai/agent-service
export YAAIF_DEFAULT_TENANT_ID=<tenant-uuid>   # optional
```

These match the plugin variable defaults in `.cursor-plugin/plugin.json` and the MCP bridge.

## Local Traefik (`platform.yaaif.local`)

Use this on developer machines that run the platform behind local Traefik / mTLS:

```bash
export YAAIF_OIDC_AUTHORITY=https://platform.yaaif.local/auth/realms/yaaif
export YAAIF_OIDC_CLIENT_ID=yaaif-cursor
export YAAIF_API_BASE_URL=https://platform.yaaif.local
export YAAIF_AGENT_BASE_URL=https://platform.yaaif.local/agent-service
export YAAIF_DEFAULT_TENANT_ID=<tenant-uuid>   # optional
```

Ensure Keycloak has client `yaaif-cursor` (realm import or `ensure-yaaif-cursor-client.sh`).

## Validation

Call `yaaif_configure_check` from Agent. It reports URL reachability and auth state.
