---
name: yaaif-sync-scenario
description: Sync a YAA\F Scenario from catalog objects, or apply the Scenario onto those objects
---

Use the `yaaif-scenario` skill in **sync** mode. Authenticate first if needed
(`yaaif-login` / `yaaif-auth`).

Resolve `spec_id` from the prompt, or `yaaif_agent_spec_list` / the last
selected scenario.

- **from objects** (default; after skill / agent / workflow edits in Cursor):
  `yaaif_agent_spec_sync_from_objects`
- **to objects** (after editing `workflow_design` or slot names on the spec):
  `yaaif_agent_spec_sync_to_objects`

Finish with `yaaif_agent_spec_coverage`. Stay in Cursor; do not open Admin UI
URLs.
