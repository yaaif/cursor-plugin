---
name: yaaif-ops-support
description: >-
  Strictly read-only operations support: analyze LLM sessions, ambient workflow
  runs, and desktop executions by ID; correlate those IDs; summarize failure
  reasons. Never pause/stop/approve/retry.
---

# YAAIF operations support (read-only)

```
Task Progress:
- [ ] 1. Auth + tenant
- [ ] 2. Collect seed ID(s)
- [ ] 3. yaaif_ops_analyze
- [ ] 4. Drill down if needed
- [ ] 5. Report links, failures, next_steps
```

## Prerequisites

1. `yaaif-auth`
2. Prefer `yaaif_doctor` — confirm `ops_api` check passes
3. Read [references/correlation.md](references/correlation.md)

## Hard rules (RO)

- Use only `yaaif_ops_*` tools (and read-only list/get tools).
- **Never** call `yaaif_ambient_run_pause`, `resume`, `stop`, `approve`, `reject`, retry, trigger, or mapping mutations.
- Do not invent remediation API calls.

## Flow

1. Ask the user for any of: `session_id`, `ambient_run_id`, `desktop_run_id`, `request_id` (one is enough).
2. Call `yaaif_ops_analyze` with the seed(s).
3. If `partial_errors` appear, note them (forbidden metrics/desktop access is common) and continue with available data.
4. Optionally drill down:
   - `yaaif_ops_session_get`
   - `yaaif_ops_ambient_run_get`
   - `yaaif_ops_desktop_run_get` / `yaaif_ops_desktop_runs_list`
5. Report:
   - Linked IDs
   - Status snapshot
   - Ranked `failures[]` (code, summary, causes, resolutions)
   - `next_steps[]`

## Hand-off

Paste a compact incident summary suitable for escalation (IDs + top failure codes + next steps).
