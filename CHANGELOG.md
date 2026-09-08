# Changelog

## Unreleased

- `@yaaif/platform-mcp@1.3.3`: docs-only. npm README is standalone (no platform-repo mention). `--install` writes `@yaaif/platform-mcp@1.3.3`.
- `@yaaif/platform-mcp@1.3.2`: npm README documents full Cursor / Claude Code / Codex install, dependencies, and IDE registration steps.
- `@yaaif/platform-mcp@1.3.1`: `--install` / `--setup` ask for hosted `https://platform.yaaif.ai` or another YAAIF URL instead of always opening hosted login. Non-interactive: `--yaaif-url` or `--profile`.

## 1.3.0

- Plugin manifest version aligned with `@yaaif/platform-mcp` 1.3.0 and the Claude / Codex plugins.
- `/yaaif-scenario` and `/yaaif-sync-scenario` use `yaaif_agent_spec_sync_preview`
  / `yaaif_agent_spec_sync_apply` (preview then apply / adopt). CI
  `scripts/check-plugin.py` asserts the ten command names and that contract.
- Neutral Node installer: `npx @yaaif/platform-mcp@1.3.0 --install --client cursor|claude|codex`. Cursor dest `mcp.json` uses absolute `node` + `cli.js` (Cursor PATH often has no `npx`). Copy is staging-swap; newer healthy dest is kept unless `--force`. Refuses `_npx` cache CLI paths unless `--cli-path`. `--no-login` does not mutate env. Doctor checks `node_runtime`, local dest, and launch command. Native `.pkg` / `.msi` / `.deb` packages, bundled Node runtime, `run-mcp` wrappers, and GitHub `installer_update` are removed.

- MCP bridge (`@yaaif/platform-mcp` 1.3.0): added `claude` as a third `--client` (alongside `cursor`/`codex`) for the new YAAIF Claude Code plugin — `yaaif-claude` OIDC client id, `~/.yaaif/claude` state home, generic (non-logo) callback page branding. `registerClients.test.ts` now asserts all three clients register an identical tool contract.
- CI: fixed the `tools/list` smoke test, which was broken since the Codex client change added a required `--client` flag that the smoke test wasn't passing.

- Scenarios (Agent Specs): `yaaif_agent_spec_*` create/list/get/update, plus
  `update_segment`, `sync_workflow_design`, `sync_from_objects`,
  `sync_to_objects`, `adopt`, `publish`, `processing`.
  Bindings default to `source=agent_spec`. Catalog object edits made through
  the plugin are recorded back onto the spec.
- Skill/command: `yaaif-scenario` / `/yaaif-scenario` to create or maintain a
  selected spec (including Admin UI **Open in Cursor**).
- Command: `/yaaif-sync-scenario` to pull the spec from live objects or push
  spec design onto bound objects.

## 1.1.0

- Ambient authoring is step-only: create-ambient / plan decomposition teach ACTION, MESSAGE, BRANCH, WAIT, HUMAN, TERMINAL — not the W→E→G→O→R engine spine. `yaaif_ambient_workflow_create` / `_update` warn (do not fail) when `workflow_graph` is engine-spine-only.
- Ops run-path shaping: `yaaif_ops_ambient_run_get` and `yaaif_ops_analyze` attach `run_path` (Coverage `reached/total`, Path `executed/reached`, current step, Admin UI canvas deep link). Run status wins over leftover wait blocks; never report fake percent-complete.
- File/artifact ops for YAA\F ADK-style artifacts:
  - Local aliases: `yaaif_load_artifacts`, `yaaif_files_search`, `yaaif_file_share_link`, `yaaif_generate_file`; richer `yaaif_files_list` / `yaaif_file_load_context` (artifact name + version)
  - REST helpers: `yaaif_file_artifact_versions`, `yaaif_file_artifact_delete`, `yaaif_file_get_extracted`, `yaaif_session_files_list` (`latest_only`)
  - Shared `devSession` helper for local-tools + file REST + doctor smoke
  - Doctor: `local_tools_files`, `local_tools_files_smoke`, `file_artifacts_api` (+ existing `file_registry*`)
  - `yaaif_catalog_overview` includes `file_registry_lifecycle`
  - Docs: `docs/file-artifacts.md`; ops skill notes artifact_name/version triage
