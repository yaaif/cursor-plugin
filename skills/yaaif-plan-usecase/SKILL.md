---
name: yaaif-plan-usecase
description: >-
  Understand a business use case, propose a YAAIF architecture plan (chat
  skills, ambient workflows, desktop skills, agents, MCP tools, mappings),
  wait for approval, then execute via yaaif-create-* skills and bridge tools.
  Use when the user describes a process to automate, asks how to split a
  solution across chat/ambient/desktop, or wants an end-to-end install plan.
---

# Plan and implement a YAAIF use case

Turn a use-case description into an **approved install plan**, then implement it
by delegating to existing plugin skills and `yaaif_*` bridge tools. Do not jump
straight to create tools before the plan is approved.

```
Task Progress:
- [ ] 1. Auth + catalog snapshot
- [ ] 2. Capture intent
- [ ] 3. Decompose (chat / ambient / desktop / MCP / agents)
- [ ] 4. Write plan file + stop for approval
- [ ] 5. Execute (MCP → agents → ambient → skills → map)
- [ ] 6. Verify + hand off
```

## Prerequisites

1. `yaaif-auth` (session + non-empty tenant)
2. Read [references/decomposition.md](references/decomposition.md)
3. Emit plans using [references/plan-template.md](references/plan-template.md)

## Phase A — Propose (always first)

### 1. Auth + catalog

- Ensure auth via `yaaif-auth`
- Call `yaaif_catalog_overview`
- Use targeted list tools when needed: `yaaif_agent_list`, `yaaif_skill_list`,
  `yaaif_mcp_tools_list`, `yaaif_ambient_workflow_list`
- Prefer **reuse** of existing agents / skills / MCP tools / workflows when names
  or purposes clearly overlap

### 2. Capture intent

Extract (infer; ask **at most one** clarifying question for the biggest gap):

- Business outcome
- Triggers (chat, schedule, webhook, batch, manual)
- Sync interactive vs async / multi-step
- HITL / approvals
- Systems (SAP OData, SAP GUI, custom APIs, none)
- Desktop / OS automation needs
- Entities and ids the process cares about

Confirm in 1–2 sentences, then continue.

### 3. Decompose

Apply [references/decomposition.md](references/decomposition.md). Produce a
component list covering only what is needed:

| Component | When |
|-----------|------|
| MCP tools | Domain APIs missing from catalog |
| Chat agent (`agent_type: skills`) | Interactive chat skills |
| Workflow agent (`agent_type: workflow`) | Host for ambient |
| Desktop agent (`agent_type: desktop`) | Desktop skills need a home |
| Ambient agent + workflow | Async / batch / schedule / HITL graphs |
| Chat skill | Triage, Q&A, light tools |
| Chat orchestration skill | Chat → `trigger_ambient_workflow` |
| Desktop skill | SAP GUI / local UI (`classification: desktop`) |
| Ambient step skill | Only when a graph step needs a dedicated skill |

State the ambient pattern briefly when ambient is in scope (Linear default;
see `yaaif-create-ambient` patterns).

### 4. Write plan + stop

1. Write `yaaif-plans/<slug>-plan.md` in the **user workspace** using the plan
   template (slug = short hyphen-case domain, e.g. `invoice-clearance`).
2. Summarize the plan in chat (components + install order).
3. **Stop.** Ask for explicit approval (`approve`, `go ahead`, or equivalent).
4. Do **not** call create/deploy/map/enable tools until the user approves.
5. If the user requests changes, revise the plan file and stop again.

## Phase B — Execute (only after approval)

Follow this order. Skip steps the plan marks as reuse / not needed.

1. **MCP** — If the plan lists missing tools, use `yaaif-create-mcp` (scaffold →
   deploy → register). Verify with `yaaif_mcp_tools_list`.
2. **Agents** — `yaaif_agent_create` for each planned agent with the correct
   `agent_type` (`skills` | `workflow` | `desktop`). Reuse existing ids from the
   plan when marked reuse.
3. **Ambient** — Use `yaaif-create-ambient` (workflow agent → ambient agent →
   workflow graph + triggers). Do not invent MCP tool names inside step configs.
4. **Skills** — Use `yaaif-create-skill` for each chat / orchestration / desktop
   / ambient-step skill. Chat→ambient skills **must** include
   `list_ambient_workflows` and `trigger_ambient_workflow`.
5. **Map** — For each agent assignment:
   - `yaaif_agent_get` to read current `skill_ids`
   - **Merge** new skill ids with existing ones (bulk map **replaces** the full
     list)
   - `yaaif_skill_map_agents` with the merged list
   - Ensure skills are enabled (`yaaif_skill_enable` / create with `enabled: true`)
6. **Reload** — `yaaif_skill_refresh` and/or `yaaif_skill_runtime_reload` when skills
   changed.
7. **Verify** — `yaaif_catalog_overview`; if ambient was created,
   `yaaif_ambient_test_trigger` then `yaaif_ambient_runs_list` when appropriate.

Update the plan file's execution checklist with created ids as you go.

## Mapping rules

- `yaaif_skill_map_agents` is a **bulk replace** per agent — never send only the
  new skill id without merging existing mappings.
- Chat skills map to chat (`skills`) agents.
- Desktop skills map to desktop agents when created; note that **worker↔skill**
  mappings (control-plane) are **not** available via this plugin — call that out
  as Admin UI / ops follow-up.
- Ambient graphs use workflow + ambient agents; chat orchestration skills map to
  the chat agent that should trigger the workflow.

## Hand-off

Report:

- Plan path
- Created / reused ids (agents, ambient agents, workflows, skills, MCP tools)
- Skill↔agent mapping summary
- What still needs Admin UI (especially desktop worker skill mappings)
- How to smoke-test (chat phrase and/or ambient test trigger)

## Ground rules

- Propose before mutate; never auto-execute without approval
- Prefer reuse over duplicate skills/workflows/agents
- One clarifying question max in Phase A
- Use only real MCP catalog tool names
- Delegate implementation details to `yaaif-create-mcp`, `yaaif-create-ambient`,
  and `yaaif-create-skill` — this skill owns orchestration and sequencing
- No monorepo required; write plan + drafts in the user workspace
- Never use S2S, desktop connection keys, or AI-gateway keys
