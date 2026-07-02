$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bootstrap.ps1"

Install-GmodTools -Root (Split-Path -Parent $PSScriptRoot) -Wiki
