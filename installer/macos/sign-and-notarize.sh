#!/usr/bin/env bash
# Sign and optionally notarize a macOS pkg/dmg. No-op when secrets are unset.
set -euo pipefail

sign_pkg() {
  local src="$1"
  local dest="$2"
  if [[ -z "${APPLE_SIGNING_IDENTITY:-}" ]]; then
    echo "APPLE_SIGNING_IDENTITY unset — leaving $dest unsigned"
    cp "$src" "$dest"
    return 0
  fi
  echo "Signing pkg with APPLE_SIGNING_IDENTITY"
  productsign --sign "$APPLE_SIGNING_IDENTITY" "$src" "$dest"
}

sign_dmg() {
  local dmg="$1"
  if [[ -z "${APPLE_SIGNING_IDENTITY:-}" ]]; then
    echo "APPLE_SIGNING_IDENTITY unset — DMG unsigned"
    return 0
  fi
  codesign --force --sign "$APPLE_SIGNING_IDENTITY" "$dmg"
}

notarize() {
  local file="$1"
  if [[ -n "${APPLE_API_KEY:-}" && -n "${APPLE_API_ISSUER:-}" && -n "${APPLE_API_KEY_PATH:-}" ]]; then
    echo "Notarizing $(basename "$file") with API key"
    xcrun notarytool submit "$file" \
      --key "$APPLE_API_KEY_PATH" \
      --key-id "$APPLE_API_KEY" \
      --issuer "$APPLE_API_ISSUER" \
      --wait
    xcrun stapler staple "$file"
    return 0
  fi
  if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_PASSWORD:-}" ]]; then
    echo "Notarizing $(basename "$file") with Apple ID"
    xcrun notarytool submit "$file" \
      --apple-id "$APPLE_ID" \
      --team-id "$APPLE_TEAM_ID" \
      --password "$APPLE_PASSWORD" \
      --wait
    xcrun stapler staple "$file"
    return 0
  fi
  echo "Notarization skipped (set APPLE_ID/APPLE_TEAM_ID/APPLE_PASSWORD or API key trio)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "source this file from build-pkg.sh (sign_pkg / sign_dmg / notarize)" >&2
  exit 1
fi
