# Install and smoke checklist

1. Build MCP: `cd packages/mcp && npm ci && npm run build`
2. Symlink or install plugin; configure URLs
3. Agent: `yaaif_configure_check` → `yaaif_login` → `yaaif_set_tenant` → `yaaif_whoami`
4. Skill: `yaaif_skill_create` → map → refresh → runtime reload
5. MCP: scaffold/deploy/register **or** `yaaif_mcp_link_or_create`
6. Ambient: workflow agent → ambient agent → workflow → test-trigger

Offline: `cd packages/mcp && npm test && npm run build`
