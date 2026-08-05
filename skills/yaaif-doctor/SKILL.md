---
name: yaaif-doctor
description: >-
  Run YAA\F Cursor connectivity diagnostics (platform profile, OIDC, TLS/mTLS,
  auth/tenant, catalog ping, local tools API). Use when login fails, local
  Traefik TLS breaks, or before plan/create work.
---

# YAA\F Doctor

```
Task Progress:
- [ ] 1. Call yaaif_doctor
- [ ] 2. Fix reported failures
- [ ] 3. Re-run until ready
```

## Steps

1. Call `yaaif_doctor` (optionally `login_if_needed: true`).
2. If profile/OIDC wrong: `yaaif_platform_use` then doctor again.
3. If TLS/CA errors on `.local`: set `YAAIF_EXTRA_CA_FILE` / profile `extra_ca_file`, or see docs/configure-environment.md.
4. If not authenticated: `yaaif_ensure_session` or `yaaif_login` / `yaaif_login_device`.
5. Confirm with `yaaif_whoami`.
6. If `local_tools` fails: ensure agent-service exposes `/api/local-tools` and
   the session has `agent.skills.read` (restart agent-service after upgrade).

## Done when

`yaaif_doctor` returns `ready: true` with all checks ok (including `local_tools`).
