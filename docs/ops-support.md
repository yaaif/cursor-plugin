# Operations support

Cursor tools and skill for incident triage across LLM sessions, ambient runs, desktop runs, and telemetry-service evidence — plus optional write-back of confirmed diagnoses to YAAIF.

## Tools

| Tool | Purpose |
|------|---------|
| `yaaif_ops_analyze` | Correlate + ranked failures + next_steps (after listing prior diagnoses) |
| `yaaif_ops_correlate` | Linked IDs / statuses |
| `yaaif_ops_telemetry` | **Unified** telemetry drill-down: `messages` \| `events` \| `flow_events` \| `insights` \| `desktop_logs` \| `ambient_logs` |
| `yaaif_ops_session_get` | Session metrics + failures |
| `yaaif_ops_ambient_run_get` | Ambient run + diagnostics + `run_path` (coverage/path/current step/canvas URL) |
| `yaaif_ops_desktop_run_get` / `_list` | Desktop run detail / list |
| `yaaif_ops_diagnosis_list` | Prior confirmed diagnoses for `ambient_run_id` (newest first) |
| `yaaif_ops_diagnosis_get` | One diagnosis by id |
| `yaaif_ops_diagnosis_create` | Persist `OpsDiagnosisRecord` — **requires `confirm=true`** after user confirmation |
| Aliases | `yaaif_ops_session_messages`, `_events`, `_flow_events`, `_session_insights`, `_desktop_worker_logs`, `_ambient_worker_logs` → prefer `yaaif_ops_telemetry` |

Shared shaping knobs on ops tools: `summary_only`, `max_chars`, `max_items` (keeps agent context small). `summary_only` keeps `run_path` when present.

When an ambient run is linked, `yaaif_ops_analyze` and `yaaif_ops_ambient_run_get` attach a compact `run_path` (plugin-side, from the run graph + state blocks):

- `counts`: executed / running / waiting / failed / pending
- `coverage`: `reached/total` (never “86% complete”)
- `path`: `executed/reached`
- `current_step`: fail, then running, then waiting
- `tone`: run status wins over leftover wait blocks
- `admin_ui_canvas_url`: `/admin/workflow-runs?ar_run=…&ar_run_tab=workflow-canvas` (+ `ar_canvas_info` when current step is known)

Skill: `yaaif-ops-support` / command `/yaaif-ops`. Flow: list prior diagnoses → analyze → telemetry → fill `OpsDiagnosisRecord` → **wait for user confirm** → `yaaif_ops_diagnosis_create(confirm=true)`.

Escalation should include:

```markdown
- Coverage: 8/20 reached
- Path: 7/8 finished on this path
- Current step: <id> WAITING|FAILED|RUNNING
- Canvas: <admin_ui_canvas_url>
- Prior diagnoses: <count>
- Written to YAAIF: yes|no
```

Analyze/telemetry call **agent-service** `GET /api/ops/*` only. Diagnosis write-back uses `POST /api/ops/diagnoses`. Do **not** configure a direct telemetry-service URL in the plugin.

## Mutation policy

Never pause, stop, approve, reject, retry, heal, or trigger workflows from ops support.

The **only** allowed write is `yaaif_ops_diagnosis_create` after explicit user confirmation (`confirm=true`). Requires `ops.support.write`.

## Requirements

- agent-service with `/api/ops` routes (diagnostics_version `ops-diagnostics/1`+) and `ops_diagnosis_records`
- api-server `TELEMETRY_STORAGE=clickhouse` + reachable telemetry-service for telemetry resources
- Token with `ops.support.read` **or** `agent.sessions.read` **or** `agent.ambient.read` for read tools
- `ops.support.write` for diagnosis create
- Downstream: `api.metrics.read`, `api.desktop_workers.read`, `harness.run.read`, `ops.support.raw` (only for `include_raw`)

## Doctor

`yaaif_doctor` checks:

- `ops_api` — correlate mounted (expects 400 without seed)
- `ops_telemetry` — flow-events proxy mounted (expects 400 without `request_id`, or 403 if missing metrics read)
