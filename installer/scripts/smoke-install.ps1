# Offline smoke of install.ps1 / uninstall.ps1 against a fake payload (no Node download).
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$installerRoot = Split-Path $PSScriptRoot -Parent

$env:YAAIF_INSTALLER_NO_OPEN = "1"
$env:YAAIF_INSTALLER_NO_LOGIN = "1"
$env:YAAIF_INSTALLER_NO_SETUP = "1"

function Test-Ps51Parse([string]$Path) {
    $ps51 = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    if (-not (Test-Path -LiteralPath $ps51)) {
        throw "Windows PowerShell 5.1 not found at $ps51"
    }
    $probe = @"
`$errs = `$null
`$null = [System.Management.Automation.Language.Parser]::ParseFile('$($Path.Replace("'", "''"))', [ref]`$null, [ref]`$errs)
if (`$errs -and `$errs.Count -gt 0) {
    `$errs | ForEach-Object { Write-Output `$_.ToString() }
    exit 1
}
exit 0
"@
    $p = Start-Process -FilePath $ps51 -ArgumentList @("-NoProfile", "-Command", $probe) -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) {
        throw "PS 5.1 parse failed: $Path"
    }
}

Write-Host "== PS 5.1 parse =="
Test-Ps51Parse (Join-Path $installerRoot "lib\install.ps1")
Test-Ps51Parse (Join-Path $installerRoot "lib\setup.ps1")
Test-Ps51Parse (Join-Path $installerRoot "windows\Install-YaaifPlugin.ps1")
Write-Host "parse-ok"

$tmp = Join-Path $env:TEMP ("yaaif-cursor-install-smoke-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$fakeHome = Join-Path $tmp "home"
$payload = Join-Path $tmp "payload"
New-Item -ItemType Directory -Force -Path @(
    (Join-Path $payload "plugin\.cursor-plugin"),
    (Join-Path $payload "plugin\dist"),
    (Join-Path $payload "lib")
) | Out-Null

Set-Content -LiteralPath (Join-Path $payload "plugin\.cursor-plugin\plugin.json") -Value '{"name":"yaaif","version":"1.1.0"}' -Encoding ascii
Set-Content -LiteralPath (Join-Path $payload "plugin\mcp.json") -Value @'
{
  "mcpServers": {
    "yaaif": {
      "command": "node",
      "args": ["${CURSOR_PLUGIN_ROOT}/dist/yaaif-cursor-mcp.mjs", "--client", "cursor"]
    }
  }
}
'@ -Encoding ascii
Set-Content -LiteralPath (Join-Path $payload "plugin\dist\yaaif-cursor-mcp.mjs") -Value "export default {}" -Encoding ascii
Copy-Item -LiteralPath (Join-Path $installerRoot "lib\next-steps.html") -Destination (Join-Path $payload "lib\next-steps.html")
Copy-Item -LiteralPath (Join-Path $installerRoot "lib\uninstall.ps1") -Destination (Join-Path $payload "lib\uninstall.ps1")

$install = Join-Path $installerRoot "lib\install.ps1"
$uninstall = Join-Path $installerRoot "lib\uninstall.ps1"
$dest = Join-Path $fakeHome ".cursor\plugins\local\yaaif"
$manifest = Join-Path $fakeHome ".yaaif\cursor\install-manifest.json"

try {
    Write-Host "== first install =="
    & $install -PayloadDir $payload -HomeDir $fakeHome -SkipSetup
    if ($LASTEXITCODE -ge 8) { throw "install.ps1 exit $LASTEXITCODE" }
    if (-not (Test-Path -LiteralPath (Join-Path $dest "dist\yaaif-cursor-mcp.mjs"))) { throw "bundle missing" }
    if (-not (Test-Path -LiteralPath $manifest)) { throw "manifest missing" }
    $mcp = Get-Content -LiteralPath (Join-Path $dest "mcp.json") -Raw | ConvertFrom-Json
    $cmd = [string]$mcp.mcpServers.yaaif.command
    if ($cmd -notmatch '[:\\]') { throw "expected absolute node path, got $cmd" }
    $man = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    if (-not $man.verified) { throw "expected verified true" }

    Write-Host "== refuse downgrade when dest is verified =="
    $man.plugin_version = "9.9.9"
    ($man | ConvertTo-Json) | Set-Content -LiteralPath $manifest -Encoding utf8
    & $install -PayloadDir $payload -HomeDir $fakeHome -SkipSetup
    $after = (Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).plugin_version
    if ($after -ne "9.9.9") { throw "downgrade should have been skipped, got $after" }

    Write-Host "== repair when dest is missing even if manifest is newer =="
    Remove-Item -LiteralPath $dest -Recurse -Force
    & $install -PayloadDir $payload -HomeDir $fakeHome -SkipSetup
    if (-not (Test-Path -LiteralPath (Join-Path $dest "dist\yaaif-cursor-mcp.mjs"))) { throw "repair did not restore dest" }
    $repaired = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    if ($repaired.plugin_version -ne "1.1.0") { throw "repair should rewrite manifest, got $($repaired.plugin_version)" }
    if (-not $repaired.verified) { throw "repair expected verified true" }

    Write-Host "== uninstall keeps session =="
    $sessionDir = Join-Path $fakeHome ".yaaif\cursor"
    New-Item -ItemType Directory -Force -Path $sessionDir | Out-Null
    Set-Content -LiteralPath (Join-Path $sessionDir "session.json") -Value '{"tokens":{"access_token":"x"}}' -Encoding ascii
    & $uninstall -HomeDir $fakeHome -UserFilesOnly
    if (Test-Path -LiteralPath $dest) { throw "plugin dir should be gone" }
    if (-not (Test-Path -LiteralPath (Join-Path $sessionDir "session.json"))) { throw "session.json must be kept" }

    Write-Host "smoke-install.ps1: ok"
} finally {
    if (Test-Path -LiteralPath $tmp) {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
