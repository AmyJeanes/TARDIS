#!/usr/bin/env pwsh
# Headless loader for the TARDIS addon's content-definition Lua.
#
# Garry's Mod content (interiors, exteriors, parts, controls, ...) is plain Lua
# that registers itself by calling TARDIS:AddInterior / AddPart / ... at file
# load time. This script runs that Lua outside the game engine: MoonSharp (a
# pure-C# Lua interpreter, loaded straight into PowerShell's .NET runtime)
# executes it against the GMod stub environment in gmod-stubs.lua. The registered
# tables then live in the interpreter's globals (TARDIS.*) for a caller to read.
#
# This first cut just proves the addon loads without crashing; extraction of the
# captured data is layered on top later.

[CmdletBinding()]
param(
    # Which realm to emulate. 'server' includes sv_/sh_ and the noprefix content
    # folders (interiors/parts/controls); 'client' includes cl_/sh_.
    [ValidateSet('server', 'client')]
    [string] $Realm = 'server',

    # Addon root (defaults to this repo). Its lua/ dir is mounted as the "LUA"
    # search path that include() and file.Find(..., "LUA") resolve against.
    [string] $AddonPath
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $AddonPath) { $AddonPath = $RepoRoot }
$LuaRoot      = (Resolve-Path (Join-Path $AddonPath 'lua')).Path
# Prelude pieces, loaded in this order. Cross-file references all resolve at
# call time, so the order is for readability rather than correctness.
$PreludeFiles = @('gmod-stubs.lua', 'gmod-types.lua', 'gmod-string.lua', 'gmod-table.lua', 'gmod-math.lua')

$dll = Join-Path $RepoRoot '.tools/bin/MoonSharp.Interpreter.dll'
if (-not (Test-Path $dll)) {
    Write-Host 'MoonSharp not found; running install-tools.ps1...'
    & (Join-Path $RepoRoot 'scripts/install-tools.ps1') | Out-Null
}
Add-Type -Path $dll

$script = New-Object MoonSharp.Interpreter.Script

# --- CLR bridge ------------------------------------------------------------
# The interpreter has no filesystem; these three callbacks are the only window
# onto the host. gmod-stubs.lua builds file.Find/include/print on top of them.

$DataType = [MoonSharp.Interpreter.DataType]
$DynValue = [MoonSharp.Interpreter.DynValue]

# __host_findfiles(pattern, pathid, kind) -> newline-joined names.
# Only the "LUA" path id is mounted (the addon's lua/ dir); everything else
# returns empty. kind 'd' lists subdirectories, anything else lists files.
$findCb = {
    param($ctx, $cargs)
    $pattern = $cargs[0].String
    $pathid  = if ($cargs.Count -gt 1 -and $cargs[1].Type -eq $DataType::String) { $cargs[1].String } else { 'GAME' }
    $kind    = if ($cargs.Count -gt 2 -and $cargs[2].Type -eq $DataType::String) { $cargs[2].String } else { 'f' }
    if ($pathid -ne 'LUA') { return $DynValue::NewString('') }

    $rel   = $pattern -replace '\\', '/'
    $slash = $rel.LastIndexOf('/')
    if ($slash -ge 0) { $dir = $rel.Substring(0, $slash); $mask = $rel.Substring($slash + 1) }
    else { $dir = ''; $mask = $rel }
    if ($mask -eq '') { $mask = '*' }

    $full = if ($dir) { Join-Path $LuaRoot $dir } else { $LuaRoot }
    if (-not (Test-Path $full)) { return $DynValue::NewString('') }

    $names = if ($kind -eq 'd') {
        [System.IO.Directory]::EnumerateDirectories($full, $mask)
    } else {
        [System.IO.Directory]::EnumerateFiles($full, $mask)
    }
    # GMod file.Find defaults to "nameasc". Sort ordinal (not culture-sensitive)
    # so the iteration order is identical on Windows and the Linux CI runner.
    $leaves = [string[]]@(foreach ($p in $names) { Split-Path $p -Leaf })
    [Array]::Sort($leaves, [System.StringComparer]::Ordinal)
    return $DynValue::NewString(($leaves -join "`n"))
}.GetNewClosure()

# __host_readfile(relPath, pathid) -> file text or nil. Defaults to "LUA" so
# include() can call it with just a path.
$readCb = {
    param($ctx, $cargs)
    $rel    = $cargs[0].String
    $pathid = if ($cargs.Count -gt 1 -and $cargs[1].Type -eq $DataType::String) { $cargs[1].String } else { 'LUA' }
    if ($pathid -ne 'LUA') { return $DynValue::Nil }
    $path = Join-Path $LuaRoot ($rel -replace '\\', '/')
    if (-not (Test-Path $path)) { return $DynValue::Nil }
    return $DynValue::NewString([System.IO.File]::ReadAllText($path))
}.GetNewClosure()

# __host_print(...) -> mirror addon Msg/print to the host console.
$printCb = {
    param($ctx, $cargs)
    $parts = for ($i = 0; $i -lt $cargs.Count; $i++) { $cargs[$i].ToPrintString() }
    Write-Host ('[lua] ' + ($parts -join "`t"))
    return $DynValue::Nil
}.GetNewClosure()

$script.Globals['__host_findfiles'] = $DynValue::NewCallback($findCb)
$script.Globals['__host_readfile']  = $DynValue::NewCallback($readCb)
$script.Globals['__host_print']     = $DynValue::NewCallback($printCb)

# Realm flags the stub env and LoadFolder gate on.
$script.Globals['SERVER'] = ($Realm -eq 'server')
$script.Globals['CLIENT'] = ($Realm -eq 'client')

# --- run -------------------------------------------------------------------

function Unwrap-InterpreterError($err) {
    # PowerShell may wrap the MoonSharp exception; dig out DecoratedMessage.
    $ex = $err.Exception
    while ($ex) {
        $dm = $ex.PSObject.Properties['DecoratedMessage']
        if ($dm -and $dm.Value) { return $dm.Value }
        $ex = $ex.InnerException
    }
    return $err.Exception.Message
}

foreach ($pf in $PreludeFiles) {
    $code = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot $pf))
    $script.DoString($code, $null, $pf) | Out-Null
}

# GMod engine enums (MASK_*, CONTENTS_*, COLLISION_GROUP_*, ...) come from the
# glua-api stub dump, which assigns the real numeric values. Loading it gives
# the addon correct enum constants instead of nil, so bit ops and comparisons
# behave. Provisioned by install-tools.ps1 alongside MoonSharp.
$enumsPath = Join-Path $RepoRoot '.tools/glua-api/enums.lua'
if (Test-Path $enumsPath) {
    $script.DoString([System.IO.File]::ReadAllText($enumsPath), $null, 'glua-api/enums.lua') | Out-Null
} else {
    Write-Host "warning: $enumsPath not found - engine enums will be nil" -ForegroundColor Yellow
}

$entry = [System.IO.File]::ReadAllText((Join-Path $LuaRoot 'autorun/tardis.lua'))
try {
    $script.DoString($entry, $null, 'autorun/tardis.lua') | Out-Null
} catch {
    Write-Host ''
    Write-Host "=== LOAD FAILED ($Realm) ===" -ForegroundColor Red
    Write-Host (Unwrap-InterpreterError $_)
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

if ($census.Type -eq $DataType::Table) {
    foreach ($key in @('interiors', 'exteriors', 'parts', 'controls', 'settings')) {
        $v = $census.Table.Get($key)
        Write-Host ("  {0,-10} {1}" -f $key, [int]$v.Number)
    }
}

exit 0
