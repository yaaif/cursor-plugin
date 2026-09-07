# Install or update the YAAIF Cursor plugin into %USERPROFILE%\.cursor\plugins\local\yaaif.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PayloadDir,
    [string]$HomeDir = $env:USERPROFILE,
    [switch]$ForceBundledNode,
    [switch]$Force,
    [switch]$SkipSetup,
    [int]$MinNodeMajor = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:InstallLog = Join-Path $env:TEMP "yaaif-cursor-plugin-install.log"

function Write-InstallLog([string]$Message) {
    $line = "{0:u} {1}" -f (Get-Date).ToUniversalTime(), $Message
    Add-Content -LiteralPath $script:InstallLog -Value $line -ErrorAction SilentlyContinue
    Write-Host $Message
}

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

function Test-PluginDest([string]$Root) {
    $pluginJson = Join-Path $Root ".cursor-plugin\plugin.json"
    $bundle = Join-Path $Root "dist\yaaif-cursor-mcp.mjs"
    if (-not (Test-Path -LiteralPath $pluginJson)) {
        throw "install.ps1: missing $pluginJson"
    }
    if (-not (Test-Path -LiteralPath $bundle)) {
        throw "install.ps1: missing $bundle"
    }
    Write-InstallLog "verified dest plugin.json + bundle under $Root"
}

function Test-McpAbsoluteCommand([string]$Root) {
    $mcpPath = Join-Path $Root "mcp.json"
    if (-not (Test-Path -LiteralPath $mcpPath)) { return $false }
    try {
        $mcp = Get-Content -LiteralPath $mcpPath -Raw | ConvertFrom-Json
        $cmd = [string]$mcp.mcpServers.yaaif.command
        if (-not $cmd -or $cmd -eq "node") { return $false }
        return $cmd -match '[:\\/]'
    } catch {
        return $false
    }
}

