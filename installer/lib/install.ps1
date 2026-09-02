# Install or update the YAAIF Cursor plugin into %USERPROFILE%\.cursor\plugins\local\yaaif.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PayloadDir,
    [string]$HomeDir = $env:USERPROFILE,
    [switch]$ForceBundledNode,
    [switch]$Force,
    [int]$MinNodeMajor = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Compare-DottedVersion([string]$A, [string]$B) {
    $pa = @($A -split '[.-]' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ })
    $pb = @($B -split '[.-]' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ })
    $n = [Math]::Max($pa.Count, $pb.Count)
    while ($pa.Count -lt $n) { $pa += 0 }
    while ($pb.Count -lt $n) { $pb += 0 }
    for ($i = 0; $i -lt $n; $i++) {
        if ($pa[$i] -lt $pb[$i]) { return -1 }
        if ($pa[$i] -gt $pb[$i]) { return 1 }
    }
    return 0
}

if (-not (Test-Path -LiteralPath (Join-Path $PayloadDir "plugin"))) {
    throw "install.ps1: -PayloadDir must be a staged payload directory"
}

$PayloadDir = (Resolve-Path -LiteralPath $PayloadDir).Path
$pluginSrc = Join-Path $PayloadDir "plugin"
$dest = Join-Path $HomeDir ".cursor\plugins\local\yaaif"
$yaaifHome = Join-Path $HomeDir ".yaaif\cursor"
$manifestPath = Join-Path $yaaifHome "install-manifest.json"

$arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
$triple = "win-$arch"
$runtimeSrc = Join-Path $PayloadDir "runtime\$triple"

$runtimeManifest = Join-Path $PayloadDir "runtime-manifest.json"
if (Test-Path -LiteralPath $runtimeManifest) {
    $rm = Get-Content -LiteralPath $runtimeManifest -Raw | ConvertFrom-Json
    if ($rm.min_system_node_major) {
        $MinNodeMajor = [int]$rm.min_system_node_major
    }
}

$pluginVersion = "unknown"
$pluginJson = Join-Path $pluginSrc ".cursor-plugin\plugin.json"
if (Test-Path -LiteralPath $pluginJson) {
    $pluginVersion = (Get-Content -LiteralPath $pluginJson -Raw | ConvertFrom-Json).version
}

$prevVersion = ""
if (Test-Path -LiteralPath $manifestPath) {
    try {
        $prevVersion = (Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json).plugin_version
    } catch {
        $prevVersion = ""
    }
}

if ($prevVersion -and -not $Force -and ((Compare-DottedVersion $prevVersion $pluginVersion) -gt 0)) {
    Write-Host "install.ps1: installed $prevVersion is newer than package $pluginVersion; skipping (pass -Force to overwrite)"
    return
}

$systemNodeBin = $null
$systemNodeVer = ""
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    try {
        $systemNodeVer = & node -p "process.versions.node" 2>$null
        $major = [int](($systemNodeVer -split "\.")[0])
        if ($major -ge $MinNodeMajor) {
            $systemNodeBin = [System.IO.Path]::GetFullPath($nodeCmd.Source)
        }
    } catch {
        $systemNodeBin = $null
    }
}

$useBundled = $ForceBundledNode -or -not $systemNodeBin
if ($useBundled -and -not (Test-Path -LiteralPath $runtimeSrc)) {
    throw "install.ps1: system Node.js >= $MinNodeMajor not found and payload has no runtime\$triple"
}

Write-Host "Installing YAAIF Cursor plugin $pluginVersion -> $dest"
if ($prevVersion) {
    Write-Host "Updating existing install ($prevVersion -> $pluginVersion)"
}

New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
New-Item -ItemType Directory -Force -Path $yaaifHome | Out-Null
if (-not (Test-Path -LiteralPath $dest)) {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
}

$robocopy = Get-Command robocopy -ErrorAction SilentlyContinue
if ($robocopy) {
    & robocopy $pluginSrc $dest /MIR /XD .git node_modules runtime /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed with exit code $LASTEXITCODE"
    }
} else {
    if (Test-Path -LiteralPath $dest) {
        Get-ChildItem -LiteralPath $dest -Force | Where-Object { $_.Name -ne "runtime" } | Remove-Item -Recurse -Force
    }
    Copy-Item -Path (Join-Path $pluginSrc "*") -Destination $dest -Recurse -Force
}

$nodeSource = "system"
$nodeVersion = $systemNodeVer
$nodeCommand = $systemNodeBin

