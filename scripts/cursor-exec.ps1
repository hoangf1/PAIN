<#
.SYNOPSIS
  Run Cursor Agent headlessly against this repo and print its reply.

.EXAMPLE
  .\scripts\cursor-exec.ps1 "Summarize rea-work\README.md in 3 bullets"
  .\scripts\cursor-exec.ps1 -Write "Fix the typo in README.md"   # allows edits/shell
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Prompt,
    [string]$Model = 'auto',
    [string]$Workspace = (Split-Path -Parent $PSScriptRoot),
    [ValidateSet('text', 'json', 'stream-json')][string]$OutputFormat = 'text',
    [string[]]$AddDir,   # extra readable roots (e.g. a spec folder outside the repo)
    [switch]$Write   # default is read-only "ask" mode
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command cursor-agent -ErrorAction SilentlyContinue)) {
    throw "cursor-agent not found on PATH. Install the Cursor CLI and run 'cursor-agent login'."
}

$cliArgs = @('--print', '--trust', '--workspace', $Workspace, '--output-format', $OutputFormat)
if ($Write) { $cliArgs += '--force' } else { $cliArgs += @('--mode', 'ask') }
if ($Model) { $cliArgs += @('--model', $Model) }
foreach ($d in $AddDir) { $cliArgs += @('--add-dir', $d) }
$cliArgs += $Prompt

& cursor-agent @cliArgs
exit $LASTEXITCODE
