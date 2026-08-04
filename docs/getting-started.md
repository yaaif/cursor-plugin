# Getting started

1. Install the **yaaif** Cursor plugin (Marketplace or local symlink).
2. Configure URLs:
   - Hosted default: `https://platform.yaaif.ai` (see README)
   - Local Traefik: `https://platform.yaaif.local` (see [configure-environment.md](configure-environment.md))
   - Optional tenant UUID after login
3. Set plugin variables in Cursor (or export the env vars before launch).
4. In Agent: run `/yaaif-login` or ask to authenticate to YAAIF.
5. Create a lean skill with `/yaaif-new-skill`, or a workflow with `/yaaif-new-workflow`.

Smoke checklist: [install-and-smoke.md](install-and-smoke.md).
