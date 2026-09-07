#!/usr/bin/env bash
# Install or update the YAAIF Cursor plugin into ~/.cursor/plugins/local/yaaif.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
  # shellcheck source=common.sh
  source "$SCRIPT_DIR/common.sh"
fi

PAYLOAD=""
HOME_DIR=""
TARGET_USER=""
FORCE_BUNDLED_NODE=false
FORCE=false
MIN_NODE_MAJOR=20

usage() {
  cat <<'EOF'
Usage: install.sh --payload DIR [--home DIR] [--user NAME]
                  [--force-bundled-node] [--force]

Copies the staged plugin into ~/.cursor/plugins/local/yaaif.
Always writes an absolute Node.js path into the installed mcp.json.
Uses system Node.js >= 20 when present (resolved to a realpath); otherwise
installs the bundled official Node.js runtime next to the plugin.
Refuses to downgrade unless --force is set.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --payload) PAYLOAD="$2"; shift 2 ;;
    --home) HOME_DIR="$2"; shift 2 ;;
    --user) TARGET_USER="$2"; shift 2 ;;
    --force-bundled-node) FORCE_BUNDLED_NODE=true; shift ;;
    --force) FORCE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "unknown arg: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$PAYLOAD" || ! -d "$PAYLOAD/plugin" ]]; then
  echo "install.sh: --payload must be a staged payload directory" >&2
  exit 1
fi
PAYLOAD="$(cd "$PAYLOAD" && pwd)"

if [[ -z "$TARGET_USER" ]]; then
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    TARGET_USER="$SUDO_USER"
  else
    TARGET_USER="$(id -un)"
  fi
fi

if [[ -z "$HOME_DIR" ]]; then
  if declare -F home_for_user >/dev/null; then
    HOME_DIR="$(home_for_user "$TARGET_USER")"
  fi
  if [[ -z "$HOME_DIR" ]]; then
    if [[ "$(id -un)" == "$TARGET_USER" ]]; then
      HOME_DIR="${HOME}"
    else
      echo "install.sh: cannot resolve home for $TARGET_USER" >&2
      exit 1
    fi
  fi
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  OS=darwin
elif [[ "$(uname -s)" == "Linux" ]]; then
  OS=linux
else
  echo "install.sh: unsupported OS $(uname -s)" >&2
  exit 1
fi
case "$(uname -m)" in
  arm64|aarch64) ARCH=arm64 ;;
  x86_64|amd64) ARCH=x64 ;;
  *)
    echo "install.sh: unsupported arch $(uname -m)" >&2
    exit 1
    ;;
esac
TRIPLE="${OS}-${ARCH}"

PLUGIN_SRC="$PAYLOAD/plugin"
DEST="$HOME_DIR/.cursor/plugins/local/yaaif"
YAAIF_HOME="$HOME_DIR/.yaaif/cursor"
MANIFEST_PATH="$YAAIF_HOME/install-manifest.json"
RUNTIME_SRC="$PAYLOAD/runtime/$TRIPLE"
NEXT_STEPS_TPL="$SCRIPT_DIR/next-steps.html"
if [[ ! -f "$NEXT_STEPS_TPL" && -f "$PAYLOAD/lib/next-steps.html" ]]; then
  NEXT_STEPS_TPL="$PAYLOAD/lib/next-steps.html"
fi

if [[ -f "$PAYLOAD/runtime-manifest.json" ]]; then
  MIN_NODE_MAJOR="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("min_system_node_major",20))' "$PAYLOAD/runtime-manifest.json")"
fi

PLUGIN_VERSION="unknown"
if [[ -f "$PLUGIN_SRC/.cursor-plugin/plugin.json" ]]; then
  PLUGIN_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$PLUGIN_SRC/.cursor-plugin/plugin.json")"
fi

PREV_VERSION=""
if [[ -f "$MANIFEST_PATH" ]]; then
  PREV_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("plugin_version",""))' "$MANIFEST_PATH" 2>/dev/null || true)"
