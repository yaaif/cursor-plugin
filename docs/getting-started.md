# Getting started

1. Install the **yaaif** Cursor plugin (Marketplace or local symlink).
2. Ask your YAAIF operator for:
   - OIDC authority (`…/auth/realms/yaaif`)
   - API base URL
   - Agent service base URL
   - Your tenant UUID (optional if discoverable after login)
3. Configure plugin variables in Cursor.
4. In Agent: run `/yaaif-login` or ask to authenticate to YAAIF.
5. Create a lean skill with `/yaaif-new-skill`, or a workflow with `/yaaif-new-workflow`.

Smoke checklist: [install-and-smoke.md](install-and-smoke.md).
