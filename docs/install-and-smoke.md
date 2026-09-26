# Install and smoke checklist

1. Build MCP from [yaaif/platform-mcp](https://github.com/yaaif/platform-mcp): `npm ci && npm run build`
2. Symlink or install plugin; configure URLs
3. Agent: `yaaif_configure_check` → `yaaif_login` → `yaaif_set_tenant` → `yaaif_whoami`
4. Skill: `yaaif_skill_create` → map → refresh → runtime reload
5. MCP: scaffold/deploy/register **or** `yaaif_mcp_link_or_create`
6. Ambient: workflow agent → ambient agent → workflow → test-trigger
7. Scenario: `yaaif_agent_spec_create` → bind/create with `spec_id`+`slot_key` → `yaaif_agent_spec_sync_to_objects` (apply) → `yaaif_agent_spec_coverage`

Offline: in a [platform-mcp](https://github.com/yaaif/platform-mcp) checkout, `npm test && npm run build`
