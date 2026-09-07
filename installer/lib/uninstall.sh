#!/usr/bin/env bash
# Remove the local Cursor plugin copy and package payload. Never deletes session/profiles.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
  # shellcheck source=common.sh
  source "$SCRIPT_DIR/common.sh"
fi

HOME_DIR=""
TARGET_USER=""
USER_FILES_ONLY=false

usage() {
  cat <<'EOF'
Usage: uninstall.sh [--home DIR] [--user NAME] [--user-files-only]

Removes:
  ~/.cursor/plugins/local/yaaif
  ~/.yaaif/cursor/install-manifest.json
  ~/.yaaif/cursor/NEXT_STEPS.html
  /Library/Application Support/yaaif/cursor-plugin   (macOS, unless --user-files-only)
  /opt/yaaif/cursor-plugin                           (Linux, unless --user-files-only)

Keeps ~/.yaaif/cursor/session.json, profiles.json, active-profile.json, CA files.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home) HOME_DIR="$2"; shift 2 ;;
    --user) TARGET_USER="$2"; shift 2 ;;
    --user-files-only) USER_FILES_ONLY=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "unknown arg: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

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
    HOME_DIR="${HOME}"
  fi
fi

DEST="$HOME_DIR/.cursor/plugins/local/yaaif"
YAAIF_HOME="$HOME_DIR/.yaaif/cursor"

echo "Removing $DEST"
rm -rf "$DEST" "$(dirname "$DEST")/yaaif.__staging" "$(dirname "$DEST")/yaaif.__old"
rm -f "$YAAIF_HOME/install-manifest.json" "$YAAIF_HOME/NEXT_STEPS.html" "$YAAIF_HOME/uninstall.sh" "$YAAIF_HOME/setup-status.json"

if [[ "$USER_FILES_ONLY" != true ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    PAYLOAD="/Library/Application Support/yaaif/cursor-plugin"
    if [[ -d "$PAYLOAD" ]]; then
      if [[ "$(id -u)" -eq 0 ]]; then
        rm -rf "$PAYLOAD"
        rmdir "/Library/Application Support/yaaif" 2>/dev/null || true
        pkgutil --forget com.yaaif.cursor-plugin >/dev/null 2>&1 || true
        echo "Removed $PAYLOAD"
      else
        echo "Payload $PAYLOAD needs sudo to delete. Re-run: sudo $0 --user $TARGET_USER"
      fi
    fi
  elif [[ "$(uname -s)" == "Linux" ]]; then
    if [[ -d /opt/yaaif/cursor-plugin ]]; then
      if [[ "$(id -u)" -eq 0 ]]; then
        rm -rf /opt/yaaif/cursor-plugin
        rmdir /opt/yaaif 2>/dev/null || true
        echo "Removed /opt/yaaif/cursor-plugin"
      else
        echo "Payload /opt/yaaif/cursor-plugin needs sudo to delete."
      fi
    fi
  fi
fi

echo "Uninstalled YAAIF Cursor plugin files."
echo "Kept $YAAIF_HOME (session/profiles/CA) if present."
