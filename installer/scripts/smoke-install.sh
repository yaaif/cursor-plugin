#!/usr/bin/env bash
# Offline smoke of install.sh / uninstall.sh against a fake payload (no Node download).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_ROOT="$(cd "$INSTALLER_ROOT/.." && pwd)"

export YAAIF_INSTALLER_NO_OPEN=1
export YAAIF_INSTALLER_NO_LOGIN=1
export YAAIF_INSTALLER_NO_SETUP=1

TMP="$(mktemp -d "${TMPDIR:-/tmp}/yaaif-cursor-install-smoke.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FAKE_HOME="$TMP/home"
PAYLOAD="$TMP/payload"
mkdir -p "$FAKE_HOME" "$PAYLOAD/plugin/.cursor-plugin" "$PAYLOAD/plugin/dist" "$PAYLOAD/lib"

OS=darwin
if [[ "$(uname -s)" == "Linux" ]]; then
  OS=linux
fi
ARCH=arm64
case "$(uname -m)" in
  x86_64|amd64) ARCH=x64 ;;
esac
TRIPLE="${OS}-${ARCH}"

mkdir -p "$PAYLOAD/runtime/$TRIPLE/bin"
cat > "$PAYLOAD/plugin/.cursor-plugin/plugin.json" <<'EOF'
{"name":"yaaif","version":"1.1.0"}
EOF
cat > "$PAYLOAD/plugin/mcp.json" <<'EOF'
{
  "mcpServers": {
    "yaaif": {
      "command": "node",
      "args": ["${CURSOR_PLUGIN_ROOT}/dist/yaaif-cursor-mcp.mjs", "--client", "cursor"]
    }
  }
}
EOF
echo "export default {}" > "$PAYLOAD/plugin/dist/yaaif-cursor-mcp.mjs"
cat > "$PAYLOAD/plugin/run-mcp.sh" <<'EOF'
#!/usr/bin/env bash
echo ok
EOF
chmod +x "$PAYLOAD/plugin/run-mcp.sh"
cp "$INSTALLER_ROOT/runtime-manifest.json" "$PAYLOAD/runtime-manifest.json"
cp "$INSTALLER_ROOT/lib/next-steps.html" "$PAYLOAD/lib/next-steps.html"
cp "$INSTALLER_ROOT/lib/uninstall.sh" "$PAYLOAD/lib/uninstall.sh"
cp "$INSTALLER_ROOT/lib/common.sh" "$PAYLOAD/lib/common.sh"

cat > "$PAYLOAD/runtime/$TRIPLE/bin/node" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-p" && "${2:-}" == "process.versions.node" ]]; then
  echo "22.22.2"
  exit 0
fi
echo "fake-node"
EOF
chmod +x "$PAYLOAD/runtime/$TRIPLE/bin/node"

echo "== system Node path (absolute) =="
"$INSTALLER_ROOT/lib/install.sh" --payload "$PAYLOAD" --home "$FAKE_HOME"
DEST="$FAKE_HOME/.cursor/plugins/local/yaaif"
test -f "$DEST/dist/yaaif-cursor-mcp.mjs"
test -f "$FAKE_HOME/.yaaif/cursor/install-manifest.json"
test -f "$FAKE_HOME/.yaaif/cursor/NEXT_STEPS.html"
CMD="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["mcpServers"]["yaaif"]["command"])' "$DEST/mcp.json")"
SRC="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["node_source"])' "$FAKE_HOME/.yaaif/cursor/install-manifest.json")"
if command -v node >/dev/null 2>&1; then
  MAJOR="$(node -p "process.versions.node" | cut -d. -f1)"
  if [[ "$MAJOR" -ge 20 ]]; then
    [[ "$CMD" == /* ]] || { echo "expected absolute system node, got $CMD"; exit 1; }
    [[ "$CMD" != "node" ]] || { echo "mcp.json must not be bare node"; exit 1; }
    [[ "$SRC" == "system" ]] || { echo "expected node_source=system, got $SRC"; exit 1; }
    [[ ! -e "$DEST/runtime/node" ]] || { echo "runtime/node should be absent for system node"; exit 1; }
  fi
fi

echo "== force bundled Node path =="
"$INSTALLER_ROOT/lib/install.sh" --payload "$PAYLOAD" --home "$FAKE_HOME" --force-bundled-node
test -x "$DEST/runtime/node/bin/node"
CMD="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["mcpServers"]["yaaif"]["command"])' "$DEST/mcp.json")"
[[ "$CMD" == "$DEST/runtime/node/bin/node" || "$CMD" == "$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$DEST/runtime/node/bin/node")" ]] \
  || { echo "expected bundled absolute command, got $CMD"; exit 1; }
SRC="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["node_source"])' "$FAKE_HOME/.yaaif/cursor/install-manifest.json")"
[[ "$SRC" == "bundled" ]] || { echo "expected node_source=bundled, got $SRC"; exit 1; }

echo "== refuse downgrade when dest is verified =="
python3 - "$FAKE_HOME/.yaaif/cursor/install-manifest.json" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
data = json.loads(p.read_text())
data["plugin_version"] = "9.9.9"
p.write_text(json.dumps(data))
PY
"$INSTALLER_ROOT/lib/install.sh" --payload "$PAYLOAD" --home "$FAKE_HOME"
AFTER="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["plugin_version"])' "$FAKE_HOME/.yaaif/cursor/install-manifest.json")"
[[ "$AFTER" == "9.9.9" ]] || { echo "downgrade should have been skipped, got $AFTER"; exit 1; }

echo "== repair when dest is missing even if manifest is newer =="
rm -rf "$DEST"
"$INSTALLER_ROOT/lib/install.sh" --payload "$PAYLOAD" --home "$FAKE_HOME"
test -f "$DEST/dist/yaaif-cursor-mcp.mjs"
REPAIRED="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["plugin_version"])' "$FAKE_HOME/.yaaif/cursor/install-manifest.json")"
[[ "$REPAIRED" == "1.1.0" ]] || { echo "repair should rewrite manifest to package version, got $REPAIRED"; exit 1; }
VERIFIED="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("verified"))' "$FAKE_HOME/.yaaif/cursor/install-manifest.json")"
[[ "$VERIFIED" == "True" ]] || { echo "expected verified true, got $VERIFIED"; exit 1; }

echo "== uninstall keeps session =="
mkdir -p "$FAKE_HOME/.yaaif/cursor"
echo '{"tokens":{"access_token":"x"}}' > "$FAKE_HOME/.yaaif/cursor/session.json"
"$INSTALLER_ROOT/lib/uninstall.sh" --home "$FAKE_HOME" --user-files-only
test ! -e "$DEST"
test -f "$FAKE_HOME/.yaaif/cursor/session.json"
test ! -e "$FAKE_HOME/.yaaif/cursor/install-manifest.json"

echo "smoke-install: ok"
: "$PLUGIN_ROOT"
