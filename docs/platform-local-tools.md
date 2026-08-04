# Platform local tools (Cursor)

Agent-service exposes built-in MCP tools (skill lifecycle, files, ambient trigger, session state, …) at:

| Method | Path | Permission (any of) |
|--------|------|---------------------|
| `GET` | `/api/local-tools` | `agent.skills.read`, `agent.mcp_tools.read`, `agent.chat.use` |
| `GET` | `/api/local-tools/:name` | same |
| `POST` | `/api/local-tools/:name/call` | write perms; family-aware check inside handler |
| `POST` | `/api/local-tools/dev-session` | `agent.skills.write` or `agent.chat.use` |

Query params on list: `family`, `q`, `limit`, `offset`, `names_only=true`.

## Cursor bridge tools

- `yaaif_local_tools_list` / `yaaif_local_tool_get` / `yaaif_local_tool_call`
- `yaaif_dev_session_ensure` — auto-picks default skills agent when omitted
- `yaaif_skill_tools_check` — verify frontmatter tools against local + MCP catalogs
- Aliases: `yaaif_skill_validate_module`, `yaaif_skill_develop`, `yaaif_skill_guided_draft`, `yaaif_skill_update_module_files`, `yaaif_skill_edit_section`, `yaaif_list_ambient_workflows`, `yaaif_trigger_ambient_workflow`, `yaaif_files_list`, …

Skill: `yaaif-platform-tools` / command `/yaaif-platform-tools`.

## Authoring flow

1. `/yaaif-doctor` — confirm `local_tools` + `local_tools_smoke`
2. Draft SKILL.md tools from real names (`yaaif_local_tools_list`)
3. `yaaif_skill_tools_check` with markdown or `tools[]`
4. Prefer lifecycle locals (`yaaif_skill_guided_draft` → edit → `yaaif_skill_validate_module`) over raw REST write
5. Map agents / refresh as today

## Plan verify

`yaaif_plan_verify` / `yaaif_plan_dry_run` accept `local_tool_names` and load `/api/local-tools?names_only=true`.

## Generate reference markdown

With an authenticated session and agent-service that has `/api/local-tools`:

```bash
cd packages/mcp
npm run generate:local-tools-ref
```

Writes `skills/yaaif-platform-tools/references/local-tools.generated.md`.

## Deploy note

Cursor against hosted/local platforms only sees these endpoints after agent-service is upgraded with the local-tools admin API.
