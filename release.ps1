<#
.SYNOPSIS
Creates and pushes a version tag to trigger Marketplace publishing.

.DESCRIPTION
This script automates the "release" steps for this VS Code extension repo:

1) Reads the extension version from package.json (e.g. 0.1.16)
2) Creates an annotated git tag in the form v<version> (e.g. v0.1.16)
3) Pushes the target branch (default: origin/main)
4) Pushes the tag to the remote

Pushing the tag triggers the GitHub Actions workflow .github/workflows/publish.yml,
which publishes the extension to the VS Code Marketplace.

Safety checks:
- Requires a clean working tree (no uncommitted changes)
- Refuses to run if you are not on the expected branch (unless -Force)
- Refuses to overwrite existing tags (unless -Force)

This script uses PowerShell's -WhatIf support via SupportsShouldProcess.

.PARAMETER Remote
Git remote name to push to (default: origin).

.PARAMETER Branch
Branch name to push (default: main). The script also checks you are currently
on this branch unless -Force is supplied.

.PARAMETER SkipBranchPush
If set, the script will not push the branch, only the tag.

.PARAMETER Force
Bypasses some safety checks and allows overwriting an existing tag (locally and/or remotely).
Use with care.

.PARAMETER Bump
Automatically bumps the version in package.json before tagging.
Allowed values: patch, minor, major.

.PARAMETER SetVersion
Sets package.json to an explicit version (SemVer: major.minor.patch) before tagging.

.PARAMETER CommitMessage
Commit message to use when bumping/setting the version (default: v<newVersion>).

.EXAMPLE
PS> ./release.ps1
Tags the current commit with v<package.json version>, pushes main, then pushes the tag.

.EXAMPLE
PS> ./release.ps1 -WhatIf
Shows what would happen without making any changes.

.EXAMPLE
PS> ./release.ps1 -Remote origin -Branch main
Same as default but explicit.

.EXAMPLE
PS> ./release.ps1 -SkipBranchPush
Only creates and pushes the tag.

.EXAMPLE
PS> ./release.ps1 -Bump patch
Bumps 0.1.16 -> 0.1.17 in package.json, commits it, tags v0.1.17, pushes main and the tag.

.EXAMPLE
PS> ./release.ps1 -SetVersion 0.2.0
Sets package.json version to 0.2.0, commits it, tags v0.2.0, pushes main and the tag.

.NOTES
Prereqs:
- git installed and available on PATH
- You have push permission to the repo
- GitHub repo secret VSCE_PAT is set (for the publish workflow)
- package.json version matches the tag version (enforced by workflow)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$Remote = "origin",

    [Parameter()]
    [string]$Branch = "main",

    [Parameter()]
    [switch]$SkipBranchPush,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [ValidateSet("patch", "minor", "major")]
    [string]$Bump,

    [Parameter()]
    [string]$SetVersion,

    [Parameter()]
    [string]$CommitMessage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Exec
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$File,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    $display = @($File) + @($Args)
    Write-Host ("> " + ($display -join ' '))

    $output = & $File @Args 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0)
    {
        $output | ForEach-Object { Write-Host $_ }
        throw "Command failed (exit $exitCode): $File $($Args -join ' ')"
    }

    # Normalize to an array of strings so callers can safely pipeline/index.
    return @($output | ForEach-Object { "$_" })
}

function Parse-SemVer
{
    param([Parameter(Mandatory = $true)][string]$Version)

    if ($Version -notmatch '^(?<maj>\d+)\.(?<min>\d+)\.(?<pat>\d+)$')
    {
        throw "Version '$Version' is not supported. Expected SemVer: major.minor.patch"
    }

    return [pscustomobject]@{
        Major = [int]$Matches.maj
        Minor = [int]$Matches.min
        Patch = [int]$Matches.pat
    }
}

function Format-SemVer
{
    param(
        [Parameter(Mandatory = $true)][int]$Major,
        [Parameter(Mandatory = $true)][int]$Minor,
        [Parameter(Mandatory = $true)][int]$Patch
    )

    return "$Major.$Minor.$Patch"
}

function Update-PackageJsonVersionInPlace
{
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$NewVersion
    )

    $raw = Get-Content -LiteralPath $Path -Raw

    if ($raw -notmatch '"version"\s*:\s*"(?<ver>[^"]+)"')
    {
        throw "Unable to find a version field in $Path"
    }

    $updated = [regex]::Replace(
        $raw,
        '"version"\s*:\s*"[^"]+"',
        '"version": "' + $NewVersion + '"',
        1
    )

    if ($updated -eq $raw)
    {
        throw "Failed to update version in $Path"
    }

    Set-Content -LiteralPath $Path -Value $updated -NoNewline
}

