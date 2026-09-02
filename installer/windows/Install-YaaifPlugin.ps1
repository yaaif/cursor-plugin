# Called from the per-user MSI after files are laid down.
[CmdletBinding()]
param(
    [string]$SetupDir = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$payload = Join-Path $SetupDir "payload"
$zip = Join-Path $SetupDir "payload.zip"
if (-not (Test-Path -LiteralPath (Join-Path $payload "plugin"))) {
    if (-not (Test-Path -LiteralPath $zip)) {
        throw "Install-YaaifPlugin.ps1: missing payload at $payload and $zip"
    }
    if (Test-Path -LiteralPath $payload) {
        Remove-Item -LiteralPath $payload -Recurse -Force
    }
    Expand-Archive -LiteralPath $zip -DestinationPath $payload -Force
}

$install = Join-Path $payload "lib\install.ps1"
if (-not (Test-Path -LiteralPath $install)) {
    $install = Join-Path $SetupDir "install.ps1"
}
if (-not (Test-Path -LiteralPath $install)) {
    throw "Install-YaaifPlugin.ps1: install.ps1 not found"
}

& $install -PayloadDir $payload -HomeDir $env:USERPROFILE
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    throw "install.ps1 failed with exit code $LASTEXITCODE"
}
