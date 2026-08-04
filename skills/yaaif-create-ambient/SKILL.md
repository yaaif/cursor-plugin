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
2. `yaaif_ambient_agent_create` (`mode: "active"`, async on)
3. `yaaif_ambient_workflow_create` with `workflow_graph` + `trigger_rules`
4. Optional chat skill via `yaaif-create-skill` including `list_ambient_workflows` + `trigger_ambient_workflow`
5. `yaaif_ambient_test_trigger` → `yaaif_ambient_runs_list`

## Hand-off

Report workflow agent id, ambient agent id, workflow id, event/entity types, run ids.
