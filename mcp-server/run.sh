#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ -x "$ROOT/bin/yaaif-cursor-mcp" ]]; then
  exec "$ROOT/bin/yaaif-cursor-mcp"
fi

exec go run ./cmd/yaaif-cursor-mcp