function Test-InstalledPluginOk([string]$Root) {
    if (-not (Test-Path -LiteralPath $Root)) { return $false }
    try {
        Test-PluginDest $Root
        return [bool](Test-McpAbsoluteCommand $Root)
    } catch {
        Write-InstallLog "dest not usable: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-RobocopySafe([string]$From, [string]$To, [string[]]$ExtraArgs, [switch]$AllowPartial) {
    New-Item -ItemType Directory -Force -Path $To | Out-Null
    $rcArgs = @($From, $To) + $ExtraArgs + @("/NFL", "/NDL", "/NJH", "/NJS", "/nc", "/ns", "/np", "/R:1", "/W:1")
    & robocopy @rcArgs | Out-Null
    $code = $LASTEXITCODE
    Write-InstallLog "robocopy $From -> $To exit=$code"
    if ($code -ge 8) {
        if ($AllowPartial) {
            Write-InstallLog "robocopy partial or locked files (exit $code); will re-verify dest"
            return $code
        }
        throw "robocopy failed with exit code $code"
    }
    return $code
}

function Update-NextStepsHtml {
    param(
        [string]$TemplatePath,
        [string]$DestHtml,
        [string]$PluginVersion,
        [string]$PluginPath,
        [string]$NodeSource,
        [string]$NodeVersion,
        [string]$UninstallHint,
        [string]$YaaifHome
    )
    if (-not (Test-Path -LiteralPath $TemplatePath)) { return }
    $profileId = "hosted"
    $loginStatus = "Sign in from Cursor with /yaaif-login if the installer did not complete login."
    $loginEmail = "-"
    $tenantName = "-"
    $statusPath = Join-Path $YaaifHome "setup-status.json"
    if (Test-Path -LiteralPath $statusPath) {
        try {
            $st = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
            if ($st.profile_id) { $profileId = [string]$st.profile_id }
            if ($st.email) { $loginEmail = [string]$st.email }
            if ($st.tenant_name) { $tenantName = [string]$st.tenant_name }
            elseif ($st.tenant_id) { $tenantName = [string]$st.tenant_id }
            switch ([string]$st.login) {
                "ok" { $loginStatus = "Signed in." }
                "skipped" { $loginStatus = "Login skipped (silent/CI). Run /yaaif-login in Cursor." }
                "failed" { $loginStatus = "Login did not finish. Run /yaaif-login in Cursor." }
                "required" { $loginStatus = "Login required. Run /yaaif-login in Cursor." }
                default { if ($st.message) { $loginStatus = [string]$st.message } }
            }
        } catch {
            Write-InstallLog "setup-status.json unreadable: $($_.Exception.Message)"
        }
    }
    $html = Get-Content -LiteralPath $TemplatePath -Raw
    $html = $html.Replace("__PLUGIN_VERSION__", $PluginVersion).
        Replace("__PLUGIN_PATH__", $PluginPath).
        Replace("__NODE_SOURCE__", $NodeSource).
        Replace("__NODE_VERSION__", "$NodeVersion").
        Replace("__UNINSTALL_HINT__", $UninstallHint).
        Replace("__PROFILE_ID__", $profileId).
        Replace("__LOGIN_STATUS__", $loginStatus).
        Replace("__LOGIN_EMAIL__", $loginEmail).
        Replace("__TENANT_NAME__", $tenantName)
    Set-Content -LiteralPath $DestHtml -Value $html -Encoding utf8
    Copy-Item -LiteralPath $DestHtml -Destination (Join-Path $PluginPath "NEXT_STEPS.html") -Force
}

function Invoke-YaaifSetupCli([string]$NodeCommand, [string]$Dest, [string]$YaaifHome) {
    if ($env:YAAIF_INSTALLER_NO_SETUP -eq "1") {
        Write-InstallLog "setup skipped (YAAIF_INSTALLER_NO_SETUP=1)"
        return
    }
    $bundle = Join-Path $Dest "dist\yaaif-cursor-mcp.mjs"
    if (-not (Test-Path -LiteralPath $bundle)) {
        Write-InstallLog "setup skipped (bundle missing)"
        return
    }
    Write-InstallLog "setup: $NodeCommand $bundle --client cursor --setup all"
    try {
        & $NodeCommand $bundle --client cursor --setup all
        Write-InstallLog "setup exit=$LASTEXITCODE"
    } catch {
        Write-InstallLog "setup failed (plugin files installed): $($_.Exception.Message)"
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $PayloadDir "plugin"))) {
    throw "install.ps1: -PayloadDir must be a staged payload directory"
}

$PayloadDir = (Resolve-Path -LiteralPath $PayloadDir).Path
$pluginSrc = Join-Path $PayloadDir "plugin"
$dest = Join-Path $HomeDir ".cursor\plugins\local\yaaif"
$yaaifHome = Join-Path $HomeDir ".yaaif\cursor"
$manifestPath = Join-Path $yaaifHome "install-manifest.json"

Write-InstallLog "install.ps1 start PayloadDir=$PayloadDir dest=$dest"

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

