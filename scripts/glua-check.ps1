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

& (Join-Path $PSScriptRoot 'install-tools.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$Root    = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ExeName = if ($IsWindows -or ($null -eq $IsWindows -and $env:OS -eq 'Windows_NT')) { 'glua_check.exe' } else { 'glua_check' }
$GluaCheck = Join-Path $Root ".tools/bin/$ExeName"

Push-Location $Root
try {
    & $GluaCheck --warnings-as-errors .
    $exitCode = $LASTEXITCODE

    if ($Sarif) {
        & $GluaCheck --warnings-as-errors -f sarif --output $Sarif . 2>$null
    }

    exit $exitCode
} finally {
    Pop-Location
}
