#!/usr/bin/env bash
# Stage plugin files + official Node.js runtime for native installer packages.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_ROOT="$(cd "$INSTALLER_ROOT/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$INSTALLER_ROOT/lib/common.sh"

OS=""
ARCH=""
OUT_DIR=""
SKIP_NODE=false
SKIP_MCP_BUILD=false

usage() {
  cat <<'EOF'
Usage: stage-payload.sh [--os darwin|linux|win] [--arch arm64|x64] [--out DIR]
                        [--skip-node] [--skip-mcp-build]

Stages:
  <out>/plugin/          plugin tree (no .git / node_modules / installer build dirs)
  <out>/runtime/<triple> official Node.js 22 (unless --skip-node)
  <out>/lib/             install.sh + install.ps1
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --os) OS="$2"; shift 2 ;;
    --arch) ARCH="$2"; shift 2 ;;
    --out) OUT_DIR="$2"; shift 2 ;;
    --skip-node) SKIP_NODE=true; shift ;;
    --skip-mcp-build) SKIP_MCP_BUILD=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "unknown arg: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$OS" ]]; then
  OS="$(host_os)"
fi
if [[ -z "$ARCH" ]]; then
  ARCH="$(host_arch)"
fi
case "$OS" in
  darwin|linux|win) ;;
  *)
    echo "unsupported --os: $OS" >&2
    exit 1
    ;;
esac
case "$ARCH" in
  arm64|x64) ;;
  *)
    echo "unsupported --arch: $ARCH" >&2
    exit 1
    ;;
esac

to_unix_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$1"
  else
    printf '%s\n' "$1"
  fi
}

TRIPLE="$(runtime_triple "$OS" "$ARCH")"
PLUGIN_ROOT="$(to_unix_path "$PLUGIN_ROOT")"
INSTALLER_ROOT="$(to_unix_path "$INSTALLER_ROOT")"
if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$INSTALLER_ROOT/out/payload/${TRIPLE}"
else
  OUT_DIR="$(to_unix_path "$OUT_DIR")"
fi

CACHE_DIR="$(to_unix_path "${YAAIF_INSTALLER_CACHE:-$INSTALLER_ROOT/.cache}")"
MANIFEST="$INSTALLER_ROOT/runtime-manifest.json"
CLI="$PLUGIN_ROOT/dist/yaaif-cursor-mcp.mjs"

if [[ "$SKIP_MCP_BUILD" != true && ! -f "$CLI" ]]; then
  echo "Building MCP bundle..."
  (
    cd "$PLUGIN_ROOT/packages/mcp"
    if [[ -f package-lock.json ]]; then
      npm ci
    else
      npm install
    fi
    npm run build
  )
fi
if [[ ! -f "$CLI" ]]; then
  echo "missing $CLI — run: (cd packages/mcp && npm ci && npm run build)" >&2
  exit 1
fi

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/plugin" "$OUT_DIR/lib" "$OUT_DIR/runtime"

export COPYFILE_DISABLE=1
echo "Staging plugin → $OUT_DIR/plugin"
copy_plugin_tree() {
  python3 - "$PLUGIN_ROOT" "$OUT_DIR/plugin" <<'PY'
import os, shutil, sys
src, dest = sys.argv[1:3]
skip_names = {".git", "node_modules", ".DS_Store"}
skip_prefixes = ("installer/out", "installer/.cache", "installer/payload", ".github")

def ignore(dirpath, names):
    rel = os.path.relpath(dirpath, src)
    dropped = []
    for name in names:
        if name in skip_names or name.startswith("._"):
            dropped.append(name)
            continue
        rel_name = name if rel == "." else os.path.join(rel, name).replace("\\", "/")
        if any(rel_name == p or rel_name.startswith(p + "/") for p in skip_prefixes):
            dropped.append(name)
    return dropped

if os.path.isdir(dest):
    shutil.rmtree(dest)
shutil.copytree(src, dest, ignore=ignore, ignore_dangling_symlinks=True)
PY
  rm -rf "$OUT_DIR/plugin/installer"
}

