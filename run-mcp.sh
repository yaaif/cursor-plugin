#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
CLI="$ROOT/packages/mcp/dist/cli.js"
if [[ ! -f "$CLI" ]]; then
  echo "yaaif cursor mcp missing built bridge at $CLI" >&2
  echo "Run: (cd \"$ROOT/packages/mcp\" && npm ci && npm run build)" >&2
  exit 1
fi
exec node "$CLI" "$@"