if (-not (Test-Path -LiteralPath "package.json"))
{
    throw "package.json not found in current directory. Run this from the repo root."
}

if ($Bump -and $SetVersion)
{
    throw "Specify only one of -Bump or -SetVersion."
}

$currentBranch = (Exec git rev-parse --abbrev-ref HEAD | Select-Object -First 1).Trim()
if (-not $Force -and $currentBranch -ne $Branch)
{
    throw "You are on '$currentBranch' but -Branch is '$Branch'. Switch branches or pass -Force."
}

# Basic safety checks
Exec git rev-parse --is-inside-work-tree | Out-Null

$gitStatus = @(Exec git status --porcelain)
if ($gitStatus.Count -gt 0)
{
    throw "Working tree is not clean. Commit or stash changes before releasing."
}

# Determine current version
$pkg = Get-Content -LiteralPath "package.json" -Raw | ConvertFrom-Json
if (-not $pkg.version)
{
    throw "package.json has no version field."
}

$currentVersion = [string]$pkg.version

if ($SetVersion)
{
    $null = Parse-SemVer -Version $SetVersion
    $newVersion = $SetVersion
}
elseif ($Bump)
{
    $sem = Parse-SemVer -Version $currentVersion
    switch ($Bump)
    {
        "patch" { $newVersion = Format-SemVer -Major $sem.Major -Minor $sem.Minor -Patch ($sem.Patch + 1) }
        "minor" { $newVersion = Format-SemVer -Major $sem.Major -Minor ($sem.Minor + 1) -Patch 0 }
        "major" { $newVersion = Format-SemVer -Major ($sem.Major + 1) -Minor 0 -Patch 0 }
        default { throw "Unexpected bump type: $Bump" }
    }
}
else
{
    $newVersion = $currentVersion
}

if ($Bump -or $SetVersion)
{
    if ($newVersion -eq $currentVersion)
    {
        throw "New version is the same as current version ($currentVersion)."
    }

    Write-Host "Current version: $currentVersion"
    Write-Host "New version:     $newVersion"

    if ($PSCmdlet.ShouldProcess("package.json", "set version to $newVersion"))
    {
        Update-PackageJsonVersionInPlace -Path "package.json" -NewVersion $newVersion
    }

    $msg = $CommitMessage
    if ([string]::IsNullOrWhiteSpace($msg))
    {
        $msg = "v$newVersion"
    }

    if ($PSCmdlet.ShouldProcess("package.json", "git add"))
    {
        Exec git add package.json | Out-Null
    }

    if ($PSCmdlet.ShouldProcess($msg, "git commit"))
    {
        Exec git commit -m $msg | Out-Null
    }

    $gitStatusAfterCommit = @(Exec git status --porcelain)
    if ($gitStatusAfterCommit.Count -gt 0)
    {
        throw "Working tree is not clean after committing version bump."
    }
}

$version = $newVersion
$tag = "v$version"

Write-Host "Version: $version"
Write-Host "Tag:     $tag"

# Ensure tag doesn't already exist locally
$existingLocalTag = @(Exec git tag -l $tag)
if ($existingLocalTag.Count -gt 0 -and -not $Force)
{
    throw "Tag '$tag' already exists locally. Use -Force to overwrite (not recommended)."
}

# Ensure tag doesn't already exist on remote
$existingRemote = @(Exec git ls-remote --tags $Remote $tag)
if ($existingRemote.Count -gt 0 -and -not $Force)
{
    throw "Tag '$tag' already exists on remote '$Remote'. Refusing to continue."
}

if (-not $SkipBranchPush)
{
    if ($PSCmdlet.ShouldProcess("$Remote/$Branch", "git push"))
    {
        Exec git push $Remote $Branch | Out-Null
    }
}

if ($PSCmdlet.ShouldProcess($tag, "git tag"))
{
    if ($Force)
    {
        Exec git tag -f -a $tag -m $tag | Out-Null
    }
    else
    {
        Exec git tag -a $tag -m $tag | Out-Null
    }
}

if ($PSCmdlet.ShouldProcess("$Remote $tag", "git push"))
{
    if ($Force)
    {
        Exec git push -f $Remote $tag | Out-Null
    }
    else
    {
        Exec git push $Remote $tag | Out-Null
    }
}

Write-Host "Done. GitHub Actions should publish on tag push: $tag"
