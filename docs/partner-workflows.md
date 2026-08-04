# Partner workflows

Partners do **not** need the yaaif-platform monorepo.

## Recommended order

1. Auth (`/yaaif-login`)
2. Multi-capability use cases: `/yaaif-plan` (propose → approve → execute)
3. Or step-by-step:
   - MCP tools (`/yaaif-new-mcp`) — deploy or link
   - Ambient workflow (`/yaaif-new-workflow`) when automation is required
   - Chat skill (`/yaaif-new-skill`) that uses catalog tools / ambient triggers

## Workspace layout (partner repo)

```text
my-yaaif-pack/
├── mcp-servers/my-domain-mcp-service/   # from yaaif_mcp_scaffold
├── skills/...                           # optional local drafts
└── ambient-workflows/*.json             # optional local drafts
```

Load into YAAIF via MCP bridge tools — do not rely on platform SQL seed scripts.
