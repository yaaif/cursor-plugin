---
name: yaaif-create-skill
description: >-
  Author a YAAIF SKILL.md pack and load it into the tenant catalog via the
  yaaif Cursor MCP bridge (create, enable, map agents, refresh). Use when the
  user asks to create/load a YAAIF skill from Cursor.
---

# Create and load a YAAIF skill

```
Task Progress:
- [ ] 1. Auth + tenant
- [ ] 2. Capture intent / skill type
- [ ] 3. Draft SKILL.md
- [ ] 4. yaaif_skill_create (+ files)
- [ ] 5. Enable + map agents
- [ ] 6. Refresh / runtime reload
```

## Prerequisites

Run skill `yaaif-auth` first (`yaaif_whoami` / login / tenant).

## Authoring rules

- Prefer lean chat skills unless SAP GUI / ambient / always-active is required.
- `id` is the path relative to the tenant skills root (e.g. `domain/my-skill`).
- Final directory segment must equal frontmatter `name`.
- Use **real** MCP tool names only in `tools` / `allowed_tools`.
- Chat→ambient skills must include `list_ambient_workflows` and `trigger_ambient_workflow`.

## Load into YAAIF

1. `yaaif_skill_create` with:
   - `id`, `description`, `instruction` (markdown body)
   - `tools` / `allowed_tools`
   - `enabled: true`
   - `updated_by: yaaif-cursor`
2. For companions (examples/references), `yaaif_skill_write_file` with relative `path`.
3. `yaaif_skill_enable` if create left it disabled.
4. `yaaif_skill_map_agents` with target `agent_id` + full desired `skill_ids` list (bulk replace).
5. `yaaif_skill_validate` (optional, `strict: true` for release).
6. `yaaif_skill_refresh` then `yaaif_skill_runtime_reload`.

## Hand-off

Report: skill id, enabled flag, mapped agent ids, validation summary.
