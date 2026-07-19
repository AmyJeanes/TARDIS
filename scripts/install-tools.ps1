$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bootstrap.ps1"

Initialize-GmodTools -Root (Split-Path -Parent $PSScriptRoot) -Wiki

# Not committed (it records the commit sha), so a fresh clone has none until this runs.
& "$PSScriptRoot/generate-version.ps1"
