#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
CLI="$ROOT/dist/yaaif-cursor-mcp.mjs"
if [[ ! -f "$CLI" ]]; then
  echo "Missing $CLI — building bundle..." >&2
  (cd "$ROOT/packages/mcp" && npm ci && npx esbuild src/cli.ts --bundle --platform=node --format=esm --outfile=../../dist/yaaif-cursor-mcp.mjs --packages=bundle)
fi
exec node "$CLI" "$@"
