# Stop the DaemonMode server started by start_daemon.ps1.
$ErrorActionPreference = "Stop"
$DevTools = $PSScriptRoot
$PidFile = Join-Path $DevTools "daemon.pid"

# Prefer a clean DaemonMode exit so the listen port is released.
try {
    julia --project=$DevTools -e "using DaemonMode; DaemonMode.sendExitCode()"
    Write-Host "Sent DaemonMode exit."
} catch {
    Write-Host "Could not send exit code (daemon may already be down): $_"
}

if (Test-Path $PidFile) {
    $daemonPid = Get-Content $PidFile
    $p = Get-Process -Id $daemonPid -ErrorAction SilentlyContinue
    if ($p) {
        Stop-Process -Id $daemonPid -Force -ErrorAction SilentlyContinue
        Write-Host "Killed PID $daemonPid"
    }
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}
