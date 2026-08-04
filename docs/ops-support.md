# Operations support (read-only)

Cursor tools and skill for incident triage across LLM sessions, ambient runs, desktop runs, and telemetry-service evidence.

## Tools

| Tool | Purpose |
|------|---------|
| `yaaif_ops_analyze` | Correlate + ranked failures + next_steps (start here) |
| `yaaif_ops_correlate` | Linked IDs / statuses |
| `yaaif_ops_telemetry` | **Unified** telemetry drill-down: `messages` \| `events` \| `flow_events` \| `insights` \| `desktop_logs` \| `ambient_logs` |
| `yaaif_ops_session_get` | Session metrics + failures |
| `yaaif_ops_ambient_run_get` | Ambient run + diagnostics |
| `yaaif_ops_desktop_run_get` / `_list` | Desktop run detail / list |
| Aliases | `yaaif_ops_session_messages`, `_events`, `_flow_events`, `_session_insights`, `_desktop_worker_logs`, `_ambient_worker_logs` → prefer `yaaif_ops_telemetry` |

Shared shaping knobs on ops tools: `summary_only`, `max_chars`, `max_items` (keeps agent context small).

Skill: `yaaif-ops-support` / command `/yaaif-ops`.

Telemetry tools call **agent-service** `GET /api/ops/*` only. That proxies api-server → telemetry-service. Do **not** configure a direct telemetry-service URL in the plugin.

## RO policy

These tools only call agent-service `GET /api/ops/*`. They never pause, stop, approve, reject, retry, or trigger workflows.

## Requirements

- agent-service with `/api/ops` routes (diagnostics_version `ops-diagnostics/1`+)
- api-server `TELEMETRY_STORAGE=clickhouse` + reachable telemetry-service for telemetry resources
- Token with `ops.support.read` **or** `agent.sessions.read` **or** `agent.ambient.read`
- Downstream: `api.metrics.read`, `api.desktop_workers.read`, `harness.run.read`, `ops.support.raw` (only for `include_raw`)

## Doctor

`yaaif_doctor` checks:

- `ops_api` — correlate mounted (expects 400 without seed)
- `ops_telemetry` — flow-events proxy mounted (expects 400 without `request_id`, or 403 if missing metrics read)