if ($useBundled) {
    Write-Host "Bundling official Node.js from payload\runtime\$triple"
    $runtimeDest = Join-Path $dest "runtime\node"
    if (Test-Path -LiteralPath $runtimeDest) {
        Remove-Item -LiteralPath $runtimeDest -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $runtimeDest) | Out-Null
    Copy-Item -Path $runtimeSrc -Destination $runtimeDest -Recurse -Force
    $nodeCommand = [System.IO.Path]::GetFullPath((Join-Path $runtimeDest "node.exe"))
    if (-not (Test-Path -LiteralPath $nodeCommand)) {
        throw "install.ps1: bundled node missing at $nodeCommand"
    }
    $nodeSource = "bundled"
    try {
        $nodeVersion = & $nodeCommand -p "process.versions.node"
    } catch {
        if (Test-Path -LiteralPath $runtimeManifest) {
            $nodeVersion = (Get-Content -LiteralPath $runtimeManifest -Raw | ConvertFrom-Json).node_version
        }
    }
} else {
    $runtimeDir = Join-Path $dest "runtime"
    if (Test-Path -LiteralPath $runtimeDir) {
        Remove-Item -LiteralPath $runtimeDir -Recurse -Force
    }
    Write-Host "Using system Node.js $nodeVersion ($nodeCommand)"
}

if (-not $nodeCommand -or $nodeCommand -eq "node") {
    throw "install.ps1: refused to write a non-absolute Node path into mcp.json"
}

$mcpPath = Join-Path $dest "mcp.json"
$mcp = Get-Content -LiteralPath $mcpPath -Raw | ConvertFrom-Json
if (-not $mcp.mcpServers) {
    $mcp | Add-Member -NotePropertyName mcpServers -NotePropertyValue (@{ yaaif = @{} })
}
if (-not $mcp.mcpServers.yaaif) {
    $mcp.mcpServers | Add-Member -NotePropertyName yaaif -NotePropertyValue (@{})
}
$mcp.mcpServers.yaaif.command = $nodeCommand
if (-not $mcp.mcpServers.yaaif.args) {
    $mcp.mcpServers.yaaif.args = @(
        '${CURSOR_PLUGIN_ROOT}/dist/yaaif-cursor-mcp.mjs',
        '--client',
        'cursor'
    )
}
$mcp | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $mcpPath -Encoding utf8

$updatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$manifest = [ordered]@{
    installer       = "yaaif-cursor-plugin"
    plugin_version  = $pluginVersion
    node_source     = $nodeSource
    node_version    = $nodeVersion
    plugin_path     = $dest
    runtime_triple  = $triple
    node_command    = $nodeCommand
    updated_at      = $updatedAt
}
($manifest | ConvertTo-Json) | Set-Content -LiteralPath $manifestPath -Encoding utf8

$uninstallSrc = Join-Path $PSScriptRoot "uninstall.ps1"
if (-not (Test-Path -LiteralPath $uninstallSrc)) {
    $uninstallSrc = Join-Path $PayloadDir "lib\uninstall.ps1"
}
$uninstallHint = "installer\lib\uninstall.ps1"
if (Test-Path -LiteralPath $uninstallSrc) {
    Copy-Item -LiteralPath $uninstallSrc -Destination (Join-Path $yaaifHome "uninstall.ps1") -Force
    $uninstallHint = Join-Path $yaaifHome "uninstall.ps1"
}

$tpl = Join-Path $PSScriptRoot "next-steps.html"
if (-not (Test-Path -LiteralPath $tpl)) {
    $tpl = Join-Path $PayloadDir "lib\next-steps.html"
}
$nextOut = Join-Path $yaaifHome "NEXT_STEPS.html"
if (Test-Path -LiteralPath $tpl) {
    $html = Get-Content -LiteralPath $tpl -Raw
    $html = $html.Replace("__PLUGIN_VERSION__", $pluginVersion).
        Replace("__PLUGIN_PATH__", $dest).
        Replace("__NODE_SOURCE__", $nodeSource).
        Replace("__NODE_VERSION__", "$nodeVersion").
        Replace("__UNINSTALL_HINT__", $uninstallHint)
    Set-Content -LiteralPath $nextOut -Value $html -Encoding utf8
    Copy-Item -LiteralPath $nextOut -Destination (Join-Path $dest "NEXT_STEPS.html") -Force
    if ($env:YAAIF_INSTALLER_NO_OPEN -ne "1") {
        Start-Process $nextOut
    }
}

Write-Host "Installed YAAIF Cursor plugin $pluginVersion"
Write-Host "  path:   $dest"
Write-Host "  node:   $nodeSource $nodeVersion ($nodeCommand)"
Write-Host ""
Write-Host "Next steps: $nextOut"
Write-Host "First install: in Cursor, Plugins -> + Add -> Add local plugin -> $dest"
Write-Host "Then Developer: Reload Window and run /yaaif-doctor."
Write-Host "Updates only need Developer: Reload Window."
