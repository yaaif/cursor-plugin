#!/bin/bash
# No-admin install from the DMG: copies into ~/.cursor/plugins/local/yaaif as the current user.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$DIR/payload"
if [[ ! -d "$PAYLOAD/plugin" ]]; then
  osascript -e 'display alert "YAAIF Cursor Plugin" message "payload/ is missing next to this installer. Use the .pkg instead, or re-download the DMG."' || true
  exit 1
fi
export YAAIF_INSTALLER_NO_OPEN="${YAAIF_INSTALLER_NO_OPEN:-0}"
exec "$PAYLOAD/lib/install.sh" --payload "$PAYLOAD" --home "$HOME" --user "$(id -un)"
