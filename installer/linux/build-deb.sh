#!/usr/bin/env bash
# Build a .deb that installs/updates the YAAIF Cursor plugin for the sudo user.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_ROOT="$(cd "$INSTALLER_ROOT/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$INSTALLER_ROOT/lib/common.sh"

ARCH=""
SKIP_STAGE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch) ARCH="$2"; shift 2 ;;
    --skip-stage) SKIP_STAGE=true; shift ;;
    -h|--help)
      echo "Usage: build-deb.sh [--arch amd64|arm64|x64] [--skip-stage]"
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ARCH" ]]; then
  case "$(host_arch)" in
    arm64) ARCH=arm64 ;;
    x64) ARCH=amd64 ;;
  esac
fi
case "$ARCH" in
  amd64|x64)
    DEB_ARCH=amd64
    NODE_ARCH=x64
    ;;
  arm64)
    DEB_ARCH=arm64
    NODE_ARCH=arm64
    ;;
  *)
    echo "unsupported --arch: $ARCH" >&2
    exit 1
    ;;
esac

VERSION="$(plugin_version "$PLUGIN_ROOT")"
TRIPLE="linux-${NODE_ARCH}"
PAYLOAD="$INSTALLER_ROOT/out/payload/${TRIPLE}"
WORK="$INSTALLER_ROOT/out/linux/${TRIPLE}"
ROOT="$WORK/root"
OUT_DIR="$INSTALLER_ROOT/out/dist"
OUT_DEB="$OUT_DIR/yaaif-cursor-plugin-${VERSION}-linux-${DEB_ARCH}.deb"

if [[ "$SKIP_STAGE" != true ]]; then
  "$INSTALLER_ROOT/scripts/stage-payload.sh" --os linux --arch "$NODE_ARCH" --out "$PAYLOAD"
fi
if [[ ! -d "$PAYLOAD/plugin" ]]; then
  echo "missing staged payload at $PAYLOAD" >&2
  exit 1
fi

export COPYFILE_DISABLE=1
rm -rf "$WORK"
mkdir -p "$ROOT/opt/yaaif/cursor-plugin" "$ROOT/DEBIAN" "$OUT_DIR"
rsync -a --exclude '._*' --exclude '.DS_Store' \
  "$PAYLOAD/" "$ROOT/opt/yaaif/cursor-plugin/"
chmod 755 "$ROOT/opt/yaaif/cursor-plugin/lib/install.sh"

cp "$SCRIPT_DIR/debian/postinst" "$ROOT/DEBIAN/postinst"
cp "$SCRIPT_DIR/debian/prerm" "$ROOT/DEBIAN/prerm"
chmod 755 "$ROOT/DEBIAN/postinst" "$ROOT/DEBIAN/prerm"

NODE_VER="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["node_version"])' "$INSTALLER_ROOT/runtime-manifest.json")"
INSTALLED_SIZE="$(du -sk "$ROOT/opt" | awk '{print $1}')"

cat > "$ROOT/DEBIAN/control" <<EOF
Package: yaaif-cursor-plugin
Version: ${VERSION}
Section: devel
Priority: optional
Architecture: ${DEB_ARCH}
Maintainer: YAAIF / BeezLabs <support@yaaif.com>
Installed-Size: ${INSTALLED_SIZE}
Depends: libc6
Homepage: https://github.com/yaaif/cursor-plugin
Description: YAAIF plugin for Cursor (local install/update)
 Copies the YAAIF Cursor plugin into ~/.cursor/plugins/local/yaaif.
 Reuses system Node.js 20+ when present; otherwise installs official
 Node.js ${NODE_VER} next to the plugin. Login state in ~/.yaaif/cursor
 is preserved on update.
EOF

if command -v dpkg-deb >/dev/null 2>&1; then
  dpkg-deb --root-owner-group --build "$ROOT" "$OUT_DEB"
else
  echo "dpkg-deb not found — writing a tar.gz fallback at ${OUT_DEB%.deb}.tar.gz" >&2
  tar -C "$ROOT" -czf "${OUT_DEB%.deb}.tar.gz" .
  echo "Wrote ${OUT_DEB%.deb}.tar.gz"
  write_dist_checksums "$OUT_DIR"
  exit 0
fi

echo "Wrote $OUT_DEB"
write_dist_checksums "$OUT_DIR"
