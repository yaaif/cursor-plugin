---
name: yaaif-login
description: Authenticate to YAAIF and select an active tenant
---

Use the `yaaif-auth` skill.

1. Call `yaaif_configure_check`.
2. If not authenticated, call `yaaif_login`.
3. Call `yaaif_list_tenants` and `yaaif_set_tenant` if needed.
4. Confirm with `yaaif_whoami` and report email + tenant id.
