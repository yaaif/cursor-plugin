# Publishing `@yaaif/cursor-mcp`

Marketplace / local installs currently run the **committed** bridge bundle:

```json
{ "command": "node", "args": ["${CURSOR_PLUGIN_ROOT}/dist/yaaif-cursor-mcp.mjs"] }
```

## Publish checklist

1. Authenticate to npm with access to the `yaaif` org scope:

   ```bash
   npm login
   npm whoami
   ```

2. From this repo:

   ```bash
   cd packages/mcp
   npm test
   npm run build
   npm publish --access public
   ```

   Package version is in `packages/mcp/package.json` (currently **0.5.0**).

3. After publish succeeds, optionally switch root `mcp.json` to npx (customers without a local bundle):

```json
{
  "mcpServers": {
    "yaaif": {
      "command": "npx",
      "args": ["-y", "@yaaif/cursor-mcp@0.5.0"],
      "env": {
        "YAAIF_PLATFORM_PROFILE": "${YAAIF_PLATFORM_PROFILE}",
        "YAAIF_OIDC_AUTHORITY": "${YAAIF_OIDC_AUTHORITY}",
        "YAAIF_OIDC_CLIENT_ID": "${YAAIF_OIDC_CLIENT_ID}",
        "YAAIF_API_BASE_URL": "${YAAIF_API_BASE_URL}",
        "YAAIF_AGENT_BASE_URL": "${YAAIF_AGENT_BASE_URL}",
        "YAAIF_CONTROL_PLANE_BASE_URL": "${YAAIF_CONTROL_PLANE_BASE_URL}",
        "YAAIF_APPROVAL_BASE_URL": "${YAAIF_APPROVAL_BASE_URL}",
        "YAAIF_DEFAULT_TENANT_ID": "${YAAIF_DEFAULT_TENANT_ID}"
      }
    }
  }
}
```

Keep the committed `dist/yaaif-cursor-mcp.mjs` path until npm publish is confirmed (`npm view @yaaif/cursor-mcp version`).

4. Submit https://github.com/yaaif/cursor-plugin to [Cursor Marketplace publish](https://cursor.com/marketplace/publish).

## Notes

- `prepublishOnly` runs tests + build.
- If `npm publish` fails with `ENEEDAUTH` / 403, an org owner must grant publish rights — do not switch `mcp.json` to npx until the package is on the registry.
