#!/usr/bin/env pwsh
# Runs glua_check against the repo, installing the pinned tooling on demand.
#
# Local:  pwsh -File scripts/glua-check.ps1
# CI:     pwsh -File scripts/glua-check.ps1 -Sarif results.sarif

[CmdletBinding()]
param(
    [string]$Sarif
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bootstrap.ps1"

& (Join-Path $PSScriptRoot 'install-tools.ps1')

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
exit (Invoke-GluaCheck -RepoRoot $Root -Sarif $Sarif)
