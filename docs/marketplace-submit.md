# Marketplace submit checklist

Repository: https://github.com/yaaif/cursor-plugin

## Before submit

- [ ] `.cursor-plugin/plugin.json` has unique `name` (`yaaif`), description, version, **relative** `logo` (`assets/logo.svg`), license
- [ ] Logo files committed: `assets/logo.svg` and `assets/logo.png` (512×512 PNG fallback)
- [ ] Logo QA: after install, Plugins detail shows the YAAIF “Y” icon (not the generic cube). If cube persists for local installs, use rsync copy + **+ Add local plugin** (see README)
- [ ] Marketplace preview: relative logo resolves via `raw.githubusercontent.com/.../<sha>/assets/logo.svg`
- [ ] Absolute GitHub raw URL still works as fallback: https://raw.githubusercontent.com/yaaif/cursor-plugin/main/assets/logo.png
- [ ] `mcp.json` launches `dist/yaaif-cursor-mcp.mjs` (or published `@yaaif/cursor-mcp` after npm auth)
- [ ] Skills/commands have YAML frontmatter (`yaaif-auth`, `yaaif-plan-usecase`, `yaaif-doctor`, `yaaif-ops-support`, create-*)
- [ ] `yaaif_doctor` passes against a demo tenant (`ops_api` + `ops_telemetry` green when ClickHouse telemetry is up)
- [ ] README documents profiles (`hosted` / `local-hybrid` / `local`) and `/yaaif-login`
- [ ] SECURITY.md + LICENSE (Apache-2.0) present
- [ ] No secrets in repo (`.env`, keys, session dumps)

## Demo script (for reviewers / GIF)

1. Install plugin → set `YAAIF_PLATFORM_PROFILE=hosted` (or local-hybrid)
2. `/yaaif-doctor` → all green (or login prompted)
3. `/yaaif-login` → browser PKCE → tenant selected
4. `yaaif_catalog_overview` → shows agents/skills
5. `/yaaif-plan` with a short use case → plan file → stop for approval
6. Optional: `/yaaif-ops` with a known `session_id` → analyze + telemetry drill-down

Optional assets (screenshots/GIF): capture doctor + login + plan approve flow; store under `docs/assets/` when available.

## Submit

https://cursor.com/marketplace/publish — link this repository.