if command -v rsync >/dev/null 2>&1 && [[ "$(uname -s)" != MINGW* && "$(uname -s)" != MSYS* && "$(uname -s)" != CYGWIN* ]]; then
  rsync -a \
    --exclude '.git' \
    --exclude '._*' \
    --exclude '.gitignore' \
    --exclude 'node_modules' \
    --exclude 'installer/out' \
    --exclude 'installer/.cache' \
    --exclude 'installer/payload' \
    --exclude '.DS_Store' \
    --exclude '.github' \
    "$PLUGIN_ROOT/" "$OUT_DIR/plugin/"
  rm -rf "$OUT_DIR/plugin/installer"
else
  copy_plugin_tree
fi

for f in install.sh install.ps1 uninstall.sh uninstall.ps1 common.sh next-steps.html; do
  cp "$INSTALLER_ROOT/lib/$f" "$OUT_DIR/lib/$f"
done
cp "$INSTALLER_ROOT/runtime-manifest.json" "$OUT_DIR/runtime-manifest.json"
cp "$INSTALLER_ROOT/THIRD_PARTY_NOTICES.md" "$OUT_DIR/THIRD_PARTY_NOTICES.md"
chmod +x "$OUT_DIR/lib/install.sh" "$OUT_DIR/lib/uninstall.sh" "$OUT_DIR/plugin/run-mcp.sh"
find "$OUT_DIR/plugin" \( -name '._*' -o -name '.DS_Store' \) -delete 2>/dev/null || true

if [[ "$SKIP_NODE" == true ]]; then
  echo "Skipping Node.js runtime (--skip-node)"
else
  ARCHIVE="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["artifacts"][sys.argv[2]]["archive"])' "$MANIFEST" "$TRIPLE")"
  SHA="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["artifacts"][sys.argv[2]]["sha256"])' "$MANIFEST" "$TRIPLE")"
  BASE="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["dist_base_url"])' "$MANIFEST")"
  URL="${BASE}/${ARCHIVE}"
  mkdir -p "$CACHE_DIR"
  ARCHIVE_PATH="$CACHE_DIR/$ARCHIVE"
  if [[ ! -f "$ARCHIVE_PATH" ]]; then
    echo "Downloading $URL"
    curl -fL --retry 3 --retry-delay 2 -o "$ARCHIVE_PATH.partial" "$URL"
    mv "$ARCHIVE_PATH.partial" "$ARCHIVE_PATH"
  else
    echo "Using cached $ARCHIVE_PATH"
  fi
  verify_sha256 "$ARCHIVE_PATH" "$SHA"

  EXTRACT="$OUT_DIR/runtime/.extract"
  rm -rf "$EXTRACT"
  mkdir -p "$EXTRACT"
  case "$ARCHIVE" in
    *.tar.gz|*.tgz) tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT" ;;
    *.zip)
      if command -v unzip >/dev/null 2>&1; then
        unzip -q "$ARCHIVE_PATH" -d "$EXTRACT"
      else
        python3 -c 'import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$ARCHIVE_PATH" "$EXTRACT"
      fi
      ;;
    *)
      echo "unsupported archive: $ARCHIVE" >&2
      exit 1
      ;;
  esac
  INNER="$(find "$EXTRACT" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "$INNER" ]]; then
    echo "failed to unpack Node.js archive" >&2
    exit 1
  fi
  DEST_RT="$OUT_DIR/runtime/$TRIPLE"
  rm -rf "$DEST_RT"
  mv "$INNER" "$DEST_RT"
  rm -rf "$EXTRACT"
  find "$DEST_RT" \( -name '._*' -o -name '.DS_Store' \) -delete 2>/dev/null || true
  echo "Staged Node.js → $DEST_RT"
fi

python3 - "$OUT_DIR" "$PLUGIN_ROOT" "$TRIPLE" <<'PY'
import json, pathlib, sys
out, root, triple = map(pathlib.Path, sys.argv[1:4])
plugin_ver = json.loads((root / ".cursor-plugin" / "plugin.json").read_text())["version"]
manifest = json.loads((out / "runtime-manifest.json").read_text())
meta = {
    "plugin_version": plugin_ver,
    "runtime_triple": str(triple),
    "node_version": manifest["node_version"],
}
(out / "payload-info.json").write_text(json.dumps(meta, indent=2) + "\n")
print("Staged payload", out)
print("  plugin", plugin_ver, "triple", triple)
PY
