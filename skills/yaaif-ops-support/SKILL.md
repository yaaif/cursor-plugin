---
name: yaaif-ops-support
description: >-
  Strictly read-only operations support: analyze LLM sessions, ambient workflow
  runs, and desktop executions by ID; correlate those IDs; pull telemetry
  evidence; summarize failure reasons. Never pause/stop/approve/retry.
---

# YAAIF operations support (read-only)

```
Task Progress:
- [ ] 1. Auth + tenant
- [ ] 2. Collect seed ID(s)
- [ ] 3. yaaif_ops_analyze
- [ ] 4. Telemetry drill-down (yaaif_ops_telemetry)
- [ ] 5. Escalate with template
```

## Prerequisites

1. `yaaif-auth`
2. Prefer `yaaif_doctor` — confirm `ops_api` and `ops_telemetry` checks pass
3. Read [references/correlation.md](references/correlation.md)

## Hard rules (RO)

- Use only `yaaif_ops_*` tools (and read-only list/get tools).
- **Never** call `yaaif_ambient_run_pause`, `resume`, `stop`, `approve`, `reject`, retry, trigger, or mapping mutations.
- Do not invent remediation API calls.
- Prefer `summary_only` (default on analyze) and avoid `include_raw` unless the operator holds `ops.support.raw`.

## Flow (fixed order)

1. Ask for any of: `session_id`, `ambient_run_id`, `desktop_run_id`, `request_id` (one is enough).
2. Call **`yaaif_ops_analyze`** with the seed(s).
3. Note `partial_errors` (metrics/desktop/harness/`ops.support.raw`) but continue with available data.
4. Drill down with **`yaaif_ops_telemetry`** (preferred over per-resource aliases):
   1. `resource=insights` when `session_id` known
   2. `resource=flow_events` when `request_id` known
   3. `resource=events` / `messages` for session timeline/transcript
   4. `resource=desktop_logs` / `ambient_logs` when those run IDs are linked
5. Optionally: `yaaif_ops_session_get`, `yaaif_ops_ambient_run_get`, `yaaif_ops_desktop_run_get`.
6. Report using the escalation template below.

## Escalation template

```markdown
## Incident
- Seed: <kind>=<id>
- Links: session=… ambient=… desktop=… harness=… request=…
- Status: session=… ambient=… desktop=… harness=…
- diagnostics_version: …

## Top failures
1. `<code>` — <summary>
2. …

## Next steps
1. …
2. …

## Evidence pulled
- analyze: yes
- telemetry: insights|flow_events|logs|none
- partial_errors: …
```

## Hand-off

Paste the filled template. Keep it short; attach raw JSON only if requested.
