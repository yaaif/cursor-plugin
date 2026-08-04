# Plan file template

Write this file to the user workspace as `yaaif-plans/<slug>-plan.md`.
Replace all `{{PLACEHOLDERS}}`. Delete sections that are not applicable only
after marking them N/A — prefer keeping the headings for a consistent shape.

```markdown
# YAAIF use-case plan: {{TITLE}}

- **Slug:** {{SLUG}}
- **Tenant:** {{TENANT_ID}}
- **Status:** proposed | approved | executing | done
- **Created:** {{DATE}}

## 1. Use case summary

{{1–3 sentences: outcome, actors, systems}}

## 2. Intent capture

| Field | Value |
|-------|-------|
| Outcome | |
| Triggers | chat / schedule / webhook / batch / manual |
| Sync vs async | |
| HITL | yes/no — where |
| Systems | |
| Desktop GUI | yes/no |
| Key entities | |

## 3. Catalog reuse

| Kind | Existing id / name | Reuse? | Notes |
|------|--------------------|--------|-------|
| Agent | | | |
| Skill | | | |
| MCP tool / server | | | |
| Ambient workflow | | | |

## 4. Components

### 4.1 MCP tools

| Action | Name | Notes |
|--------|------|-------|
| create / reuse / none | | |

### 4.2 Agents

| Action | Name | `agent_type` | Notes |
|--------|------|--------------|-------|
| create / reuse | | skills / workflow / desktop | |

### 4.3 Ambient

| Action | Name | Pattern | Trigger rules summary |
|--------|------|---------|------------------------|
| create / reuse / none | | Linear / Linear+approval / Branching / Recon-resolve / Chat-triggered | |

### 4.4 Skills

| Action | Skill id | Kind | Tools (real names) | Maps to agent |
|--------|----------|------|--------------------|---------------|
| create / reuse | | chat / orchestration / desktop / ambient-step / base | | |

## 5. Skill ↔ agent mappings

| Agent id / name | Final skill_ids (merged) |
|-----------------|--------------------------|
| | |

## 6. Install order

1. [ ] MCP deploy/register (if needed)
2. [ ] Create / bind agents
3. [ ] Ambient agent + workflow (if needed)
4. [ ] Create / load skills
5. [ ] Enable + map skills (merge existing)
6. [ ] Refresh / runtime reload
7. [ ] Verify (catalog + optional test-trigger)

## 7. Test plan

- Chat smoke phrase(s): …
- Ambient test-trigger payload (if any): …
- Success criteria: …

## 8. Risks / follow-ups

- Desktop worker↔skill mappings (Admin / control-plane) if desktop skills are used
- Approval strategy ids if approval nodes exist
- Missing credentials / MCP secrets
- Other: …

## 9. Execution log

| Step | Result ids | Notes |
|------|------------|-------|
| | | |
```
