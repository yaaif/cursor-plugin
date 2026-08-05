---
name: yaaif-create-skill
description: >-
  Author a YAA\F SKILL.md pack and load it into the tenant catalog via the
  yaaif Cursor MCP bridge. Prefers platform local skill lifecycle tools when
  available. Works without the yaaif-platform monorepo.
---

# Create and load a YAA\F skill

```
Task Progress:
- [ ] 1. Auth + tenant
- [ ] 2. Capture intent + discover tools
- [ ] 3. Search existing / guided draft
- [ ] 4. Edit + validate module (local tools)
- [ ] 5. Enable + map agents (REST)
- [ ] 6. Refresh / runtime reload
```

## Prerequisites

Run `yaaif-auth` first. Optionally `yaaif_doctor` (confirm `local_tools`).

## Authoring

Read [references/frontmatter.md](references/frontmatter.md). Prefer lean chat skills unless SAP GUI / ambient / always-active is required.

- `id` is the path relative to the tenant skills root (e.g. `domain/my-skill`)
- Final path segment must equal frontmatter `name`
- Use **real** tool names from local tools or MCP catalog only
- Chat→ambient skills must include `list_ambient_workflows` and `trigger_ambient_workflow`

### Preferred path (platform local tools)

1. Discover: `yaaif_local_tools_list` (`family: skill`) and/or `yaaif-platform-tools`
2. Search: `yaaif_local_tool_call` → `skill_search` / `skill_search_workspace`
3. Draft: `yaaif_skill_guided_draft` (or `skill_create_guided_draft`)
4. Edit: `yaaif_skill_update_module_files` / `yaaif_skill_edit_section` / `yaaif_skill_develop`
5. **Check tools:** `yaaif_skill_tools_check` with the draft markdown (or `tools[]`) — must pass
6. Link tools: `yaaif_skill_mcp_tool_catalog` + `skill_tool_link_manager`
7. Validate: `yaaif_skill_validate_module` (strict) — prefer over `yaaif_skill_validate`
8. Map: `yaaif_skill_map_agents_merge`
9. `yaaif_skill_refresh` then `yaaif_skill_runtime_reload`

### Fallback (REST only)

When local tools are unavailable (doctor `local_tools` failed):

1. `yaaif_skill_create` with `id`, `description`, `instruction`, `tools` / `allowed_tools`, `enabled: true`
2. Companions via `yaaif_skill_write_file`
3. Prefer `yaaif_skill_map_agents_merge`
4. `yaaif_skill_validate` (optional)
5. `yaaif_skill_refresh` then `yaaif_skill_runtime_reload`

## File-aware skills

Call `yaaif_dev_session_ensure`, then exercise `yaaif_files_list` / `yaaif_file_load_context` while drafting. Put `files_list` / `file_load_context` (and `file_share_link` if needed) in frontmatter.

## Hand-off

Report skill id, validation result, enabled flag, mapped agent ids, and whether local lifecycle tools were used.
