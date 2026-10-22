# Run a Julia script (and optional args) on the PAIN DaemonMode server.
# Usage:  .\scripts\devtools\run_in_daemon.ps1 scripts\smoke\smoke_gui_model.jl
#         .\scripts\devtools\run_in_daemon.ps1 scripts\devtools\run_tests_in_daemon.jl CYL2D
#         .\scripts\devtools\run_in_daemon.ps1 scripts\devtools\run_tests_in_daemon.jl CYL2D "Validation case registry"
#
# DaemonMode include_string leaves @__DIR__ as the client pwd(), so we cd to the
# script's directory before connecting. Spaces in test filters are escaped as
# <|> because DaemonMode's wire format joins/splits args on spaces.
$ErrorActionPreference = "Stop"
if ($args.Count -lt 1) {
    Write-Host "Usage: run_in_daemon.ps1 <script.jl> [args…]"
    exit 1
}
$DevTools = $PSScriptRoot
$PainRoot = (Resolve-Path (Join-Path $DevTools "..\..")).Path
$Script = $args[0]
if (-not [System.IO.Path]::IsPathRooted($Script)) {
    $cand = Join-Path (Get-Location) $Script
    if (Test-Path $cand) {
        $Script = $cand
    } else {
        $Script = Join-Path $PainRoot $args[0]
    }
}
$Script = (Resolve-Path $Script).Path
$ScriptDir = Split-Path -Parent $Script
$Rest = @()
if ($args.Count -gt 1) { $Rest = $args[1..($args.Count - 1)] }

$env:QT_QPA_PLATFORM = if ($env:QT_QPA_PLATFORM) { $env:QT_QPA_PLATFORM } else { "offscreen" }

if ([System.IO.Path]::GetFileName($Script) -eq "run_tests_in_daemon.jl") {
    $Rest = @($Rest | ForEach-Object { $_ -replace ' ', '<|>' })
}

$prev = Get-Location
Set-Location $ScriptDir
try {
    $juliaArgs = @("--project=$DevTools", (Join-Path $DevTools "client.jl"), $Script) + $Rest
    & julia @juliaArgs
    $code = $LASTEXITCODE
} finally {
    Set-Location $prev
}
exit $code
