#!/usr/bin/env bash
# Push installer artifacts to GitHub Packages (GHCR) for yaaif/cursor-plugin.
set -euo pipefail

DIST="${1:-}"
VERSION="${2:-}"
IMAGE="${GHCR_IMAGE:-ghcr.io/yaaif/cursor-plugin/installer}"

if [[ -z "$DIST" || -z "$VERSION" ]]; then
  echo "Usage: publish-ghcr.sh <dist-dir> <version>" >&2
  exit 1
fi
DIST="$(cd "$DIST" && pwd)"

shopt -s nullglob
FILES=( "$DIST"/*.pkg "$DIST"/*.dmg "$DIST"/*.msi "$DIST"/*.deb "$DIST"/SHA256SUMS )
if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "no installer artifacts in $DIST" >&2
  exit 1
fi

USER_NAME="$(gh api user --jq .login)"
TOKEN="${GHCR_TOKEN:-${GITHUB_TOKEN:-$(gh auth token)}}"
echo "$TOKEN" | docker login ghcr.io -u "$USER_NAME" --password-stdin

ORAS=(oras)
if ! command -v oras >/dev/null 2>&1; then
  ORAS=(docker run --rm
    -v "$DIST:/workspace"
    -v "$HOME/.docker/config.json:/root/.docker/config.json:ro"
    -w /workspace
    ghcr.io/oras-project/oras:v1.2.2)
  WORK_FILES=()
  for f in "${FILES[@]}"; do
    WORK_FILES+=("$(basename "$f")")
  done
else
  WORK_FILES=("${FILES[@]}")
fi

ANNOTATIONS=(
  --annotation "org.opencontainers.image.source=https://github.com/yaaif/cursor-plugin"
  --annotation "org.opencontainers.image.description=YAAIF Cursor plugin native installers"
  --annotation "org.opencontainers.image.version=${VERSION}"
)

echo "Pushing ${#WORK_FILES[@]} files to ${IMAGE}:${VERSION}"
"${ORAS[@]}" push "${IMAGE}:${VERSION}" "${ANNOTATIONS[@]}" "${WORK_FILES[@]}"

echo "Published ${IMAGE}:${VERSION}"
echo "Package: https://github.com/orgs/yaaif/packages/container/package/cursor-plugin%2Finstaller"
