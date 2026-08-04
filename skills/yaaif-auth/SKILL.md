---
name: yaaif-auth
description: >-
  Authenticate to YAAIF from Cursor, select a tenant, and verify session before
  skills/MCP/ambient mutations. Use for YAAIF login, tenant selection, whoami,
  or configure_check.
---

# YAAIF Auth

```
Task Progress:
- [ ] 1. configure_check
- [ ] 2. Login if needed
- [ ] 3. Select tenant
- [ ] 4. Confirm whoami
```

## Steps

1. Call `yaaif_configure_check` and fix any unreachable URL issues with the user.
2. If not authenticated, call `yaaif_login` (browser PKCE).
3. Call `yaaif_list_tenants` when tenant is unknown.
4. Call `yaaif_set_tenant` with the tenant UUID.
5. Call `yaaif_whoami` and report email + `tenant_id`.

## Rules

- Do not invent tokens or paste Keycloak secrets into chat.
- Do not use S2S / desktop / AI-gateway keys.
- Session file: `~/.yaaif/cursor/session.json`.
- Plugin variables: `YAAIF_OIDC_AUTHORITY`, `YAAIF_API_BASE_URL`, `YAAIF_AGENT_BASE_URL`, optional `YAAIF_DEFAULT_TENANT_ID`, optional `YAAIF_OIDC_CLIENT_ID`.

## Done when

`yaaif_whoami` returns `authenticated: true` and a non-empty `tenant_id`.
