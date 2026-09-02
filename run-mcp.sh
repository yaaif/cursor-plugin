#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
CLI="$ROOT/dist/yaaif-cursor-mcp.mjs"

resolve_node() {
  local bundled="$ROOT/runtime/node/bin/node"
  if [[ -x "$bundled" ]]; then
    printf '%s\n' "$bundled"
    return 0
  fi
  if command -v node >/dev/null 2>&1; then
    local ver major
    ver="$(node -p "process.versions.node" 2>/dev/null || true)"
    major="${ver%%.*}"
    if [[ -n "${major}" && "${major}" =~ ^[0-9]+$ && "${major}" -ge 20 ]]; then
      command -v node
      return 0
    fi
  fi
  echo "YAAIF Cursor plugin: Node.js >= 20 not found. Re-run the YAAIF Cursor plugin installer or install Node 20+." >&2
  return 1
}

NODE_BIN="$(resolve_node)"

if [[ ! -f "$CLI" ]]; then
  echo "Missing $CLI — building bundle..." >&2
  (cd "$ROOT/packages/mcp" && npm ci && npx esbuild src/cli.ts --bundle --platform=node --format=esm --outfile=../../dist/yaaif-cursor-mcp.mjs --packages=bundle)
fi
exec "$NODE_BIN" "$CLI" --client cursor "$@"
