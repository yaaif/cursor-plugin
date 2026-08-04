# Operations support (read-only)

Cursor tools and skill for incident triage across LLM sessions, ambient runs, and desktop runs.

## Tools

| Tool | Purpose |
|------|---------|
| `yaaif_ops_analyze` | Correlate + ranked failures + next_steps |
| `yaaif_ops_correlate` | Linked IDs / statuses (optional analyze) |
| `yaaif_ops_session_get` | Session metrics + failures |
| `yaaif_ops_ambient_run_get` | Ambient run + diagnostics |
| `yaaif_ops_desktop_run_get` | Desktop run + failures |
| `yaaif_ops_desktop_runs_list` | Desktop runs for a session |

Skill: `yaaif-ops-support` / command `/yaaif-ops`.

## RO policy

These tools only call agent-service `GET /api/ops/*`. They never pause, stop, approve, reject, retry, or trigger workflows.

## Requirements

- agent-service with `/api/ops` routes deployed
- Token with `agent.sessions.read` or `agent.ambient.read`
- For desktop/metrics enrichment: control-plane + api-server metrics permissions as applicable

## Doctor

`yaaif_doctor` includes `ops_api` (expects HTTP 400 without a seed ID when the route exists).
