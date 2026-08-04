---
name: yaaif-create-ambient
description: >-
  Design and install YAAIF ambient workflows via the Cursor MCP bridge for
  customer/partner tenants (no monorepo required).
---

# Create ambient workflows on YAAIF

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

## Patterns

See [references/patterns.md](references/patterns.md). Default to **Linear**.

## Install order

1. `yaaif_agent_create` with `agent_type: "workflow"`
2. If Linear+approval / HITL: `yaaif_approval_strategy_create` (`publish: true`) or reuse via `yaaif_approval_strategies_list`; set `approval_strategy_id` on approval nodes
3. `yaaif_ambient_agent_create` (`mode: "active"`, async on)
4. `yaaif_ambient_workflow_create` with `workflow_graph` + `trigger_rules`
5. Optional chat skill via `yaaif-create-skill` including exact local tools
   `list_ambient_workflows` + `trigger_ambient_workflow` (confirm via
   `yaaif_local_tools_list` family `ambient`)
6. Optional smoke: `yaaif_local_tool_call` → `list_ambient_workflows`
7. `yaaif_ambient_test_trigger` → `yaaif_ambient_runs_list`

## Hand-off

Report workflow agent id, ambient agent id, workflow id, event/entity types, run ids.
