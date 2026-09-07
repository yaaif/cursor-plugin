# Called from the per-user MSI after files are laid down.
[CmdletBinding()]
param(
    [string]$SetupDir = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# MSI [INSTALLFOLDER] is "C:\...\setup\" - a quoted value ending in \ breaks
# powershell.exe -File argument parsing. Strip a leaked quote and separators.
if ($SetupDir) {
    $SetupDir = $SetupDir.Trim().TrimEnd('"').TrimEnd('\', '/')
}
if (-not $SetupDir) {
    $SetupDir = $PSScriptRoot
}

$log = Join-Path $env:TEMP "yaaif-cursor-plugin-install.log"
function Write-InstallLog([string]$Message) {
    $line = "{0:u} {1}" -f (Get-Date).ToUniversalTime(), $Message
    Add-Content -LiteralPath $log -Value $line -ErrorAction SilentlyContinue
}

function Test-MsiexecQuiet {
    try {
        $thisProc = Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction Stop
        $parentId = $thisProc.ParentProcessId
        $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$parentId" -ErrorAction Stop
        $cmd = [string]$parent.CommandLine
        if ($cmd -match '(?i)(/qn|/quiet|/passive)\b') { return $true }
    } catch {
        return $false
    }
    return $false
}

function Test-SilentOrCi {
    if ($env:YAAIF_INSTALLER_NO_LOGIN -eq "1") { return $true }
    if ($env:YAAIF_INSTALLER_NO_OPEN -eq "1") { return $true }
    if ($env:YAAIF_INSTALLER_NO_SETUP -eq "1") { return $true }
    $ci = ""
    if ($env:CI) { $ci = [string]$env:CI }
    if ($ci -and $ci -ne "0" -and $ci.ToLower() -ne "false") { return $true }
    if (Test-MsiexecQuiet) { return $true }
    return $false
}

function Show-InstallFailure([string]$Message) {
    Write-InstallLog $Message
    if (Test-SilentOrCi) { return }
    if (-not [Environment]::UserInteractive) { return }
    try {
        Add-Type -AssemblyName System.Windows.Forms | Out-Null
        [void][System.Windows.Forms.MessageBox]::Show(
            "YAAIF Cursor plugin install failed.`r`n`r`n$Message`r`n`r`nSee $log",
            "YAAIF Cursor plugin",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    } catch {
        Write-InstallLog "message box skipped: $($_.Exception.Message)"
    }
}

try {
    Write-InstallLog "start SetupDir=$SetupDir"

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

    # File copy is the only MSI failure path. Setup/login is best-effort.
    & $install -PayloadDir $payload -HomeDir $env:USERPROFILE -SkipSetup
    if ($global:LASTEXITCODE -ge 8) {
        throw "install.ps1 failed with exit code $LASTEXITCODE"
    }

    $dest = Join-Path $env:USERPROFILE ".cursor\plugins\local\yaaif"
    $pluginJson = Join-Path $dest ".cursor-plugin\plugin.json"
    $bundle = Join-Path $dest "dist\yaaif-cursor-mcp.mjs"
    if (-not (Test-Path -LiteralPath $pluginJson) -or -not (Test-Path -LiteralPath $bundle)) {
        throw "Install-YaaifPlugin.ps1: dest missing after install.ps1 ($dest)"
    }
    Write-InstallLog "dest verified; MSI will succeed even if setup/login fails"

    $setupPs1 = Join-Path $payload "lib\setup.ps1"
    if (-not (Test-Path -LiteralPath $setupPs1)) {
        $setupPs1 = Join-Path $SetupDir "setup.ps1"
    }
    $silent = Test-SilentOrCi
    if (Test-Path -LiteralPath $setupPs1) {
        try {
            if ($silent) {
                Write-InstallLog "running silent setup (no browser login)"
                $env:YAAIF_INSTALLER_NO_LOGIN = "1"
                & $setupPs1 -HomeDir $env:USERPROFILE -NoPause
            } else {
                Write-InstallLog "launching visible setup window (not waiting)"
                $ps = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
                Start-Process -FilePath $ps -ArgumentList @(
                    "-NoProfile",
                    "-ExecutionPolicy", "Bypass",
                    "-File", $setupPs1,
                    "-HomeDir", $env:USERPROFILE
                ) -WindowStyle Normal | Out-Null
            }
        } catch {
            Write-InstallLog "setup skipped or failed (plugin files installed): $($_.Exception.Message)"
        }
    } else {
        Write-InstallLog "setup.ps1 missing; skip profile/login"
    }

    Write-InstallLog "ok"
    $global:LASTEXITCODE = 0
    exit 0
} catch {
    Write-InstallLog ("FAILED: " + $_.Exception.Message)
    Write-InstallLog ($_ | Out-String)
    Show-InstallFailure $_.Exception.Message
    throw
}
