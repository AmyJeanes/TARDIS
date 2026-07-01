#!/usr/bin/env pwsh
# CLI smoke test for the headless content harness: loads the TARDIS addon's
# content-definition Lua outside the game engine and prints a census of what
# registered. The loading itself lives in harness.ps1, shared with the wiki
# generator (which reads the loaded metadata in-process). See that file for the
# MoonSharp-under-PowerShell design.

[CmdletBinding()]
param(
    # Which realm to emulate. 'server' includes sv_/sh_ and the noprefix content
    # folders (interiors/parts/controls); 'client' includes cl_/sh_.
    [ValidateSet('server', 'client')]
    [string] $Realm = 'server',

    # Addon root (defaults to this repo).
    [string] $AddonPath
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'harness.ps1')

try {
    $script = if ($AddonPath) { New-AddonHarness -Realm $Realm -AddonPath $AddonPath } else { New-AddonHarness -Realm $Realm }
} catch {
    Write-Host ''
    Write-Host "=== LOAD FAILED ($Realm) ===" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

Write-Host ''
Write-Host "=== LOAD OK ($Realm) ===" -ForegroundColor Green

# Census via the addon's own accessors, as a coverage signal. Parts and controls
# register into file-local tables, so go through the registry rather than TARDIS.*.
$census = $script.DoString(@'
local function count(t)
    local n = 0
    if type(t) == "table" then for _ in pairs(t) do n = n + 1 end end
    return n
end
local parts = 0
for name in pairs(__HARNESS.sents) do
    if string.sub(name, 1, 17) == "gmod_tardis_part_" then parts = parts + 1 end
end
return {
    interiors = count(TARDIS.MetadataRaw),
    exteriors = count(TARDIS.ExteriorsMetadataRaw),
    settings  = count(TARDIS.SettingsData),
    controls  = count(TARDIS:GetControls()),
    parts     = parts,
}
'@, $null, 'harness-census')

if ($census.Type -eq [MoonSharp.Interpreter.DataType]::Table) {
    foreach ($key in @('interiors', 'exteriors', 'parts', 'controls', 'settings')) {
        $v = $census.Table.Get($key)
        Write-Host ("  {0,-10} {1}" -f $key, [int]$v.Number)
    }
}

exit 0