$destOk = Test-InstalledPluginOk $dest
if ($prevVersion -and -not $Force -and ((Compare-DottedVersion $prevVersion $pluginVersion) -gt 0) -and $destOk) {
    Write-InstallLog "install.ps1: installed $prevVersion is newer than package $pluginVersion and dest is verified; skipping copy (pass -Force to overwrite)"
    $nodeCommand = $null
    $nodeSource = ""
    $nodeVersion = ""
    if (Test-Path -LiteralPath $manifestPath) {
        try {
            $ex = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
            if ($ex.node_command) { $nodeCommand = [string]$ex.node_command }
            if ($ex.node_source) { $nodeSource = [string]$ex.node_source }
            if ($ex.node_version) { $nodeVersion = [string]$ex.node_version }
        } catch { }
    }
    if (-not $nodeCommand -or $nodeCommand -eq "node") {
        try {
            $mcp = Get-Content -LiteralPath (Join-Path $dest "mcp.json") -Raw | ConvertFrom-Json
            $nodeCommand = [string]$mcp.mcpServers.yaaif.command
        } catch { }
    }
    $uninstallHint = Join-Path $yaaifHome "uninstall.ps1"
    $tpl = Join-Path $PSScriptRoot "next-steps.html"
    if (-not (Test-Path -LiteralPath $tpl)) {
        $tpl = Join-Path $PayloadDir "lib\next-steps.html"
    }
    $nextOut = Join-Path $yaaifHome "NEXT_STEPS.html"
    if (-not $SkipSetup -and $nodeCommand) {
        Invoke-YaaifSetupCli -NodeCommand $nodeCommand -Dest $dest -YaaifHome $yaaifHome
    }
    Update-NextStepsHtml -TemplatePath $tpl -DestHtml $nextOut -PluginVersion $prevVersion `
        -PluginPath $dest -NodeSource $nodeSource -NodeVersion "$nodeVersion" `
        -UninstallHint $uninstallHint -YaaifHome $yaaifHome
    $global:LASTEXITCODE = 0
    return
}
if ($prevVersion -and ((Compare-DottedVersion $prevVersion $pluginVersion) -gt 0) -and -not $destOk) {
    Write-InstallLog "manifest claims $prevVersion but dest is missing or incomplete; repairing with package $pluginVersion"
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

Write-InstallLog "Installing YAAIF Cursor plugin $pluginVersion -> $dest"
if ($prevVersion) {
    Write-InstallLog "Updating existing install ($prevVersion -> $pluginVersion)"
}

New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
New-Item -ItemType Directory -Force -Path $yaaifHome | Out-Null

$destParent = Split-Path $dest
$staging = Join-Path $destParent "yaaif.__staging"
$backup = Join-Path $destParent "yaaif.__old"
if (Test-Path -LiteralPath $staging) {
    Remove-Item -LiteralPath $staging -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $staging | Out-Null

$robocopy = Get-Command robocopy -ErrorAction SilentlyContinue
if ($robocopy) {
    Invoke-RobocopySafe $pluginSrc $staging @("/E", "/XD", ".git", "node_modules", "runtime") | Out-Null
} else {
    Copy-Item -Path (Join-Path $pluginSrc "*") -Destination $staging -Recurse -Force
}
Test-PluginDest $staging

$swapped = $false
for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
        if (Test-Path -LiteralPath $backup) {
            Remove-Item -LiteralPath $backup -Recurse -Force
        }
        if (Test-Path -LiteralPath $dest) {
            Rename-Item -LiteralPath $dest -NewName "yaaif.__old"
        }
        Rename-Item -LiteralPath $staging -NewName "yaaif"
        $swapped = $true
        Write-InstallLog "swapped staging into $dest (attempt $attempt)"
        break
    } catch {
        Write-InstallLog "swap attempt $attempt failed: $($_.Exception.Message)"
        if (-not (Test-Path -LiteralPath $dest) -and (Test-Path -LiteralPath $backup)) {
            try { Rename-Item -LiteralPath $backup -NewName "yaaif" } catch { }
        }
        if ($attempt -lt 3) { Start-Sleep -Seconds 1 }
    }
}

if (-not $swapped) {
    Write-InstallLog "swap failed after retries; in-place copy without /MIR"
    if (-not (Test-Path -LiteralPath $dest) -and (Test-Path -LiteralPath $backup)) {
        try { Rename-Item -LiteralPath $backup -NewName "yaaif" } catch { }
    }
    if (-not (Test-Path -LiteralPath $dest)) {
        New-Item -ItemType Directory -Force -Path $dest | Out-Null
    }
    if ($robocopy) {
        Invoke-RobocopySafe $staging $dest @("/E", "/IS", "/IT", "/XD", ".git", "node_modules", "runtime") -AllowPartial | Out-Null
    } else {
        try {
            Copy-Item -Path (Join-Path $staging "*") -Destination $dest -Recurse -Force
        } catch {
            Write-InstallLog "in-place copy hit locked files: $($_.Exception.Message)"
        }
    }
}

