# Regenerates the AddHook ---@overload catalogue in each entity's shared.lua from the
# addon's CallHook sites, so hook callbacks type their payload params without a manual
# ---@param. Auto-generated block. CI: generate-hook-types.yml.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bootstrap.ps1"

Build-HookTypeCatalogue -Root (Split-Path -Parent $PSScriptRoot)