fi

plugin_dest_ok() {
  local root="$1"
  [[ -f "$root/.cursor-plugin/plugin.json" && -f "$root/dist/yaaif-cursor-mcp.mjs" && -f "$root/mcp.json" ]] || return 1
  python3 - "$root/mcp.json" <<'PY'
import json, sys
cmd = str(json.load(open(sys.argv[1])).get("mcpServers", {}).get("yaaif", {}).get("command") or "")
sys.exit(0 if cmd and cmd != "node" and (":" in cmd or "\\" in cmd or cmd.startswith("/")) else 1)
PY
}

DEST_OK=false
if plugin_dest_ok "$DEST"; then
  DEST_OK=true
fi

if [[ -n "$PREV_VERSION" && "$FORCE" != true && "$(type -t version_cmp)" == "function" && "$DEST_OK" == true ]]; then
  CMP="$(version_cmp "$PREV_VERSION" "$PLUGIN_VERSION" || echo 0)"
  if [[ "$CMP" == "1" ]]; then
    echo "install.sh: installed $PREV_VERSION is newer than package $PLUGIN_VERSION and dest is verified; skipping copy (pass --force to overwrite)"
    NODE_COMMAND="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("node_command",""))' "$MANIFEST_PATH" 2>/dev/null || true)"
    if [[ -z "$NODE_COMMAND" || "$NODE_COMMAND" == "node" ]]; then
      NODE_COMMAND="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["mcpServers"]["yaaif"]["command"])' "$DEST/mcp.json" 2>/dev/null || true)"
    fi
    NODE_SOURCE="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("node_source",""))' "$MANIFEST_PATH" 2>/dev/null || true)"
    NODE_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("node_version",""))' "$MANIFEST_PATH" 2>/dev/null || true)"
    UNINSTALL_HINT="$YAAIF_HOME/uninstall.sh"
    run_setup() {
      [[ "${YAAIF_INSTALLER_NO_SETUP:-}" == "1" ]] && return 0
      [[ -f "$DEST/dist/yaaif-cursor-mcp.mjs" ]] || return 0
      [[ -n "$NODE_COMMAND" && -x "$NODE_COMMAND" ]] || return 0
      "$NODE_COMMAND" "$DEST/dist/yaaif-cursor-mcp.mjs" --client cursor --setup all \
        || echo "install.sh: setup failed (plugin files are installed)"
    }
    run_setup
    exit 0
  fi
fi
if [[ -n "$PREV_VERSION" && "$DEST_OK" != true ]]; then
  echo "install.sh: manifest claims $PREV_VERSION but dest is missing or incomplete; repairing with package $PLUGIN_VERSION"
fi

system_node_bin=""
system_node_ver=""
if command -v node >/dev/null 2>&1; then
  system_node_ver="$(node -p "process.versions.node" 2>/dev/null || true)"
  major="${system_node_ver%%.*}"
  if [[ -n "$major" && "$major" =~ ^[0-9]+$ && "$major" -ge "$MIN_NODE_MAJOR" ]]; then
    raw="$(command -v node)"
    if declare -F abs_path >/dev/null; then
      system_node_bin="$(abs_path "$raw")"
    else
      system_node_bin="$raw"
    fi
  fi
fi

USE_BUNDLED=false
if [[ "$FORCE_BUNDLED_NODE" == true || -z "$system_node_bin" ]]; then
  USE_BUNDLED=true
fi
if [[ "$USE_BUNDLED" == true && ! -d "$RUNTIME_SRC" ]]; then
  echo "install.sh: system Node.js >= ${MIN_NODE_MAJOR} not found and payload has no runtime/$TRIPLE" >&2
  exit 1
fi

echo "Installing YAAIF Cursor plugin ${PLUGIN_VERSION} → $DEST"
if [[ -n "$PREV_VERSION" ]]; then
  echo "Updating existing install (${PREV_VERSION} → ${PLUGIN_VERSION})"
fi

