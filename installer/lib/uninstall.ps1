# Remove the local Cursor plugin copy and optional setup payload. Never deletes session/profiles.
[CmdletBinding()]
param(
    [string]$HomeDir = $env:USERPROFILE,
    [switch]$UserFilesOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dest = Join-Path $HomeDir ".cursor\plugins\local\yaaif"
$yaaifHome = Join-Path $HomeDir ".yaaif\cursor"

Write-Host "Removing $dest"
if (Test-Path -LiteralPath $dest) {
    Remove-Item -LiteralPath $dest -Recurse -Force
}
foreach ($name in @("install-manifest.json", "NEXT_STEPS.html", "uninstall.ps1")) {
    $p = Join-Path $yaaifHome $name
    if (Test-Path -LiteralPath $p) {
        Remove-Item -LiteralPath $p -Force
    }
}

if (-not $UserFilesOnly) {
    $setup = Join-Path $env:LOCALAPPDATA "yaaif\cursor-plugin-setup"
    if (Test-Path -LiteralPath $setup) {
        Remove-Item -LiteralPath $setup -Recurse -Force
        Write-Host "Removed $setup"
    }
}

Write-Host "Uninstalled YAAIF Cursor plugin files."
Write-Host "Kept $yaaifHome (session/profiles/CA) if present."
