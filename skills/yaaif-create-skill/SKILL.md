---
name: yaaif-create-skill
description: >-
  Author a YAAIF SKILL.md pack and load it into the tenant catalog via the
  yaaif Cursor MCP bridge. Works without the yaaif-platform monorepo.
---

# Create and load a YAAIF skill

```
Task Progress:
- [ ] 1. Auth + tenant
- [ ] 2. Capture intent
- [ ] 3. Draft SKILL.md
- [ ] 4. yaaif_skill_create (+ files)
- [ ] 5. Enable + map agents
- [ ] 6. Refresh / runtime reload
```

## Prerequisites

Run `yaaif-auth` first.

## Authoring

Read [references/frontmatter.md](references/frontmatter.md). Prefer lean chat skills unless SAP GUI / ambient / always-active is required.

- `id` is the path relative to the tenant skills root (e.g. `domain/my-skill`)
- Final path segment must equal frontmatter `name`
- Use **real** MCP catalog tool names only
- Chat→ambient skills must include `list_ambient_workflows` and `trigger_ambient_workflow`

Optionally write a local draft in the user's workspace, then load via API.

## Load into YAAIF

1. `yaaif_skill_create` with `id`, `description`, `instruction`, `tools` / `allowed_tools`, `enabled: true`
2. Companions via `yaaif_skill_write_file`
3. Prefer `yaaif_skill_map_agents_merge` (safe union). Use `yaaif_skill_map_agents` only when intentionally replacing the full list.
4. `yaaif_skill_validate` (optional)
5. `yaaif_skill_refresh` then `yaaif_skill_runtime_reload`

## Hand-off

Report skill id, enabled flag, mapped agent ids.
