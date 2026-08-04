# Changelog

## 0.8.0

- Dev-session auto-picks default skills agent; skills runtime attached on local-tool calls
- `yaaif_skill_tools_check` for frontmatter/tools vs local+MCP catalogs
- Plan verify/dry-run include `local_tool_names`
- Doctor smoke-calls `list_ambient_workflows`
- More aliases: update module files, edit section, list/trigger ambient
- List pagination + `names_only`; family-aware RBAC; structured local-tool call audit logs
- Docs: `docs/platform-local-tools.md`; `npm run generate:local-tools-ref`
- Integration smoke for local-tools when `YAAIF_INTEGRATION=1`

## 0.7.0

- Platform local tools bridge: `yaaif_local_tools_list` / `get` / `call` / catalog overview
- `yaaif_dev_session_ensure` for files_* / session_state_* authoring
- Convenience aliases: `yaaif_skill_validate_module`, `yaaif_skill_develop`, `yaaif_skill_guided_draft`, `yaaif_skill_mcp_tool_catalog`, `yaaif_files_list`, `yaaif_file_load_context`
- New skill/command `yaaif-platform-tools` (+ local-tools reference)
- `yaaif-create-skill` / plan / ambient prefer platform lifecycle locals
- Doctor `local_tools` check; catalog overview includes local tools
- Requires agent-service `/api/local-tools` endpoints

## 0.6.0

- `yaaif_doctor` + `/yaaif-doctor` end-to-end connectivity checks
- Fix `yaaif_skill_get` via catalog `?ids=`
- TLS: extra CA / client mTLS via profile or `YAAIF_EXTRA_CA_FILE`
- `yaaif_platform_export` shell + Cursor variable JSON
- Plan execution save/update/resume for mid-run recovery
- Ambient run pause/resume/approve/reject/stop + approval inbox decide
- Client-side `agent_type` filter on agent list
- Device-code login (`yaaif_login_device`) + Keycloak device grant enablement
- Opt-in local telemetry counters; secret redaction helpers
- Marketplace submit checklist; SECURITY session hardening notes

## 0.5.0

- Platform profiles: `hosted` / `local-hybrid` / `local` + custom save (`yaaif_platform_*`)
- `yaaif_ensure_session` one-shot auth + tenant resolution
- Smart tenants: set by name/slug/uuid, normalized list, last-tenant / single auto-select
- Session stores `profile_id` + `oidc_authority`; issuer mismatch forces re-login
- OIDC discovery in `configure_check`; optional Keycloak `end_session` on logout
- Auth skill / `/yaaif-login` updated for profile-first flow

## 0.4.0

- Safe skill mapping: `yaaif_skill_map_agents_merge`
- Agent update: `yaaif_agent_update`
- Desktop worker tools: list workers + skill-mappings get/set/delete (control-plane)
- Approval strategy tools: list/get/create/publish (approval-service)
- Plan helpers: `yaaif_plan_verify`, `yaaif_plan_dry_run`
- Plan skill: interview mode, dry-run, examples, approval + desktop steps
- Config: `YAAIF_CONTROL_PLANE_BASE_URL`, `YAAIF_APPROVAL_BASE_URL`
- Package `@yaaif/cursor-mcp@0.4.0`

## 0.3.0

- `yaaif-plan-usecase` skill + `/yaaif-plan`: propose chat/ambient/desktop architecture, then execute after approval
- Decomposition and plan-template references for partner use-case planning

## 0.2.0

- Marketplace packaging (LICENSE Apache-2.0, SECURITY.md, logo, commands)
- TypeScript MCP bridge (`packages/mcp`) with full tool surface + `yaaif_configure_check`
- Partner-oriented skills and references (no monorepo required)
- Hosted at https://github.com/yaaif/cursor-plugin

## 0.1.0

- Initial Go stdio bridge and skill stubs (superseded by 0.2.0 runtime)
