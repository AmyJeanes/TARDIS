#!/usr/bin/env pwsh
# Runs the typing-enforcement gate against the repo: fails on any untyped function
# param (a silent `any` glua_check never reports) or annotation rot (STALE/DUP/OVER).
# Installs the pinned tooling on demand, same as glua-check.ps1.
#
# Local:  pwsh -File scripts/typing-check.ps1
# CI:     same

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bootstrap.ps1"

& (Join-Path $PSScriptRoot 'install-tools.ps1')

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$result = Test-GmodTyping -RepoRoot $Root
if (-not $result.Ok) { exit 1 }
exit 0
