---
name: yaaif-create-ambient
description: >-
  Design and install YAAIF ambient workflows (workflow agent, ambient agent,
  graph JSON, triggers, test-trigger) via the yaaif Cursor MCP bridge. Use when
  the user asks to create ambient workflows or chat→ambient packs from Cursor.
---

# Create ambient workflows on YAAIF

```
Task Progress:
- [ ] 1. Auth + tenant
- [ ] 2. Pick pattern
- [ ] 3. Ensure MCP tools exist
- [ ] 4. Create workflow agent + ambient agent
- [ ] 5. Create workflow graph + triggers
- [ ] 6. Optional chat skill
- [ ] 7. Test trigger
```

## Prerequisites

1. Skill `yaaif-auth`.
2. Domain MCP tools registered (skill `yaaif-create-mcp` or `yaaif_mcp_link_or_create`).
3. License/feature ambient enabled on the deployment.

## Patterns

| Pattern | Use when |
|---------|----------|
| Linear | Single automated path |
| Linear + approval | Mid/late HITL via `approval` nodes |
| Branching | `switch` / `if` gates |
| Recon / resolve | Batch detect + later clearance |
| Chat-triggered | Chat starts graph via trigger tools |

Default to **Linear** unless the user needs HITL, branches, or batch recon.

## Install order

1. **Workflow agent** — `yaaif_agent_create` with `agent_type: "workflow"`, `skill_ids` for ambient step skills if any.
2. **Ambient agent** — `yaaif_ambient_agent_create` with that `agent_id`, `mode: "active"`, `workflow_async_enabled: true`.
3. **Workflow** — `yaaif_ambient_workflow_create` with:
   - `ambient_agent_id`
   - `name`, `description`
   - `workflow_graph` (`nodes` + `edges`)
   - `trigger_rules` (`source_type`, `event_types`, `entity_types`)
4. **Chat skill** (optional) — skill `yaaif-create-skill` including `list_ambient_workflows` + `trigger_ambient_workflow`.
5. **Test** — `yaaif_ambient_test_trigger` then `yaaif_ambient_runs_list` / `yaaif_ambient_run_get`.

## Graph notes

- Keep node ids stable; edges use `from` / `to`.
- Tool names inside graph steps must match the MCP catalog exactly.
- Only reference approval strategy ids that already exist when using approval nodes.

## Hand-off

Report: workflow agent id, ambient agent id, workflow id, trigger event/entity types, test run ids.
