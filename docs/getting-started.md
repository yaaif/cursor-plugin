# Getting started

1. Install the **yaaif** Cursor plugin (Marketplace or local symlink).
2. Configure URLs:
   - Hosted default: `https://platform.yaaif.ai` (see README)
   - Local Traefik: `https://platform.yaaif.local` (see [configure-environment.md](configure-environment.md))
   - Optional tenant UUID after login
3. Set plugin variables in Cursor (or export the env vars before launch).
4. In Agent: run `/yaaif-login` (uses `yaaif_ensure_session`). For local Traefik, switch with `yaaif_platform_use` → `local-hybrid` first.
5. For a full use case (chat + ambient + desktop), run `/yaaif-plan`, approve the plan, then let it execute. For a single artifact, use `/yaaif-new-skill` or `/yaaif-new-workflow`.

Smoke checklist: [install-and-smoke.md](install-and-smoke.md).
