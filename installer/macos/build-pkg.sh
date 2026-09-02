#!/usr/bin/env bash
# Build a macOS .pkg (and .dmg) that installs/updates the YAAIF Cursor plugin.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_ROOT="$(cd "$INSTALLER_ROOT/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$INSTALLER_ROOT/lib/common.sh"

ARCH=""
SKIP_STAGE=false
SKIP_DMG=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch) ARCH="$2"; shift 2 ;;
    --skip-stage) SKIP_STAGE=true; shift ;;
    --skip-dmg) SKIP_DMG=true; shift ;;
    -h|--help)
      echo "Usage: build-pkg.sh [--arch arm64|x64] [--skip-stage] [--skip-dmg]"
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ARCH" ]]; then
  ARCH="$(host_arch)"
fi
OS=darwin
TRIPLE="${OS}-${ARCH}"
VERSION="$(plugin_version "$PLUGIN_ROOT")"
IDENTIFIER="com.yaaif.cursor-plugin"
PAYLOAD="$INSTALLER_ROOT/out/payload/${TRIPLE}"
WORK="$INSTALLER_ROOT/out/macos/${TRIPLE}"
PKGROOT="$WORK/pkgroot"
SCRIPTS="$WORK/scripts"
DIST_XML="$WORK/distribution.xml"
COMPONENT_PKG="$WORK/yaaif-cursor-plugin-component.pkg"
OUT_DIR="$INSTALLER_ROOT/out/dist"
OUT_PKG="$OUT_DIR/yaaif-cursor-plugin-${VERSION}-macos-${ARCH}.pkg"
OUT_DMG="$OUT_DIR/yaaif-cursor-plugin-${VERSION}-macos-${ARCH}.dmg"

if [[ "$SKIP_STAGE" != true ]]; then
  "$INSTALLER_ROOT/scripts/stage-payload.sh" --os darwin --arch "$ARCH" --out "$PAYLOAD"
fi
if [[ ! -d "$PAYLOAD/plugin" ]]; then
  echo "missing staged payload at $PAYLOAD" >&2
  exit 1
fi

export COPYFILE_DISABLE=1
rm -rf "$WORK"
mkdir -p "$PKGROOT/Library/Application Support/yaaif/cursor-plugin" \
  "$SCRIPTS" "$OUT_DIR"

rsync -a --exclude '._*' --exclude '.DS_Store' \
  "$PAYLOAD/" "$PKGROOT/Library/Application Support/yaaif/cursor-plugin/"
cp "$SCRIPT_DIR/scripts/postinstall" "$SCRIPTS/postinstall"
chmod 755 "$SCRIPTS/postinstall"

pkgbuild \
  --root "$PKGROOT" \
  --identifier "$IDENTIFIER" \
  --version "$VERSION" \
  --install-location / \
  --scripts "$SCRIPTS" \
  "$COMPONENT_PKG"

HOST_ARCH="arm64"
if [[ "$ARCH" == "x64" ]]; then
  HOST_ARCH="x86_64"
fi

cat > "$DIST_XML" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>YAA\\F Cursor Plugin ${VERSION}</title>
    <organization>com.yaaif</organization>
    <options customize="never" require-scripts="true" hostArchitectures="${HOST_ARCH}"/>
    <welcome file="welcome.txt" mime-type="text/plain"/>
    <conclusion file="conclusion.txt" mime-type="text/plain"/>
    <pkg-ref id="${IDENTIFIER}"/>
    <choices-outline>
        <line choice="default">
            <line choice="${IDENTIFIER}"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="${IDENTIFIER}" visible="false">
        <pkg-ref id="${IDENTIFIER}"/>
    </choice>
    <pkg-ref id="${IDENTIFIER}" version="${VERSION}" onConclusion="none">yaaif-cursor-plugin-component.pkg</pkg-ref>
</installer-gui-script>
EOF

RESOURCES="$WORK/resources"
mkdir -p "$RESOURCES"
NODE_VER="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["node_version"])' "$INSTALLER_ROOT/runtime-manifest.json")"
cat > "$RESOURCES/welcome.txt" <<EOF
This installer copies the YAA\\F Cursor plugin into:

  ~/.cursor/plugins/local/yaaif

If Node.js 20+ is already on your PATH, it is reused. Otherwise the official
Node.js ${NODE_VER} runtime bundled in this package is installed next to the plugin.

Profiles and login state in ~/.yaaif/cursor/ are kept on update.
EOF
cat > "$RESOURCES/conclusion.txt" <<EOF
The plugin files are installed.

First time: open Cursor → Plugins → + Add → Add local plugin and choose
~/.cursor/plugins/local/yaaif. Then Developer: Reload Window and run /yaaif-doctor.

Updating: re-run this installer, then Developer: Reload Window.
EOF

UNSIGNED_PKG="$WORK/yaaif-cursor-plugin-unsigned.pkg"
productbuild \
  --distribution "$DIST_XML" \
  --package-path "$WORK" \
  --resources "$RESOURCES" \
  "$UNSIGNED_PKG"

# shellcheck source=sign-and-notarize.sh
source "$SCRIPT_DIR/sign-and-notarize.sh"
sign_pkg "$UNSIGNED_PKG" "$OUT_PKG"
notarize "$OUT_PKG"
echo "Wrote $OUT_PKG"

if [[ "$SKIP_DMG" != true ]]; then
  DMG_ROOT="$WORK/dmg"
  rm -rf "$DMG_ROOT"
  mkdir -p "$DMG_ROOT"
  cp "$OUT_PKG" "$DMG_ROOT/"
  cp "$PLUGIN_ROOT/LICENSE" "$DMG_ROOT/LICENSE.txt"
  cp "$SCRIPT_DIR/Install YAAIF Cursor Plugin.command" "$DMG_ROOT/Install YAAIF Cursor Plugin.command"
  chmod +x "$DMG_ROOT/Install YAAIF Cursor Plugin.command"
  rsync -a --exclude '._*' --exclude '.DS_Store' "$PAYLOAD/" "$DMG_ROOT/payload/"
  cat > "$DMG_ROOT/README.txt" <<EOF
YAA\\F Cursor Plugin ${VERSION}

No admin password: double-click "Install YAAIF Cursor Plugin.command"
(uses the payload/ folder on this disk image).

IT / Apple Installer: double-click the .pkg (writes a copy under
/Library/Application Support/yaaif/cursor-plugin, then your home).

Unsigned builds: right-click → Open if Gatekeeper blocks it.
EOF
  rm -f "$OUT_DMG"
  hdiutil create -volname "YAAIF Cursor Plugin" -srcfolder "$DMG_ROOT" -ov -format UDZO "$OUT_DMG" >/dev/null
  sign_dmg "$OUT_DMG"
  notarize "$OUT_DMG"
  echo "Wrote $OUT_DMG"
fi

write_dist_checksums "$OUT_DIR"
