# Build a per-user MSI that installs/updates the YAAIF Cursor plugin.
[CmdletBinding()]
param(
    [ValidateSet("x64", "arm64")]
    [string]$Arch = "x64",
    [switch]$SkipStage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$windowsDir = $PSScriptRoot
$installerRoot = Split-Path $windowsDir -Parent
$pluginRoot = Split-Path $installerRoot -Parent
$wix = Join-Path $windowsDir "yaaif-cursor-plugin.wxs"

$pluginJson = Get-Content -LiteralPath (Join-Path $pluginRoot ".cursor-plugin\plugin.json") -Raw | ConvertFrom-Json
$version = $pluginJson.version
$triple = "win-$Arch"
$payload = Join-Path $installerRoot "out\payload\$triple"
$dist = Join-Path $installerRoot "out\dist"
$work = Join-Path $installerRoot "out\windows\$triple"
New-Item -ItemType Directory -Force -Path $dist, $work | Out-Null

if (-not $SkipStage) {
    $stage = Join-Path $installerRoot "scripts\stage-payload.sh"
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if (-not $bash) {
        throw "build-msi.ps1: bash is required to stage the payload (Git Bash on PATH)"
    }
    # Forward slashes; stage-payload.sh runs cygpath on Windows.
    $stageUnix = ($stage -replace '\\', '/')
    $payloadUnix = ($payload -replace '\\', '/')
    & bash $stageUnix --os win --arch $Arch --out $payloadUnix
    if ($LASTEXITCODE -ne 0) {
        throw "stage-payload.sh failed"
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $payload "plugin"))) {
    throw "missing staged payload at $payload"
}

$payloadZip = Join-Path $work "payload.zip"
if (Test-Path -LiteralPath $payloadZip) {
    Remove-Item -LiteralPath $payloadZip -Force
}
if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
    # Compress-Archive cannot zip a directory's *contents* cleanly on all hosts;
    # zip the payload folder, then install.ps1 still finds plugin/ at payload/plugin
    # after Expand-Archive if we zip the folder itself. Stage a wrapper.
    $zipRoot = Join-Path $work "ziproot"
    if (Test-Path -LiteralPath $zipRoot) {
        Remove-Item -LiteralPath $zipRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $zipRoot | Out-Null
    Copy-Item -Path (Join-Path $payload "*") -Destination $zipRoot -Recurse -Force
    Compress-Archive -Path (Join-Path $zipRoot "*") -DestinationPath $payloadZip -Force
} else {
    throw "Compress-Archive is required"
}

$wixCmd = Get-Command wix -ErrorAction SilentlyContinue
if (-not $wixCmd) {
    Write-Host "WiX CLI not on PATH — installing WixToolset.Sdk / wix as a local dotnet tool"
    $toolManifest = Join-Path $work "dotnet-tools.json"
    if (-not (Test-Path -LiteralPath (Join-Path $work ".config\dotnet-tools.json"))) {
        Push-Location $work
        try {
            dotnet new tool-manifest --force | Out-Null
            dotnet tool install wix --version 5.0.2
        } finally {
            Pop-Location
        }
    }
    Push-Location $work
    try {
        dotnet tool restore | Out-Null
    } finally {
        Pop-Location
    }
    $wixExe = "dotnet"
    $wixPrefix = @("tool", "run", "wix", "--")
} else {
    $wixExe = $wixCmd.Source
    $wixPrefix = @()
}

$outMsi = Join-Path $dist "yaaif-cursor-plugin-$version-win-$Arch.msi"
$wixArgs = $wixPrefix + @(
    "build", $wix,
    "-arch", $(if ($Arch -eq "arm64") { "arm64" } else { "x64" }),
    "-d", "ProductVersion=$version",
    "-d", "PayloadZip=$payloadZip",
    "-d", "InstallPs1=$(Join-Path $installerRoot 'lib\install.ps1')",
    "-d", "BootstrapPs1=$(Join-Path $windowsDir 'Install-YaaifPlugin.ps1')",
    "-d", "UninstallPs1=$(Join-Path $installerRoot 'lib\uninstall.ps1')",
    "-d", "UninstallBootstrapPs1=$(Join-Path $windowsDir 'Uninstall-YaaifPlugin.ps1')",
    "-o", $outMsi
)

Push-Location $work
try {
    & $wixExe @wixArgs
    if ($LASTEXITCODE -ne 0) {
        throw "wix build failed"
    }
} finally {
    Pop-Location
}

if ($env:WINDOWS_CERTIFICATE_THUMBPRINT) {
    $signtool = Get-Command signtool -ErrorAction SilentlyContinue
    if ($signtool) {
        Write-Host "Signing MSI with WINDOWS_CERTIFICATE_THUMBPRINT"
        & signtool sign /tr "http://timestamp.digicert.com" /td sha256 /fd sha256 /sha1 $env:WINDOWS_CERTIFICATE_THUMBPRINT $outMsi
        if ($LASTEXITCODE -ne 0) {
            throw "signtool failed"
        }
    } else {
        Write-Host "signtool not on PATH — MSI unsigned"
    }
} elseif ($env:WINDOWS_CERTIFICATE) {
    Write-Host "WINDOWS_CERTIFICATE is set but this script uses WINDOWS_CERTIFICATE_THUMBPRINT + signtool"
} else {
    Write-Host "WINDOWS_CERTIFICATE_THUMBPRINT unset — MSI unsigned"
}

Write-Host "Wrote $outMsi"
Get-ChildItem -LiteralPath $dist -File | Where-Object { $_.Name -ne "SHA256SUMS" } |
    Sort-Object Name |
    ForEach-Object { (Get-FileHash -Algorithm SHA256 $_.FullName).Hash.ToLower() + "  " + $_.Name } |
    Set-Content -LiteralPath (Join-Path $dist "SHA256SUMS") -Encoding ascii
