#!/usr/bin/env node

// Preserve the published Cursor command while the shared bridge owns runtime
// behavior. Put the descriptor first so callers cannot accidentally override it.
process.argv.splice(2, 0, "--client", "cursor");

await import("@yaaif/platform-mcp");
