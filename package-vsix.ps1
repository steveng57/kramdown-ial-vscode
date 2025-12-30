Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Run from the repo root regardless of the current working directory.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $scriptDir

# Basic dependency check.
if (-not (Get-Command npm -ErrorAction SilentlyContinue))
{
    throw "npm was not found on PATH. Install Node.js (which includes npm) and try again."
}

Write-Host "Packaging VSIX via 'npm run package' (output: .\\artifacts\\)..." -ForegroundColor Cyan
npm run package

$artifactsDir = Join-Path $scriptDir 'artifacts'

# Best-effort: show the newest VSIX created in artifacts.
$latestVsix = Get-ChildItem -Path $artifactsDir -Filter '*.vsix' -File -ErrorAction SilentlyContinue |
Sort-Object -Property LastWriteTime -Descending |
Select-Object -First 1

if ($null -ne $latestVsix)
{
    Write-Host ("Created: {0}" -f $latestVsix.FullName) -ForegroundColor Green
}
else
{
    Write-Host "Package finished, but no .vsix was found in .\\artifacts\\." -ForegroundColor Yellow
}
