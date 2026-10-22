$ErrorActionPreference = "Stop"
$DevTools = $PSScriptRoot
if (Test-Path (Join-Path $DevTools "daemon.pid")) {
    $old = Get-Content (Join-Path $DevTools "daemon.pid")
    Stop-Process -Id $old -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $DevTools "daemon.pid") -Force -ErrorAction SilentlyContinue
}
try { julia --project=$DevTools -e "using DaemonMode; DaemonMode.sendExitCode()" 2>$null } catch {}
Remove-Item (Join-Path $DevTools "daemon.out.log"), (Join-Path $DevTools "daemon.err.log") -Force -ErrorAction SilentlyContinue
$env:QT_QPA_PLATFORM = "offscreen"
& (Join-Path $DevTools "start_daemon.ps1")
$ready = $false
for ($i = 0; $i -lt 90; $i++) {
    Start-Sleep -Seconds 5
    $daemonPid = Get-Content (Join-Path $DevTools "daemon.pid") -ErrorAction SilentlyContinue
    $alive = $false
    if ($daemonPid) {
        $alive = [bool](Get-Process -Id $daemonPid -ErrorAction SilentlyContinue)
    }
    $logPath = Join-Path $DevTools "daemon.out.log"
    $c = ""
    if (Test-Path $logPath) { $c = Get-Content $logPath -Raw -ErrorAction SilentlyContinue }
    if ($null -eq $c) { $c = "" }
    Write-Host ("t={0}s alive={1} loglen={2}" -f ($i * 5), $alive, $c.Length)
    if (($c -match "Starting DaemonMode") -and $alive) {
        Write-Host "READY"
        $ready = $true
        break
    }
    if ($daemonPid -and -not $alive) {
        Write-Host "DIED"
        Get-Content $logPath -ErrorAction SilentlyContinue
        $err = Join-Path $DevTools "daemon.err.log"
        if (Test-Path $err) {
            Write-Host "--- err (as text) ---"
            Get-Content $err -ErrorAction SilentlyContinue
        }
        break
    }
}
if (-not $ready) { Write-Host "gave up"; exit 1 }
