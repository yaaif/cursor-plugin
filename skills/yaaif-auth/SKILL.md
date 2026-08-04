---
name: yaaif-auth
description: >-
  Authenticate to YAAIF from Cursor, select a tenant, and verify session before
  skills/MCP/ambient mutations. Use when the user mentions YAAIF login, tenant,
  whoami, or any platform deploy that requires auth.
---

# YAAIF Auth

```
Task Progress:
- [ ] 1. Check session
- [ ] 2. Login if needed
- [ ] 3. Select tenant
- [ ] 4. Confirm whoami
```

## Steps

1. Call `yaaif_whoami`.
2. If `authenticated` is false, call `yaaif_login` (opens browser PKCE).
3. Call `yaaif_list_tenants` when tenant is unknown.
4. Call `yaaif_set_tenant` with the tenant UUID.
5. Call `yaaif_whoami` again and report email + `tenant_id`.

## Rules

- Do not invent tokens or paste Keycloak secrets into chat.
- Do not use S2S / desktop / AI-gateway keys.
- Env defaults: `YAAIF_OIDC_AUTHORITY`, `YAAIF_API_BASE_URL`, `YAAIF_AGENT_BASE_URL`, optional `YAAIF_DEFAULT_TENANT_ID`.
- Session file: `~/.yaaif/cursor/session.json`.

## Done when

`yaaif_whoami` returns `authenticated: true` and a non-empty `tenant_id`.