- Docs/skills updated for file-aware authoring with `load_artifacts`

## 1.0.0

- Align plugin major version with YAA\F platform 1.0.0

## 0.12.2

- TLS: for `local` / `local-hybrid`, always merge mkcert `rootCA.pem` even when `YAAIF_EXTRA_CA_FILE` / `NODE_EXTRA_CA_CERTS` is set
- Startup: prefer `~/.yaaif/cursor/active-profile.json` (`yaaif_platform_use`) over Cursor plugin var `YAAIF_PLATFORM_PROFILE` (defaults to `hosted`)
- Plugin vars: pass through `YAAIF_EXTRA_CA_FILE` / client mTLS cert+key
- Fix: ignore unexpanded `${YAAIF_*}` placeholders so missing client cert vars do not crash MCP startup

## 0.12.1

- TLS: auto-discover mkcert `rootCA.pem` for `local` / `local-hybrid` (`*.yaaif.local`) so Node trusts Traefik without manual `YAAIF_EXTRA_CA_FILE`
- Doctor: `tls_ca` check + `ca_source` / `ca_file_resolved`; clearer hints on certificate verify failures
- `yaaif_ensure_session`: reinstall TLS after profile apply; auto-switch `local` → `local-hybrid` when the saved session issuer is `platform.yaaif.com`

## 0.12.0

- MCP deployments: full lifecycle for compose + kubernetes_gitops (`update` / `redeploy` / `stop` / `delete`)
- Read-only `yaaif_deployment_settings_get` + `yaaif_deployment_settings_status` preflight
- Method-aware `yaaif_mcp_deployment_logs` (compose `/logs` vs k8s `/k8s/logs`) + `yaaif_mcp_deployment_k8s_status`
- Fix create default `transport_type` → `STREAMABLE_HTTP`; inherit tenant `default_deployment_method` when omitted
- Create accepts `client_secret_headers`; catalog overview includes deployment settings status
- Skill/docs: `deploy-methods.md`; create-mcp + plan install order cover both methods

## 0.11.0

- Tenant API keys for MCP → platform APIs: `yaaif_api_key_list|get|create|update|rotate|delete|bind_deployment`
- `yaaif_mcp_deployment_create` accepts `secret_env`; catalog overview includes `api_keys`
- Skills/rules: create-mcp + plan install order mint/bind scoped API keys (never S2S in MCP pods)
- Docs: `skills/yaaif-create-mcp/references/api-keys.md`

## 0.10.2

- Doctor: `ops_telemetry` check (flow-events proxy / metrics RBAC)
- Unified `yaaif_ops_telemetry` (`resource=messages|events|flow_events|insights|desktop_logs|ambient_logs`); keep thin aliases
- Response shaping: `summary_only`, `max_chars`, `max_items` on ops tools
- Ops skill: fixed drill-down order + escalation template
- Local install docs: rsync + Add local plugin (symlink logo caveat); marketplace logo QA
- configure-environment: ClickHouse requirement for ops telemetry on local/hybrid
- CI asserts `yaaif_ops_telemetry`; unit tests for ops shaping

## 0.10.1

- Telemetry RO via ops facade: `yaaif_ops_session_messages|events`, `yaaif_ops_flow_events`, `yaaif_ops_session_insights`, `yaaif_ops_desktop_worker_logs`, `yaaif_ops_ambient_worker_logs`
- Requires agent-service proxies under `GET /api/ops/*` (api-server → telemetry-service); still no direct telemetry URL in the plugin

## 0.10.0

- Ops support hardened against production agent-service `/api/ops`:
  - Prefer summaries; `include_raw` requires `ops.support.raw`
  - Surface `diagnostics_version`, `partial_errors`, `cache_hit`
  - Docs: RBAC `ops.support.read` + downstream metrics/desktop/harness reads
- Align DEVELOPER role expectations with ops.support.read + metrics/desktop/harness read

## 0.9.0

- Read-only ops support: `yaaif_ops_analyze` / `correlate` / session / ambient / desktop tools
- Skill + command `/yaaif-ops` (`yaaif-ops-support`)
- Doctor `ops_api` check for agent-service `GET /api/ops/correlate`
- Fix ambient runs list filter: `ambient_workflow_id` (+ status/q)
- Docs: `docs/ops-support.md`
- Requires agent-service `/api/ops/*` RO facade

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
