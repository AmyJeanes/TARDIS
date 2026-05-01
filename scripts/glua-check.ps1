#!/usr/bin/env pwsh
# Runs glua_check against the repo, installing the pinned tooling on demand.
#
# Local:  pwsh -File scripts/glua-check.ps1
#         pwsh -File scripts/glua-check.ps1 lua/tardis/parts
# CI:     pwsh -File scripts/glua-check.ps1 -Sarif results.sarif

param(
    [string]$Sarif,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'install-tools.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$Root    = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ExeName = if ($IsWindows -or ($null -eq $IsWindows -and $env:OS -eq 'Windows_NT')) { 'glua_check.exe' } else { 'glua_check' }
$GluaCheck = Join-Path $Root ".tools/bin/$ExeName"

# glua_check resolves .luarc.json relative to CWD, so run from repo root.
Push-Location $Root
try {
    $targets = if ($null -eq $Paths -or $Paths.Count -eq 0) { @('.') } else { $Paths }
    $sarifArgs = if ($Sarif) { @('-f', 'sarif', '--output', $Sarif) } else { @() }
    & $GluaCheck --warnings-as-errors @sarifArgs @targets
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
