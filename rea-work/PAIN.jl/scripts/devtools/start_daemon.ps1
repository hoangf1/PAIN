# Start a persistent Julia daemon with PAIN + Revise + DaemonMode.
# Usage (from PAIN.jl):  .\scripts\devtools\start_daemon.ps1
# Stop:                  .\scripts\devtools\stop_daemon.ps1
$ErrorActionPreference = "Stop"
$DevTools = $PSScriptRoot
$PainRoot = (Resolve-Path (Join-Path $DevTools "..\..")).Path
$OutLog = Join-Path $DevTools "daemon.out.log"
$ErrLog = Join-Path $DevTools "daemon.err.log"
$PidFile = Join-Path $DevTools "daemon.pid"

if (Test-Path $PidFile) {
    $old = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($old -and (Get-Process -Id $old -ErrorAction SilentlyContinue)) {
        Write-Host "Daemon already running (PID $old). Stop it first with stop_daemon.ps1"
        exit 1
    }
}

Write-Host "Starting daemon (PAIN project: $PainRoot)…"
Write-Host "stdout: $OutLog"
Write-Host "stderr: $ErrLog"
# Never open a GUI window.
$env:QT_QPA_PLATFORM = if ($env:QT_QPA_PLATFORM) { $env:QT_QPA_PLATFORM } else { "offscreen" }

$proc = Start-Process -FilePath "julia" `
    -ArgumentList @("--project=$DevTools", (Join-Path $DevTools "start_daemon.jl")) `
    -WorkingDirectory $PainRoot `
    -RedirectStandardOutput $OutLog `
    -RedirectStandardError $ErrLog `
    -PassThru `
    -WindowStyle Hidden

$proc.Id | Set-Content $PidFile
Write-Host "Daemon PID $($proc.Id). First start compiles PAIN (can take minutes)."
Write-Host "Ready when $OutLog contains 'Starting DaemonMode.serve'. Then: .\scripts\devtools\run_in_daemon.ps1 <script.jl> [args…]"
