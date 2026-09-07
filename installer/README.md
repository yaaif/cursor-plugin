# YAA\\F Cursor plugin installer

Native packages that **install or update** the local Cursor plugin at
`~/.cursor/plugins/local/yaaif` (Windows: `%USERPROFILE%\.cursor\plugins\local\yaaif`).

The same package is used for first install and for updates. `~/.yaaif/cursor/`
session, profiles, and CA files are never deleted.

## What customers download

GitHub Releases on [yaaif/cursor-plugin](https://github.com/yaaif/cursor-plugin/releases)
(each release includes `SHA256SUMS`):

| OS | File |
|----|------|
| macOS Apple Silicon | `yaaif-cursor-plugin-<ver>-macos-arm64.pkg` (also `.dmg`) |
| macOS Intel | `yaaif-cursor-plugin-<ver>-macos-x64.pkg` |
| Windows x64 | `yaaif-cursor-plugin-<ver>-win-x64.msi` |
| Ubuntu/Debian amd64 | `yaaif-cursor-plugin-<ver>-linux-amd64.deb` |
| Ubuntu/Debian arm64 | `yaaif-cursor-plugin-<ver>-linux-arm64.deb` |

Unsigned macOS builds: right-click the `.pkg` → **Open** if Gatekeeper warns.

### After the package runs

The installer copies the plugin, writes an **absolute Node path** into `mcp.json`,
detects the default YAAIF server (`hosted` / `local-hybrid` / `local`), and saves
`~/.yaaif/cursor/active-profile.json`. An interactive install then opens a browser
for PKCE login and records email + tenant in `setup-status.json`.

It also writes `~/.yaaif/cursor/NEXT_STEPS.html` and opens it when a desktop
session is available.

1. **First install only:** Cursor → **Plugins → + Add → Add local plugin** → `~/.cursor/plugins/local/yaaif`
   (Cursor has no API to register a local plugin automatically.)
2. **Developer: Reload Window**
3. Run `/yaaif-doctor`

Updates and repair: re-run the same or newer package, then reload. An existing
active profile and session are kept.

- If the plugin folder is missing or incomplete, the installer **repairs** it
  even when `install-manifest.json` claims a newer version.
- Downgrades of a **healthy** dest are refused unless `--force` / `-Force`.
- A successful install means files are on disk. Browser login is optional and
  never fails the MSI. If login did not run, use `/yaaif-login` in Cursor.
- If the log says files are locked, close Cursor (or Developer: Reload Window)
  and re-run the installer. Log: `%TEMP%\yaaif-cursor-plugin-install.log`.

### Silent / CI

| Variable | Effect |
|----------|--------|
| `YAAIF_INSTALLER_NO_OPEN=1` | Do not open NEXT_STEPS.html or a visible login window |
| `YAAIF_INSTALLER_NO_LOGIN=1` | Detect + write profile only; skip browser login |
| `YAAIF_INSTALLER_NO_SETUP=1` | Skip profile detection and login entirely |

`msiexec /qn` (and `/quiet` / `/passive`) is treated as silent: no browser, no
pause. Install logs: `%TEMP%\yaaif-cursor-plugin-install.log`.

```powershell
$env:YAAIF_INSTALLER_NO_OPEN = "1"
$env:YAAIF_INSTALLER_NO_LOGIN = "1"
msiexec /i yaaif-cursor-plugin-<ver>-win-x64.msi /qn
```

The same `--setup` CLI is available after install:

```text
node dist/yaaif-cursor-mcp.mjs --client cursor --setup detect|profile|login|whoami|all
```

### macOS without an admin password

The `.dmg` also contains **Install YAAIF Cursor Plugin.command** plus a `payload/`
folder. Double-click the `.command` to copy into your home directory as the
current user (no `/Library` write).

### Uninstall

Keeps `~/.yaaif/cursor/session.json`, `profiles.json`, `active-profile.json`, and CA files.

```bash
# Unix (user files; add sudo to also remove /Library or /opt payload)
~/.yaaif/cursor/uninstall.sh --user-files-only
sudo /Library/Application\ Support/yaaif/cursor-plugin/lib/uninstall.sh   # macOS pkg
sudo /opt/yaaif/cursor-plugin/lib/uninstall.sh                             # Linux .deb
```

```powershell
& "$env:USERPROFILE\.yaaif\cursor\uninstall.ps1"
# or uninstall the MSI from Apps & features
```

`dpkg -r yaaif-cursor-plugin` and MSI remove also delete the user plugin copy.

## Node.js / npm

The MCP bridge needs **Node.js ≥ 20**. Packages ship official Node.js 22 LTS
from `nodejs.org` (checksums in [`runtime-manifest.json`](runtime-manifest.json)).

At install time:

- If `node` on `PATH` is ≥ 20, that binary is **resolved to an absolute path**
  and written into the installed `mcp.json` (Cursor’s PATH often has no `node`).
- Otherwise official Node 22 (includes npm) is copied to
  `~/.cursor/plugins/local/yaaif/runtime/node/` and `mcp.json` points at it.

The installer does **not** install Homebrew/apt/Chocolatey Node.

## Signing (release machines)

Same env vars as the desktop app (`desktop-app/docs/installer-signing.md`):

| Variable | Effect |
|----------|--------|
| `APPLE_SIGNING_IDENTITY` | `productsign` the `.pkg`, `codesign` the `.dmg` |
| `APPLE_ID` + `APPLE_TEAM_ID` + `APPLE_PASSWORD` | `notarytool submit --wait` + `stapler staple` |
| `APPLE_API_KEY` + `APPLE_API_ISSUER` + `APPLE_API_KEY_PATH` | Notarize via App Store Connect API key |
| `WINDOWS_CERTIFICATE_THUMBPRINT` | `signtool` the `.msi` when `signtool` is on `PATH` |

Builds succeed unsigned when these are unset.

## Build (developers)

From the plugin repo root:

```bash
./installer/scripts/stage-payload.sh --os darwin --arch arm64
YAAIF_INSTALLER_NO_OPEN=1 ./installer/scripts/smoke-install.sh
pwsh ./installer/scripts/smoke-install.ps1
./installer/macos/build-pkg.sh --arch arm64
./installer/linux/build-deb.sh --arch amd64
pwsh ./installer/windows/build-msi.ps1 -Arch x64
```

Outputs land in `installer/out/dist/` including `SHA256SUMS`.
Downloads are cached in `installer/.cache/`.

Set `YAAIF_INSTALLER_NO_OPEN=1` and `YAAIF_INSTALLER_NO_LOGIN=1` in CI so
next-steps HTML is not opened and browser login is skipped (profile is still written).