export COPYFILE_DISABLE=1
mkdir -p "$(dirname "$DEST")" "$YAAIF_HOME"
DEST_PARENT="$(dirname "$DEST")"
STAGING="$DEST_PARENT/yaaif.__staging"
BACKUP="$DEST_PARENT/yaaif.__old"
rm -rf "$STAGING"
mkdir -p "$STAGING"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete --exclude runtime --exclude .git --exclude node_modules \
    --exclude '._*' --exclude '.DS_Store' \
    "$PLUGIN_SRC/" "$STAGING/"
else
  tar -C "$PLUGIN_SRC" --exclude runtime --exclude .git --exclude node_modules -cf - . \
    | tar -C "$STAGING" -xf -
fi
if [[ ! -f "$STAGING/.cursor-plugin/plugin.json" || ! -f "$STAGING/dist/yaaif-cursor-mcp.mjs" ]]; then
  echo "install.sh: staged plugin missing plugin.json or dist/yaaif-cursor-mcp.mjs" >&2
  exit 1
fi
rm -rf "$BACKUP"
SWAPPED=false
for attempt in 1 2 3; do
  if [[ -e "$DEST" ]]; then
    if ! mv "$DEST" "$BACKUP"; then
      echo "install.sh: swap attempt $attempt: could not move dest (locked?)" >&2
      sleep 1
      continue
    fi
  fi
  if mv "$STAGING" "$DEST"; then
    SWAPPED=true
    echo "install.sh: swapped staging into $DEST (attempt $attempt)"
    break
  fi
  echo "install.sh: swap attempt $attempt failed" >&2
  if [[ ! -e "$DEST" && -e "$BACKUP" ]]; then
    mv "$BACKUP" "$DEST" || true
  fi
  sleep 1
done
if [[ "$SWAPPED" != true ]]; then
  echo "install.sh: swap failed after retries; in-place copy (no --delete)" >&2
  if [[ ! -e "$DEST" && -e "$BACKUP" ]]; then
    mv "$BACKUP" "$DEST" || true
  fi
  mkdir -p "$DEST"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude runtime --exclude .git --exclude node_modules \
      --exclude '._*' --exclude '.DS_Store' \
      "$STAGING/" "$DEST/" || echo "install.sh: in-place rsync hit locked files"
  else
    tar -C "$STAGING" --exclude runtime --exclude .git --exclude node_modules -cf - . \
      | tar -C "$DEST" -xf - || echo "install.sh: in-place tar hit locked files"
  fi
fi
if [[ ! -e "$DEST" && -e "$BACKUP" ]]; then
  echo "install.sh: dest missing; restoring yaaif.__old"
  mv "$BACKUP" "$DEST"
fi
if [[ ! -f "$DEST/.cursor-plugin/plugin.json" || ! -f "$DEST/dist/yaaif-cursor-mcp.mjs" ]]; then
  if [[ -e "$BACKUP" ]]; then
    echo "install.sh: verify failed; restoring yaaif.__old" >&2
    rm -rf "$DEST"
    mv "$BACKUP" "$DEST"
  fi
  echo "install.sh: dest missing plugin.json or dist/yaaif-cursor-mcp.mjs" >&2
  exit 1
fi
rm -rf "$STAGING" "$BACKUP"
chmod +x "$DEST/run-mcp.sh" 2>/dev/null || true

NODE_SOURCE="system"
NODE_VERSION="$system_node_ver"
NODE_COMMAND="$system_node_bin"

