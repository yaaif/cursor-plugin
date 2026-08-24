# Partner workflows

Partners do **not** need the yaaif-platform monorepo.

## Recommended order

1. Auth (`/yaaif-login`) then `/yaaif-doctor` (confirm `local_tools` / `ops_api` / `ops_telemetry`)
2. Incident triage: `/yaaif-ops` (read-only session/ambient/desktop analysis)
3. Multi-capability use cases: `/yaaif-plan` (propose → approve → Scenario → execute; verify `local_tool_names`)
4. Maintain an existing Scenario (Admin UI **Open in Cursor** or `spec_id`): `/yaaif-scenario`. Sync with `/yaaif-sync-scenario`.
5. Or step-by-step:
   - MCP tools (`/yaaif-new-mcp`) — settings preflight → deploy compose or kubernetes_gitops (or link); mint/bind API keys when the MCP calls platform APIs
   - Ambient workflow (`/yaaif-new-workflow`) when automation is required
   - Discover platform tools (`/yaaif-platform-tools`) before inventing skill `tools:`
   - Chat skill (`/yaaif-new-skill`) — prefer lifecycle locals + `yaaif_skill_tools_check`

See [platform-local-tools.md](platform-local-tools.md).

## Workspace layout (partner repo)

```text
my-yaaif-pack/
├── mcp-servers/my-domain-mcp-service/   # from yaaif_mcp_scaffold
├── skills/...                           # optional local drafts
└── ambient-workflows/*.json             # optional local drafts
```

Load into YAA\F via MCP bridge tools — do not rely on platform SQL seed scripts.
