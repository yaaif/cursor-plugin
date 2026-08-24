---
name: yaaif-create-ambient
description: >-
  Design and install YAA\F ambient workflows via the Cursor MCP bridge for
  customer/partner tenants (no monorepo required).
---

# Create ambient workflows on YAA\F

```
Task Progress:
- [ ] 1. Auth + tenant
- [ ] 2. Pick pattern
- [ ] 3. Ensure MCP tools exist
- [ ] 4. Workflow agent + ambient agent
- [ ] 5. Workflow graph + triggers
- [ ] 6. Optional chat skill
- [ ] 7. Test trigger
```

## Prerequisites

1. `yaaif-auth`
2. Domain MCP tools registered (`yaaif-create-mcp` or link)
3. Ambient feature enabled on the deployment

If Admin UI **Open in Cursor** included `workflow_id`, stay in Cursor — do not
open Admin UI URLs. Load `yaaif_ambient_workflow_get` and update that graph /
triggers. Do not create a second workflow with the same id.

## Patterns

See [references/patterns.md](references/patterns.md). Default to **Linear**.

Author **step-only** graphs (`tool_call` / `action` / `if` / `approval` / `hotl` / `wait` / `do_nothing`, etc.). The designer canvas labels those as ACTION, MESSAGE, BRANCH, WAIT, HUMAN, TERMINAL. Do **not** add watcher / evaluator / guardian / orchestrator / recorder nodes — those are engine phases (settings), not canvas steps. `approval` pauses (HITL); `hotl` notifies and continues (HOTL).

## Install order

1. `yaaif_agent_create` with `agent_type: "workflow"`
2. If Linear+approval / HITL: `yaaif_approval_strategy_create` (`publish: true`) or reuse via `yaaif_approval_strategies_list`; set `approval_strategy_id` on approval nodes
2b. If Linear+HOTL (inform without blocking): reuse or create a published strategy; set `approval_strategy_id` on `hotl` nodes (optional `continue_on_error`, default true). Do **not** expect pause/resume — HOTL auto-closes after notify.
3. `yaaif_ambient_agent_create` (`mode: "active"`, async on)
4. `yaaif_ambient_workflow_create` with `workflow_graph` + `trigger_rules`
5. Optional chat skill via `yaaif-create-skill` including exact local tools
   `list_ambient_workflows` + `trigger_ambient_workflow` (confirm via
   `yaaif_local_tools_list` family `ambient`)
6. Optional smoke: `yaaif_local_tool_call` → `list_ambient_workflows`
7. `yaaif_ambient_test_trigger` → `yaaif_ambient_runs_list`
8. If this workflow belongs to a Scenario, pass `spec_id` + `slot_key` on
   create/update and finish with `yaaif_agent_spec_sync_from_objects`. After
   editing `workflow_design` on the spec, use `yaaif_agent_spec_sync_to_objects`.

## Hand-off

Report workflow agent id, ambient agent id, workflow id, event/entity types, run ids.
