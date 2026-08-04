# Publishing `@yaaif/cursor-mcp`

Marketplace installs currently run the committed bridge:

```json
{ "command": "node", "args": ["packages/mcp/dist/cli.js"] }
```

After an npm org owner authenticates (`npm login` for the `yaaif` scope):

```bash
cd packages/mcp
npm publish --access public
```

Then update root `mcp.json` to:

```json
{
  "mcpServers": {
    "yaaif": {
      "command": "npx",
      "args": ["-y", "@yaaif/cursor-mcp@0.2.0"],
      "env": {
        "YAAIF_OIDC_AUTHORITY": "${YAAIF_OIDC_AUTHORITY}",
        "YAAIF_OIDC_CLIENT_ID": "${YAAIF_OIDC_CLIENT_ID}",
        "YAAIF_API_BASE_URL": "${YAAIF_API_BASE_URL}",
        "YAAIF_AGENT_BASE_URL": "${YAAIF_AGENT_BASE_URL}",
        "YAAIF_DEFAULT_TENANT_ID": "${YAAIF_DEFAULT_TENANT_ID}"
      }
    }
  }
}
```

Submit https://github.com/yaaif/cursor-plugin to [Cursor Marketplace publish](https://cursor.com/marketplace/publish).
