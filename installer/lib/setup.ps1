# Visible post-install: detect server, write profile, browser PKCE login.
[CmdletBinding()]
param(
    [string]$HomeDir = $env:USERPROFILE,
    [switch]$NoPause
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$log = Join-Path $env:TEMP "yaaif-cursor-plugin-install.log"
function Write-SetupLog([string]$Message) {
    $line = "{0:u} {1}" -f (Get-Date).ToUniversalTime(), $Message
    Add-Content -LiteralPath $log -Value $line -ErrorAction SilentlyContinue
    Write-Host $Message
}

$dest = Join-Path $HomeDir ".cursor\plugins\local\yaaif"
$yaaifHome = Join-Path $HomeDir ".yaaif\cursor"
$manifestPath = Join-Path $yaaifHome "install-manifest.json"
$bundle = Join-Path $dest "dist\yaaif-cursor-mcp.mjs"

$nodeCommand = $null
if (Test-Path -LiteralPath $manifestPath) {
    try {
        $man = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        if ($man.node_command) { $nodeCommand = [string]$man.node_command }
        if ($man.plugin_path) {
            $dest = [string]$man.plugin_path
            $bundle = Join-Path $dest "dist\yaaif-cursor-mcp.mjs"
        }
    } catch { }
}
if (-not $nodeCommand -or -not (Test-Path -LiteralPath $nodeCommand)) {
    $mcpPath = Join-Path $dest "mcp.json"
    if (Test-Path -LiteralPath $mcpPath) {
        try {
            $mcp = Get-Content -LiteralPath $mcpPath -Raw | ConvertFrom-Json
            $nodeCommand = [string]$mcp.mcpServers.yaaif.command
        } catch { }
    }
}

Write-Host ""
Write-Host "YAAIF Cursor plugin setup"
Write-Host "Detecting the default server, saving the profile, and signing in..."
Write-Host ""

if (-not (Test-Path -LiteralPath $bundle)) {
    Write-SetupLog "setup.ps1: bundle missing at $bundle"
    Write-Host "Plugin files are installed, but the MCP bundle is missing."
    Write-Host "Add the local plugin in Cursor and run /yaaif-doctor."
} elseif (-not $nodeCommand -or -not (Test-Path -LiteralPath $nodeCommand)) {
    Write-SetupLog "setup.ps1: node missing ($nodeCommand)"
    Write-Host "Could not find Node.js. Plugin files are installed."
} else {
    Write-SetupLog "setup.ps1: $nodeCommand $bundle --setup all"
    try {
        & $nodeCommand $bundle --client cursor --setup all
    } catch {
        Write-SetupLog "setup.ps1 failed: $($_.Exception.Message)"
        Write-Host "Sign-in did not finish. Plugin files are installed."
        Write-Host "In Cursor, run /yaaif-login after you add the local plugin."
    }
}

$tpl = Join-Path $PSScriptRoot "next-steps.html"
$nextOut = Join-Path $yaaifHome "NEXT_STEPS.html"
if (Test-Path -LiteralPath $tpl) {
    $profileId = "hosted"
    $loginStatus = "Sign in from Cursor with /yaaif-login if the installer did not complete login."
    $loginEmail = "-"
    $tenantName = "-"
    $pluginVersion = "unknown"
    $nodeSource = ""
    $nodeVersion = ""
    $uninstallHint = Join-Path $yaaifHome "uninstall.ps1"
    if (Test-Path -LiteralPath $manifestPath) {
        try {
            $man = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
            if ($man.plugin_version) { $pluginVersion = [string]$man.plugin_version }
            if ($man.node_source) { $nodeSource = [string]$man.node_source }
            if ($man.node_version) { $nodeVersion = [string]$man.node_version }
        } catch { }
    }
    $statusPath = Join-Path $yaaifHome "setup-status.json"
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
            }
        } catch { }
    }
    $html = Get-Content -LiteralPath $tpl -Raw
    $html = $html.Replace("__PLUGIN_VERSION__", $pluginVersion).
        Replace("__PLUGIN_PATH__", $dest).
        Replace("__NODE_SOURCE__", $nodeSource).
        Replace("__NODE_VERSION__", "$nodeVersion").
        Replace("__UNINSTALL_HINT__", $uninstallHint).
        Replace("__PROFILE_ID__", $profileId).
        Replace("__LOGIN_STATUS__", $loginStatus).
        Replace("__LOGIN_EMAIL__", $loginEmail).
        Replace("__TENANT_NAME__", $tenantName)
    Set-Content -LiteralPath $nextOut -Value $html -Encoding utf8
    if (Test-Path -LiteralPath $dest) {
        Copy-Item -LiteralPath $nextOut -Destination (Join-Path $dest "NEXT_STEPS.html") -Force
    }
}

Write-Host ""
Write-Host "Next: Cursor -> Plugins -> + Add -> Add local plugin -> $dest"
Write-Host "Then Developer: Reload Window and run /yaaif-doctor."
if ($env:YAAIF_INSTALLER_NO_OPEN -ne "1" -and (Test-Path -LiteralPath $nextOut)) {
    try { Start-Process $nextOut } catch { }
}

if (-not $NoPause -and $env:YAAIF_INSTALLER_NO_OPEN -ne "1") {
    Write-Host ""
    Write-Host "Press Enter to close..."
    try { [void][Console]::ReadLine() } catch { }
}

exit 0
