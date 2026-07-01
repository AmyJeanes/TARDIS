#!/usr/bin/env pwsh
# Shared library for loading the TARDIS addon's content Lua under MoonSharp.
#
# Dot-source it. Both run-harness.ps1 (the CLI smoke test) and generate-wiki-api.ps1
# (which reads metadata defaults) build on New-AddonHarness, so the engine setup
# lives in one place and callers work with the live interpreter in-process - no
# subprocess, temp file, or hand-rolled JSON between them.

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

# Load the addon's content-definition Lua and return the live MoonSharp Script.
# Throws (with the interpreter's decorated message) if the addon fails to load.
function New-AddonHarness {
    [CmdletBinding()]
    param(
        # 'server' includes sv_/sh_ and the noprefix content folders; 'client' cl_/sh_.
        [ValidateSet('server', 'client')]
        [string] $Realm = 'server',
        # Addon root (defaults to this repo). Its lua/ dir is the "LUA" search path.
        [string] $AddonPath
    )

    $ErrorActionPreference = 'Stop'

    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    if (-not $AddonPath) { $AddonPath = $repoRoot }
    $luaRoot = (Resolve-Path (Join-Path $AddonPath 'lua')).Path
    # Prelude pieces, loaded in this order. Cross-file references all resolve at
    # call time, so the order is for readability rather than correctness.
    $preludeFiles = @('gmod-stubs.lua', 'gmod-types.lua', 'gmod-string.lua', 'gmod-table.lua', 'gmod-math.lua')

    $dll = Join-Path $repoRoot '.tools/bin/MoonSharp.Interpreter.dll'
    if (-not (Test-Path $dll)) {
        Write-Host 'MoonSharp not found; running install-tools.ps1...'
        & (Join-Path $repoRoot 'scripts/install-tools.ps1') | Out-Null
    }
    if (-not ('MoonSharp.Interpreter.Script' -as [type])) { Add-Type -Path $dll }

    $lua = New-Object MoonSharp.Interpreter.Script

    # --- CLR bridge --------------------------------------------------------
    # The interpreter has no filesystem; these three callbacks are the only
    # window onto the host. gmod-stubs.lua builds file.Find/include/print on them.
    $DataType = [MoonSharp.Interpreter.DataType]
    $DynValue = [MoonSharp.Interpreter.DynValue]

    # __host_findfiles(pattern, pathid, kind) -> newline-joined names. Only the
    # "LUA" path id is mounted (the addon's lua/ dir). kind 'd' lists dirs.
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

        $full = if ($dir) { Join-Path $luaRoot $dir } else { $luaRoot }
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
        $path = Join-Path $luaRoot ($rel -replace '\\', '/')
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

    $lua.Globals['__host_findfiles'] = $DynValue::NewCallback($findCb)
    $lua.Globals['__host_readfile']  = $DynValue::NewCallback($readCb)
    $lua.Globals['__host_print']     = $DynValue::NewCallback($printCb)

    # Realm flags the stub env and LoadFolder gate on.
    $lua.Globals['SERVER'] = ($Realm -eq 'server')
    $lua.Globals['CLIENT'] = ($Realm -eq 'client')

    # --- run ---------------------------------------------------------------

    foreach ($pf in $preludeFiles) {
        $code = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot $pf))
        $lua.DoString($code, $null, $pf) | Out-Null
    }

    # GMod engine enums (MASK_*, CONTENTS_*, COLLISION_GROUP_*, ...) come from the
    # glua-api stub dump, which assigns the real numeric values. Loading it gives
    # the addon correct enum constants instead of nil, so bit ops and comparisons
    # behave. Provisioned by install-tools.ps1 alongside MoonSharp.
    $enumsPath = Join-Path $repoRoot '.tools/glua-api/enums.lua'
    if (Test-Path $enumsPath) {
        $lua.DoString([System.IO.File]::ReadAllText($enumsPath), $null, 'glua-api/enums.lua') | Out-Null
    } else {
        Write-Host "warning: $enumsPath not found - engine enums will be nil" -ForegroundColor Yellow
    }

    $entry = [System.IO.File]::ReadAllText((Join-Path $luaRoot 'autorun/tardis.lua'))
    try {
        $lua.DoString($entry, $null, 'autorun/tardis.lua') | Out-Null
    } catch {
        throw (Unwrap-InterpreterError $_)
    }

    return $lua
}

