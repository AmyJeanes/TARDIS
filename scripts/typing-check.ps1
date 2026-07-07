#!/usr/bin/env pwsh

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bootstrap.ps1"

& (Join-Path $PSScriptRoot 'install-tools.ps1')

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$result = Test-GmodTyping -RepoRoot $Root
if (-not $result.Ok) { exit 1 }
exit 0
