$AddonRoot = Split-Path -Parent $PSScriptRoot
$Tools     = Join-Path (Split-Path -Parent $AddonRoot) 'gmod-addon-tools'
$Manifest  = Join-Path $Tools 'GmodAddonTools.psd1'

if (-not (Test-Path $Manifest)) {
    throw @"
gmod-addon-tools is not installed next to this addon (expected at: $Tools).
It provides the shared build tooling this script needs.

To fix, clone it beside this addon and re-run:
    git clone https://github.com/AmyJeanes/gmod-addon-tools "$Tools"
"@
}

Import-Module $Manifest -Force
