# Publishing `@yaaif/platform-mcp` and the Cursor compatibility wrapper

Marketplace / local installs launch the published bridge (same pin as Claude / Codex):

```json
{ "command": "npx", "args": ["-y", "@yaaif/platform-mcp@1.3.3", "--client", "cursor"] }
```

Install / profile setup:

```bash
npx -y @yaaif/platform-mcp@1.3.3 --install --client cursor --plugin-src ./cursor-plugin
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

   Package version is in `packages/mcp/package.json`. Publish the shared bridge
   first, then publish the compatibility wrapper:

   ```bash
   cd ../cursor-mcp
   npm publish --access public
   ```

3. Confirm `npm view @yaaif/platform-mcp version` reports `1.3.3` before relying on marketplace `npx --install`. The legacy `@yaaif/cursor-mcp` package remains a compatibility launcher. Root `mcp.json` already uses the npx pin.

Claude Code and Codex marketplace installs start `npx -y @yaaif/platform-mcp@<version> --client claude|codex` and cannot start until this package is on the public registry. After publish, bump the pin in `yaaif/claude-plugin` and `yaaif/codex-plugin` `.mcp.json` files. See [`claude-plugin/docs/npm-publish.md`](https://github.com/yaaif/claude-plugin/blob/main/docs/npm-publish.md).

4. Submit https://github.com/yaaif/cursor-plugin to [Cursor Marketplace publish](https://cursor.com/marketplace/publish).

## Notes

- `prepublishOnly` runs tests + build.
- If `npm publish` fails with `ENEEDAUTH` / 403, an org owner must grant publish rights — do not switch `mcp.json` to npx until the package is on the registry.