# The Vector/Angle/Color/Material metatables, by identity. ConvertFrom-LuaValue
# uses these to tell those recorded values apart (their permissive __index breaks
# duck-typing). $script is a loaded New-AddonHarness result.
function Get-HarnessMeta($script) {
    $meta = $script.Globals.Get('__HARNESS').Table.Get('meta').Table
    return @{
        vector   = $meta.Get('vector').Table
        angle    = $meta.Get('angle').Table
        color    = $meta.Get('color').Table
        material = $meta.Get('material').Table
    }
}

# C-printf %g for the clean designer-entered numbers in metadata (no scientific
# notation, trailing zeros trimmed) so literals read like the source.
function Format-LuaNum([double]$n) { return ('{0:0.######}' -f $n) }

function New-LuaLiteral([string]$text) { return [pscustomobject]@{ __type = 'literal'; text = $text } }

# Walk a MoonSharp DynValue into plain PowerShell. Vector/Angle/Color/Material
# (by metatable identity) become {__type='literal'; text='Vector(...)'} so a
# caller renders them verbatim; sequences become arrays; other tables become
# PSCustomObjects (string keys, sorted); functions and nil are dropped.
function ConvertFrom-LuaValue($dv, $meta) {
    $T = [MoonSharp.Interpreter.DataType]
    if ($dv.Type -eq $T::Number)  { return $dv.Number }
    if ($dv.Type -eq $T::String)  { return $dv.String }
    if ($dv.Type -eq $T::Boolean) { return $dv.Boolean }
    if ($dv.Type -ne $T::Table)   { return $null }

    $tbl = $dv.Table
    $mt = $tbl.MetaTable
    if ($mt) {
        if ([object]::ReferenceEquals($mt, $meta.vector)) {
            return (New-LuaLiteral ('Vector({0}, {1}, {2})' -f (Format-LuaNum $tbl.Get('x').Number), (Format-LuaNum $tbl.Get('y').Number), (Format-LuaNum $tbl.Get('z').Number)))
        }
        if ([object]::ReferenceEquals($mt, $meta.angle)) {
            return (New-LuaLiteral ('Angle({0}, {1}, {2})' -f (Format-LuaNum $tbl.Get('p').Number), (Format-LuaNum $tbl.Get('y').Number), (Format-LuaNum $tbl.Get('r').Number)))
        }
        if ([object]::ReferenceEquals($mt, $meta.color)) {
            $a = $tbl.Get('a').Number
            if ($a -ne 255) {
                return (New-LuaLiteral ('Color({0}, {1}, {2}, {3})' -f (Format-LuaNum $tbl.Get('r').Number), (Format-LuaNum $tbl.Get('g').Number), (Format-LuaNum $tbl.Get('b').Number), (Format-LuaNum $a)))
            }
            return (New-LuaLiteral ('Color({0}, {1}, {2})' -f (Format-LuaNum $tbl.Get('r').Number), (Format-LuaNum $tbl.Get('g').Number), (Format-LuaNum $tbl.Get('b').Number)))
        }
        if ([object]::ReferenceEquals($mt, $meta.material)) {
            return (New-LuaLiteral ('Material("{0}")' -f $tbl.Get('__name').String))
        }
    }

    $len = $tbl.Length
    $pairs = @($tbl.Pairs)
    if ($len -gt 0 -and $pairs.Count -eq $len) {
        $arr = for ($i = 1; $i -le $len; $i++) { ConvertFrom-LuaValue $tbl.Get($i) $meta }
        return , @($arr)
    }

    $props = [ordered]@{}
    $strKeys = $pairs | Where-Object { $_.Key.Type -eq $T::String } | Sort-Object { $_.Key.String }
    foreach ($p in $strKeys) {
        $v = ConvertFrom-LuaValue $p.Value $meta
        if ($null -ne $v) { $props[$p.Key.String] = $v }
    }
    return [pscustomobject]$props
}
