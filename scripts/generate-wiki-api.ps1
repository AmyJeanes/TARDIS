[CmdletBinding()]
param(
    [string] $WikiPath,
    [switch] $Check
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bootstrap.ps1"

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $WikiPath) { $WikiPath = Join-Path (Split-Path -Parent $RepoRoot) 'TARDIS.wiki' }

# Ordered: a non-root class is owned by the first category that reaches it, so
# the shared metadata structs home on Interior and the rest link in.
$Categories = @(
    @{ Title = 'Interior Reference';          File = 'Interior-Reference';          Roots = @('tardis_metadata') }
    @{ Title = 'Exterior Reference';          File = 'Exterior-Reference';          Roots = @('tardis_exterior_metadata') }
    @{ Title = 'Parts Reference';             File = 'Parts-Reference';             Roots = @('gmod_tardis_part') }
    @{ Title = 'Controls Reference';          File = 'Controls-Reference';          Roots = @('tardis_control') }
    @{ Title = 'Control Sequences Reference'; File = 'Control-Sequences-Reference'; Roots = @('tardis_sequence') }
    @{ Title = 'Settings Reference';          File = 'Settings-Reference';          Roots = @('tardis_setting') }
    @{ Title = 'Tips Reference';              File = 'Tips-Reference';              Roots = @('tardis_tip') }
    @{ Title = 'Icon Packs Reference';        File = 'Icon-Packs-Reference';        Roots = @('tardis_icon_pack') }
    @{ Title = 'GUI Themes Reference';        File = 'GUI-Themes-Reference';        Roots = @('tardis_gui_theme') }
    @{ Title = 'Screens Reference';           File = 'Screens-Reference';           Roots = @('tardis_screen_options') }
)

# Identity/plumbing fields whose base value is not an inherited default.
$IdentityFields = @{
    'tardis_metadata'  = @('ID', 'Name', 'Base', 'BaseMerged')
    'tardis_gui_theme' = @('id', 'name', 'folder')
}

# Base defaults, read straight from the headless-loaded registries. The engine
# hands us a loaded harness ($lua) + its metatable map ($meta).
$DefaultsProvider = {
    param($lua, $meta)
    $Table  = [MoonSharp.Interpreter.DataType]::Table
    $tardis = $lua.Globals.Get('TARDIS').Table

    $base = $tardis.Get('MetadataRaw').Table.Get('base')
    if ($base.Type -ne $Table) { throw 'base interior metadata not found' }

    $guiBase = $tardis.Get('gui_themes').Table.Get('base')

    return @{
        tardis_metadata          = ConvertFrom-LuaValue $base $meta
        tardis_exterior_metadata = ConvertFrom-LuaValue ($base.Table.Get('Exterior')) $meta
        tardis_gui_theme         = if ($guiBase.Type -eq $Table) { ConvertFrom-LuaValue $guiBase $meta } else { $null }
    }
}

Invoke-WikiGen `
    -Root $RepoRoot `
    -WikiPath $WikiPath `
    -Categories $Categories `
    -OwnedPrefix @('tardis_') `
    -DefaultsProvider $DefaultsProvider `
    -IdentityFields $IdentityFields `
    -Check:$Check