if [[ "$USE_BUNDLED" == true ]]; then
  echo "Bundling official Node.js from payload/runtime/$TRIPLE"
  rm -rf "$DEST/runtime/node"
  mkdir -p "$DEST/runtime"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$RUNTIME_SRC/" "$DEST/runtime/node/"
  else
    mkdir -p "$DEST/runtime/node"
    tar -C "$RUNTIME_SRC" -cf - . | tar -C "$DEST/runtime/node" -xf -
  fi
  NODE_COMMAND="$DEST/runtime/node/bin/node"
  if [[ ! -x "$NODE_COMMAND" ]]; then
    echo "install.sh: bundled node missing at $NODE_COMMAND" >&2
    exit 1
  fi
  if declare -F abs_path >/dev/null; then
    NODE_COMMAND="$(abs_path "$NODE_COMMAND")"
  fi
  NODE_SOURCE="bundled"
  NODE_VERSION="$("$NODE_COMMAND" -p "process.versions.node" 2>/dev/null || true)"
  if [[ -z "$NODE_VERSION" && -f "$PAYLOAD/runtime-manifest.json" ]]; then
    NODE_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["node_version"])' "$PAYLOAD/runtime-manifest.json")"
  fi
else
  rm -rf "$DEST/runtime"
  echo "Using system Node.js ${NODE_VERSION} (${NODE_COMMAND})"
fi

if [[ -z "$NODE_COMMAND" || "$NODE_COMMAND" == "node" ]]; then
  echo "install.sh: refused to write a non-absolute Node path into mcp.json" >&2
  exit 1
fi

python3 - "$DEST/mcp.json" "$NODE_COMMAND" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
command = sys.argv[2]
data = json.loads(path.read_text())
servers = data.setdefault("mcpServers", {})
yaaif = servers.setdefault("yaaif", {})
yaaif["command"] = command
if not yaaif.get("args"):
    yaaif["args"] = ["${CURSOR_PLUGIN_ROOT}/dist/yaaif-cursor-mcp.mjs", "--client", "cursor"]
path.write_text(json.dumps(data, indent=2) + "\n")
PY

