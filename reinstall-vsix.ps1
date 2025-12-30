[CmdletBinding()]
param(
    # Optional override: path to VS Code CLI (e.g. "code" or "code-insiders").
    [string]$CodeCmd = 'code',

    # Optional override: specific extension id to uninstall.
    # Default is derived from package.json ("publisher.name").
    [string]$ExtensionId,

    # Optional override: install this VSIX instead of the newest *.vsix in .\artifacts.
    [string]$VsixPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $scriptDir

function Get-ExtensionIdFromManifest
{
    $manifestPath = Join-Path $scriptDir 'package.json'
    if (-not (Test-Path -LiteralPath $manifestPath))
    {
        throw "package.json not found at: $manifestPath"
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($manifest.publisher) -or [string]::IsNullOrWhiteSpace($manifest.name))
    {
        throw "package.json is missing 'publisher' and/or 'name'."
    }

    return "$($manifest.publisher).$($manifest.name)"
}

function Resolve-CodeCommand
{
    param([string]$Command)

    $resolved = Get-Command $Command -ErrorAction SilentlyContinue
    if ($null -ne $resolved) { return $resolved.Path }

    throw "VS Code CLI '$Command' was not found on PATH. In VS Code, run 'Shell Command: Install \'code\' command in PATH' (or provide -CodeCmd)."
}

function Resolve-VsixPath
{
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path))
    {
        if (-not (Test-Path -LiteralPath $Path))
        {
            throw "VSIX not found: $Path"
        }
        return (Resolve-Path -LiteralPath $Path).Path
    }

    $artifactsDir = Join-Path $scriptDir 'artifacts'
    $latest = Get-ChildItem -Path $artifactsDir -Filter '*.vsix' -File -ErrorAction SilentlyContinue |
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -First 1

    if ($null -eq $latest)
    {
        throw "No .vsix found in .\\artifacts\\. Run '.\\package-vsix.ps1' (or 'npm run package') first."
    }

    return $latest.FullName
}

# 1) Package
Write-Host "Packaging VSIX..." -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptDir 'package-vsix.ps1')

# 2) Resolve inputs
$codePath = Resolve-CodeCommand -Command $CodeCmd
$vsix = Resolve-VsixPath -Path $VsixPath

if ([string]::IsNullOrWhiteSpace($ExtensionId))
{
    $ExtensionId = Get-ExtensionIdFromManifest
}

Write-Host "Using VS Code CLI: $codePath" -ForegroundColor DarkGray
Write-Host "Extension ID: $ExtensionId" -ForegroundColor DarkGray
Write-Host "VSIX: $vsix" -ForegroundColor DarkGray

# 3) Uninstall old
Write-Host "Uninstalling (if present): $ExtensionId" -ForegroundColor Cyan
try
{
    & $codePath --uninstall-extension $ExtensionId | Out-Host
}
catch
{
    # VS Code returns non-zero if not installed; treat as non-fatal.
    Write-Host "Uninstall step returned an error (often means not installed). Continuing..." -ForegroundColor Yellow
}

# 4) Install new
Write-Host "Installing: $vsix" -ForegroundColor Cyan
& $codePath --install-extension $vsix --force | Out-Host

Write-Host "Done. If VS Code was open, run 'Developer: Reload Window'." -ForegroundColor Green
