# Configure environment

## SaaS / Traefik-style hosts

```bash
YAAIF_OIDC_AUTHORITY=https://platform.yaaif.local/auth/realms/yaaif
YAAIF_API_BASE_URL=https://platform.yaaif.local
YAAIF_AGENT_BASE_URL=https://platform.yaaif.local/agent-service
YAAIF_OIDC_CLIENT_ID=yaaif-cursor
```

Exact path prefixes depend on the customer's ingress. Prefer the same origins Admin UI uses.

## Local docker-compose

```bash
YAAIF_OIDC_AUTHORITY=http://localhost:8080/auth/realms/yaaif
YAAIF_API_BASE_URL=http://localhost:8084
YAAIF_AGENT_BASE_URL=http://localhost:8086
```

Ensure Keycloak has client `yaaif-cursor` (realm import or `ensure-yaaif-cursor-client.sh`).

## Validation

Call `yaaif_configure_check` from Agent. It reports URL reachability and auth state.