python3 - "$MANIFEST_PATH" "$PLUGIN_VERSION" "$NODE_SOURCE" "$NODE_VERSION" "$DEST" "$TRIPLE" "$NODE_COMMAND" <<'PY'
import json, pathlib, sys
from datetime import datetime, timezone
path = pathlib.Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
payload = {
    "installer": "yaaif-cursor-plugin",
    "plugin_version": sys.argv[2],
    "node_source": sys.argv[3],
    "node_version": sys.argv[4],
    "plugin_path": sys.argv[5],
    "runtime_triple": sys.argv[6],
    "node_command": sys.argv[7],
    "verified": True,
    "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
path.write_text(json.dumps(payload, indent=2) + "\n")
PY

UNINSTALL_HINT="installer/lib/uninstall.sh"
if [[ -f "$SCRIPT_DIR/uninstall.sh" ]]; then
  cp "$SCRIPT_DIR/uninstall.sh" "$YAAIF_HOME/uninstall.sh"
  chmod +x "$YAAIF_HOME/uninstall.sh"
  UNINSTALL_HINT="$YAAIF_HOME/uninstall.sh"
fi
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
  cp "$SCRIPT_DIR/common.sh" "$YAAIF_HOME/common.sh"
fi

run_setup() {
  [[ "${YAAIF_INSTALLER_NO_SETUP:-}" == "1" ]] && return 0
  [[ -f "$DEST/dist/yaaif-cursor-mcp.mjs" ]] || return 0
  [[ -n "$NODE_COMMAND" && -x "$NODE_COMMAND" ]] || return 0
  echo "Running YAAIF setup (profile + optional login)…"
  if [[ "$(id -u)" -eq 0 && "$TARGET_USER" != "root" ]]; then
    sudo -u "$TARGET_USER" env \
      YAAIF_INSTALLER_NO_LOGIN="${YAAIF_INSTALLER_NO_LOGIN:-}" \
      YAAIF_INSTALLER_NO_OPEN="${YAAIF_INSTALLER_NO_OPEN:-}" \
      CI="${CI:-}" \
      "$NODE_COMMAND" "$DEST/dist/yaaif-cursor-mcp.mjs" --client cursor --setup all \
      || echo "install.sh: setup failed (plugin files are installed)"
  else
    "$NODE_COMMAND" "$DEST/dist/yaaif-cursor-mcp.mjs" --client cursor --setup all \
      || echo "install.sh: setup failed (plugin files are installed)"
  fi
}
run_setup

NEXT_OUT="$YAAIF_HOME/NEXT_STEPS.html"
if [[ -f "$NEXT_STEPS_TPL" ]]; then
  python3 - "$NEXT_STEPS_TPL" "$NEXT_OUT" "$PLUGIN_VERSION" "$DEST" "$NODE_SOURCE" "$NODE_VERSION" "$UNINSTALL_HINT" "$YAAIF_HOME" <<'PY'
import json, pathlib, sys
src, dest, ver, path, src_node, node_ver, hint, home = sys.argv[1:9]
profile_id, login_status, login_email, tenant_name = (
    "hosted",
    "Sign in from Cursor with /yaaif-login if the installer did not complete login.",
    "—",
    "—",
)
status_path = pathlib.Path(home) / "setup-status.json"
if status_path.is_file():
    try:
        st = json.loads(status_path.read_text())
        profile_id = str(st.get("profile_id") or profile_id)
        login_email = str(st.get("email") or login_email)
        tenant_name = str(st.get("tenant_name") or st.get("tenant_id") or tenant_name)
        login = str(st.get("login") or "")
        login_status = {
            "ok": "Signed in.",
            "skipped": "Login skipped (silent/CI). Run /yaaif-login in Cursor.",
            "failed": "Login did not finish. Run /yaaif-login in Cursor.",
            "required": "Login required. Run /yaaif-login in Cursor.",
        }.get(login, str(st.get("message") or login_status))
    except Exception:
        pass
text = pathlib.Path(src).read_text()
for k, v in {
    "__PLUGIN_VERSION__": ver,
    "__PLUGIN_PATH__": path,
    "__NODE_SOURCE__": src_node,
    "__NODE_VERSION__": node_ver,
    "__UNINSTALL_HINT__": hint,
    "__PROFILE_ID__": profile_id,
    "__LOGIN_STATUS__": login_status,
    "__LOGIN_EMAIL__": login_email,
    "__TENANT_NAME__": tenant_name,
}.items():
    text = text.replace(k, v)
pathlib.Path(dest).write_text(text)
PY
  cp "$NEXT_OUT" "$DEST/NEXT_STEPS.html"
fi

if [[ "$(id -u)" -eq 0 && "$TARGET_USER" != "root" ]]; then
  GROUP="$(id -gn "$TARGET_USER" 2>/dev/null || true)"
  if [[ -n "$GROUP" ]]; then
    chown -R "$TARGET_USER:$GROUP" "$DEST" "$YAAIF_HOME"
  fi
fi

open_next_steps() {
  [[ -f "$NEXT_OUT" ]] || return 0
  [[ "${YAAIF_INSTALLER_NO_OPEN:-}" == "1" ]] && return 0
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if [[ "$(id -u)" -eq 0 && "$TARGET_USER" != "root" ]]; then
      sudo -u "$TARGET_USER" /usr/bin/open "$NEXT_OUT" >/dev/null 2>&1 || true
    else
      /usr/bin/open "$NEXT_OUT" >/dev/null 2>&1 || true
    fi
  elif [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    if [[ "$(id -u)" -eq 0 && "$TARGET_USER" != "root" ]]; then
      sudo -u "$TARGET_USER" xdg-open "$NEXT_OUT" >/dev/null 2>&1 || true
    else
      xdg-open "$NEXT_OUT" >/dev/null 2>&1 || true
    fi
  fi
}
open_next_steps

cat <<EOF
Installed YAAIF Cursor plugin ${PLUGIN_VERSION}
  path:   $DEST
  node:   ${NODE_SOURCE} ${NODE_VERSION} (${NODE_COMMAND})

Next steps were written to $NEXT_OUT
First install: Cursor → Plugins → + Add → Add local plugin → $DEST
Then Developer: Reload Window and run /yaaif-doctor.
Updates only need Developer: Reload Window.
EOF
