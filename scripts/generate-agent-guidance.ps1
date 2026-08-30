# Regenerates the shared cross-addon conventions block in AGENTS.md from
# gmod-addon-tools/docs/gmod-addon-conventions.md. The block (between the HTML-comment
# markers) is generated; edit the shared source in the module, not here. CI:
# generate-agent-guidance.yml.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bootstrap.ps1"

Sync-AddonConventions -Root (Split-Path -Parent $PSScriptRoot)