if (-not (Test-Path -LiteralPath $dest) -and (Test-Path -LiteralPath $backup)) {
    Write-InstallLog "dest missing after copy; restoring yaaif.__old"
    Rename-Item -LiteralPath $backup -NewName "yaaif"
}

try {
    Test-PluginDest $dest
} catch {
    if (Test-Path -LiteralPath $backup) {
        Write-InstallLog "verify failed; restoring yaaif.__old"
        if (Test-Path -LiteralPath $dest) {
            Remove-Item -LiteralPath $dest -Recurse -Force -ErrorAction SilentlyContinue
        }
        Rename-Item -LiteralPath $backup -NewName "yaaif"
    }
    throw
}

$stgBundle = Join-Path $staging "dist\yaaif-cursor-mcp.mjs"
$dstBundle = Join-Path $dest "dist\yaaif-cursor-mcp.mjs"
if ((Test-Path -LiteralPath $stgBundle) -and (Test-Path -LiteralPath $dstBundle)) {
    $stgItem = Get-Item -LiteralPath $stgBundle
    $dstItem = Get-Item -LiteralPath $dstBundle
    if ($dstItem.Length -ne $stgItem.Length) {
        Write-InstallLog "dest bundle looks stale or locked (size $($dstItem.Length) vs staging $($stgItem.Length)). Close Cursor, reload the window, then re-run the installer."
    }
}

if (Test-Path -LiteralPath $staging) {
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -LiteralPath $backup) {
    Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue
}

$nodeSource = "system"
$nodeVersion = $systemNodeVer
$nodeCommand = $systemNodeBin

if ($useBundled) {
    Write-InstallLog "Bundling official Node.js from payload\runtime\$triple"
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
    Write-InstallLog "Using system Node.js $nodeVersion ($nodeCommand)"
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
Write-InstallLog "mcp.json command=$nodeCommand"

$updatedAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$manifest = [ordered]@{
    installer       = "yaaif-cursor-plugin"
    plugin_version  = $pluginVersion
    node_source     = $nodeSource
    node_version    = $nodeVersion
    plugin_path     = $dest
    runtime_triple  = $triple
    node_command    = $nodeCommand
    verified        = $true
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

if (-not $SkipSetup) {
    Invoke-YaaifSetupCli -NodeCommand $nodeCommand -Dest $dest -YaaifHome $yaaifHome
}

Update-NextStepsHtml -TemplatePath $tpl -DestHtml $nextOut -PluginVersion $pluginVersion `
    -PluginPath $dest -NodeSource $nodeSource -NodeVersion "$nodeVersion" `
    -UninstallHint $uninstallHint -YaaifHome $yaaifHome

if (-not $SkipSetup -and $env:YAAIF_INSTALLER_NO_OPEN -ne "1") {
    try {
        Start-Process $nextOut
    } catch {
        Write-InstallLog "Could not open next-steps page: $($_.Exception.Message)"
    }
}

Write-InstallLog "Installed YAAIF Cursor plugin $pluginVersion"
Write-Host "  path:   $dest"
Write-Host "  node:   $nodeSource $nodeVersion ($nodeCommand)"
Write-Host ""
Write-Host "Next steps: $nextOut"
Write-Host "First install: in Cursor, Plugins -> + Add -> Add local plugin -> $dest"
Write-Host "Then Developer: Reload Window and run /yaaif-doctor."
Write-Host "Updates only need Developer: Reload Window."

# Robocopy leaves 1-7 on success; native MSI/cmd callers must see 0.
$global:LASTEXITCODE = 0
