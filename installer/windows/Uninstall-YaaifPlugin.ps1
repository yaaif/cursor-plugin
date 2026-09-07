# Called from the MSI on remove. Deletes the user plugin copy only.
[CmdletBinding()]
param(
    [string]$HomeDir = $env:USERPROFILE
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$here = $PSScriptRoot
$candidate = @(
    (Join-Path $here "uninstall.ps1"),
    (Join-Path $here "payload\lib\uninstall.ps1")
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $candidate) {
    $fallback = Join-Path $HomeDir ".yaaif\cursor\uninstall.ps1"
    if (Test-Path -LiteralPath $fallback) {
        $candidate = $fallback
    }
}

if ($candidate) {
    & $candidate -HomeDir $HomeDir -UserFilesOnly
} else {
    $dest = Join-Path $HomeDir ".cursor\plugins\local\yaaif"
    if (Test-Path -LiteralPath $dest) {
        Remove-Item -LiteralPath $dest -Recurse -Force
    }
    $manifest = Join-Path $HomeDir ".yaaif\cursor\install-manifest.json"
    if (Test-Path -LiteralPath $manifest) {
        Remove-Item -LiteralPath $manifest -Force
    }
}

$global:LASTEXITCODE = 0
exit 0
