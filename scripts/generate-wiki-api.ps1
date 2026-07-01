<#
.SYNOPSIS
    Generates the API type-reference wiki pages from the TARDIS source annotations.

.DESCRIPTION
    Runs emmylua_doc_cli (the same EmmyLua engine as glua_ls) over the source to
    parse the ---@class / ---@field annotations on the extension content-authoring
    definition tables (interiors, exteriors, parts, controls, sequences, settings,
    tips, icon packs, GUI themes, screens) into a JSON type model, then emits one
    markdown page per category into the TARDIS.wiki repo. The pages are a pure
    projection of the source annotations - including the trailing description text
    on each ---@field - so they stay in sync once the descriptions pass lands.
    Field types are rendered exactly as the analyzer resolves them, so they match
    editor hover. Re-run to update.

    These pages complement, not replace, the hand-written tutorial pages. The
    "Create with TARDIS:NewX()" note lives in each page's hand-written intro.

.PARAMETER WikiPath
    Path to the TARDIS.wiki clone. Defaults to the sibling ../TARDIS.wiki.

.PARAMETER Check
    Parse and report only; do not write any files. Useful for CI / dry runs.
#>
[CmdletBinding()]
param(
    [string]$WikiPath,
    [switch]$Check
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$LuaRoot  = Join-Path $RepoRoot "lua"

. (Join-Path $PSScriptRoot "lua-harness/harness.ps1")

if (-not $WikiPath) {
    $WikiPath = Join-Path (Split-Path -Parent $RepoRoot) "TARDIS.wiki"
}

# --- Category manifest -------------------------------------------------------
# Ordered: a non-root class is "owned" (inlined) by the first category that
# reaches it; later references link to that page. Roots are pinned to their own
# category, so e.g. the Interior page links to the Exterior page rather than
# inlining the whole exterior tree. Put the broadest category (Interiors) first
# so the shared metadata structs live there and the others link in.
# Each category becomes one wiki page. The page intro above the generated markers
# is hand-written and preserved; only the type tables between the markers are
# generated here.
$Categories = @(
    @{ Title = "Interior Reference";          File = "Interior-Reference";          Roots = @("tardis_metadata") }
    @{ Title = "Exterior Reference";          File = "Exterior-Reference";          Roots = @("tardis_exterior_metadata") }
    @{ Title = "Parts Reference";             File = "Parts-Reference";             Roots = @("gmod_tardis_part") }
    @{ Title = "Controls Reference";          File = "Controls-Reference";          Roots = @("tardis_control") }
    @{ Title = "Control Sequences Reference"; File = "Control-Sequences-Reference"; Roots = @("tardis_sequence") }
    @{ Title = "Settings Reference";          File = "Settings-Reference";          Roots = @("tardis_setting") }
    @{ Title = "Tips Reference";              File = "Tips-Reference";              Roots = @("tardis_tip") }
    @{ Title = "Icon Packs Reference";        File = "Icon-Packs-Reference";        Roots = @("tardis_icon_pack") }
    @{ Title = "GUI Themes Reference";        File = "GUI-Themes-Reference";        Roots = @("tardis_gui_theme") }
    @{ Title = "Screens Reference";           File = "Screens-Reference";           Roots = @("tardis_screen_options") }
)

# --- Annotation parser (emmylua_doc_cli) -------------------------------------
# The ---@class / ---@field type model is produced by emmylua_doc_cli, so the
# wiki types are exactly what the analyzer resolves (matching editor hover) and
# there is no hand-rolled type parsing here - we just post-process its JSON into
# the small shape the renderer consumes.

function Resolve-DocCli {
    $exe = if ($IsWindows -or ($null -eq $IsWindows -and $env:OS -eq 'Windows_NT')) { 'emmylua_doc_cli.exe' } else { 'emmylua_doc_cli' }
    $path = Join-Path $RepoRoot ".tools/bin/$exe"
    if (-not (Test-Path $path)) {
        throw "emmylua_doc_cli not found at $path - run scripts/install-tools.ps1 first."
    }
    return $path
}

# Parse every annotation via emmylua_doc_cli, returning:
#   Classes : ordered hashtable name -> @{ Name; Parent; Blurb; Fields = @(@{Name;Type;Optional;Desc}) }
function Parse-Annotations([string]$root) {
    $docCli = Resolve-DocCli

    # emmylua_doc_cli requires the JSON output path to end in .json (a .tmp path errors).
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("tardis-wiki-api-" + [guid]::NewGuid().ToString('N') + ".json")
    try {
        & $docCli $root -f json -o $tmp --exclude '**/gmod_wire_expression2/**' | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "emmylua_doc_cli failed (exit $LASTEXITCODE)." }
        $doc = (Get-Content -LiteralPath $tmp -Raw -Encoding utf8) | ConvertFrom-Json
    } finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }

    $classes = [ordered]@{}
    foreach ($t in $doc.types) {
        if ($t.type -ne 'class') { continue }
        $name = $t.name
        if ($classes.Contains($name)) { continue }   # emmylua already merges same-name decls

        $parent = if ($t.bases -and $t.bases.Count -gt 0) { $t.bases -join ', ' } else { $null }
        $blurb  = if ($t.description) { ($t.description -replace '\r?\n', ' ').Trim() } else { $null }
        if (-not $blurb) { $blurb = $null }

        $fields = @()
        foreach ($m in $t.members) {
            if ($m.type -ne 'field') { continue }
            $fname = $m.name
            $ftype = if ($m.typ) { $m.typ } else { '' }
            # emmylua encodes optionality as a trailing '?'; index signatures ([k]) are always optional.
            $optional = $ftype.EndsWith('?') -or $fname.StartsWith('[')
            $desc = if ($m.description) { ($m.description -replace '\r?\n', ' ').Trim() } else { '' }
            $fields += @{ Name = $fname; Type = $ftype; Optional = $optional; Desc = $desc }
        }

        $classes[$name] = @{ Name = $name; Parent = $parent; Blurb = $blurb; Fields = $fields }
    }

    return @{ Classes = $classes }
}

# --- Base defaults (from the headless harness) -------------------------------
# The "Default" column shows the value a content author inherits when they omit
# a field. Those defaults are assigned in Lua at load time (base.lua), invisible
# to the static analyzer, so we load the addon headless in-process (see
# lua-harness/harness.ps1) and walk base's interior/exterior metadata straight
# out of the interpreter. Vector/Angle/Color become {__type='literal'} markers,
# rendered verbatim.

function Get-BaseDefaults {
    $lua    = New-AddonHarness -Realm server   # loads MoonSharp before the type ref below
    $meta   = Get-HarnessMeta $lua
    $tardis = $lua.Globals.Get('TARDIS').Table
    $Table  = [MoonSharp.Interpreter.DataType]::Table

    $base = $tardis.Get('MetadataRaw').Table.Get('base')
    if ($base.Type -ne $Table) { throw "base interior metadata not found" }

    # The "base" GUI theme is the root every visgui theme inherits from via base_id.
    $guiBase    = $tardis.Get('gui_themes').Table.Get('base')
    $guiDefault = if ($guiBase.Type -eq $Table) { ConvertFrom-LuaValue $guiBase $meta } else { $null }

    return [pscustomobject]@{
        tardis_metadata          = ConvertFrom-LuaValue $base $meta
        tardis_exterior_metadata = ConvertFrom-LuaValue ($base.Table.Get('Exterior')) $meta
        tardis_gui_theme         = $guiDefault
    }
}

function Test-JsonObject($v) { return $v -is [System.Management.Automation.PSCustomObject] }
function Test-LiteralDefault($v) { return (Test-JsonObject $v) -and ($null -ne $v.PSObject.Properties['__type']) }
function Test-PlainObject($v) { return (Test-JsonObject $v) -and (-not (Test-LiteralDefault $v)) }
function Test-StrongDefault($v) { return (Test-PlainObject $v) -and (($v.PSObject.Properties | Measure-Object).Count -gt 0) }

# The default subtree for a field's class - only a plain nested object (a struct
# we expand as its own class) qualifies; scalars/literals/arrays don't recurse.
function Get-ChildDefault($parentSub, [string]$field) {
    if ($null -eq $parentSub) { return $null }
    $p = $parentSub.PSObject.Properties[$field]
    if ($p -and (Test-PlainObject $p.Value)) { return $p.Value }
    return $null
}

# A class is shared across pages (tardis_portal in both Interior and Exterior),
# so record the first non-empty subtree it is reached by - an empty {} (e.g. the
# interior's blank Sounds.Teleport) yields to a populated one.
function Set-DefaultsFor([hashtable]$map, [string]$name, $sub) {
    if ($null -eq $sub) { return }
    if (-not $map.ContainsKey($name)) { $map[$name] = $sub; return }
    if ((-not (Test-StrongDefault $map[$name])) -and (Test-StrongDefault $sub)) { $map[$name] = $sub }
}

# Identity/plumbing fields whose base value (base is itself the "base" interior /
# the "base" GUI theme) is not a default a child inherits - excluded so they read
# as Required instead. For gui themes, folder is rewritten per-theme at load time,
# so base's own path is not a meaningful default either.
$IdentityFields = @{
    'tardis_metadata'  = @('ID', 'Name', 'Base', 'BaseMerged')
    'tardis_gui_theme' = @('id', 'name', 'folder')
}

function Get-FieldDefault([hashtable]$map, [string]$class, [string]$field) {
    $ex = $IdentityFields[$class]
    if ($ex -and ($ex -contains $field)) { return @{ Has = $false } }
    $sub = $map[$class]
    if ($null -eq $sub) { return @{ Has = $false } }
    $p = $sub.PSObject.Properties[$field]
    if (-not $p -or $null -eq $p.Value) { return @{ Has = $false } }
    return @{ Has = $true; Value = $p.Value }
}

# --- Ownership ---------------------------------------------------------------

$parsed  = Parse-Annotations $LuaRoot
$classes = $parsed.Classes

$defaults    = Get-BaseDefaults
$defaultsFor = @{}   # className -> default subtree (a parsed-JSON object)

$rootSet = @{}
foreach ($cat in $Categories) { foreach ($r in $cat.Roots) { $rootSet[$r] = $true } }

function Is-Documentable([string]$name) {
    return $classes.Contains($name) -and ($name.StartsWith('tardis_') -or $rootSet.ContainsKey($name))
}

# In-scope class names referenced by a type string.
function Get-Refs([string]$type) {
    $refs = @()
    foreach ($m in [regex]::Matches($type, '[A-Za-z_][A-Za-z0-9_]*')) {
        $n = $m.Value
        if ((Is-Documentable $n) -and ($refs -notcontains $n)) { $refs += $n }
    }
    return $refs
}

$owner    = @{}   # className -> category File
$pageList = @{}   # category File -> ordered class names to render

# Pin every root to its category up front so cross-category refs become links.
foreach ($cat in $Categories) {
    $pageList[$cat.File] = New-Object System.Collections.Generic.List[string]
    foreach ($r in $cat.Roots) {
        if (-not $classes.Contains($r)) { Write-Warning "Root class '$r' not found in source"; continue }
        $owner[$r] = $cat.File
        [void]$pageList[$cat.File].Add($r)
        $rootDefault = $defaults.PSObject.Properties[$r]
        if ($rootDefault) { Set-DefaultsFor $defaultsFor $r $rootDefault.Value }
    }
}

foreach ($cat in $Categories) {
    $page = $cat.File
    $queue = New-Object System.Collections.Generic.Queue[string]
    $seen  = @{}
    foreach ($r in $cat.Roots) { if ($classes.Contains($r)) { $queue.Enqueue($r); $seen[$r] = $true } }

    while ($queue.Count -gt 0) {
        $cname = $queue.Dequeue()
        $parentSub = $defaultsFor[$cname]
        foreach ($f in $classes[$cname].Fields) {
            $childSub = Get-ChildDefault $parentSub $f.Name
            foreach ($ref in (Get-Refs $f.Type)) {
                # Record defaults even for already-owned refs so a class the
                # interior reached empty can be filled from the exterior.
                Set-DefaultsFor $defaultsFor $ref $childSub
                if ($owner.ContainsKey($ref)) { continue }  # owned elsewhere -> will link
                $owner[$ref] = $page
                [void]$pageList[$page].Add($ref)
                if (-not $seen.ContainsKey($ref)) { $queue.Enqueue($ref); $seen[$ref] = $true }
            }
        }
    }
}

# Reverse of the type links: for each class, the rendered classes that reference
# it through a field (a "Used in" backlink). Built in page order for stable
# output; self-references are skipped (the field is already in the class table).
$usedBy = @{}
foreach ($cat in $Categories) {
    foreach ($cname in $pageList[$cat.File]) {
        foreach ($f in $classes[$cname].Fields) {
            foreach ($ref in (Get-Refs $f.Type)) {
                if ($ref -eq $cname -or -not $owner.ContainsKey($ref)) { continue }
                if (-not $usedBy.ContainsKey($ref)) { $usedBy[$ref] = New-Object System.Collections.Generic.List[string] }
                if (-not $usedBy[$ref].Contains($cname)) { [void]$usedBy[$ref].Add($cname) }
            }
        }
    }
}

# --- Rendering ---------------------------------------------------------------

function Get-Anchor([string]$name) { return $name.ToLower() }

# The anchor GitHub derives for a field's "#### `<field>` default" expansion heading
# (backticks dropped, lowercased, spaces to hyphens), used to link the summary cell.
function Get-DefaultAnchor([string]$fieldName) { return $fieldName.ToLower() + '-default' }

function Format-Cell([string]$s) {
    if (-not $s) { return "" }
    return $s.Replace('|', '\|')
}

# Link a documentable class name to its section (same page -> bare anchor).
function Get-ClassLink([string]$name, [string]$label, [string]$thisPage) {
    if ((Is-Documentable $name) -and $owner.ContainsKey($name)) {
        $anchor = Get-Anchor $name
        $target = if ($owner[$name] -eq $thisPage) { "#$anchor" } else { "$($owner[$name])#$anchor" }
        return "[$label]($target)"
    }
    return $label
}

# Render the Default cell for a field. Scalars and Vector/Angle/Color literals
# show their value; a field that holds a sub-table shows `{...}` (linked to the
# nested type when documented) and a list shows `[...]`; anything base doesn't
# set shows "-", so every cell is populated.
function Render-DefaultCell($default, $f, [string]$thisPage) {
    if (-not $default.Has) { return "-" }
    $value = $default.Value
    if ($value -is [bool]) { return "``" + ($value.ToString().ToLower()) + "``" }
    if ($value -is [string]) { return "``" + (Format-Cell ('"' + $value + '"')) + "``" }
    if ($value -is [ValueType]) { return "``$value``" }   # numbers
    if (Test-LiteralDefault $value) { return "``" + (Format-Cell $value.text) + "``" }

    # A non-documented table/list is summarised here and expanded below the table;
    # link the `{...}` / `[...]` summary down to that expansion.
    if ($null -ne (Get-ExpandableDefault $default $f)) {
        $label = if ($value -is [Array]) { '`[...]`' } else { '`{...}`' }
        return "[$label](#$(Get-DefaultAnchor $f.Name))"
    }

    if ($value -is [Array]) {
        if ($value.Count -eq 0) { return "``[]``" }
        # A pure-number array (a sequence) is shown inline.
        if ((@($value | Where-Object { $_ -isnot [ValueType] }).Count) -eq 0) {
            return "``[" + ($value -join ', ') + "]``"
        }
        return "``[...]``"
    }
    if (Test-PlainObject $value) {
        if ((@($value.PSObject.Properties).Count) -eq 0) { return "``{}``" }
        # A documented struct links to its own section.
        return Get-ClassLink ($f.Type.TrimEnd('?')) '`{...}`' $thisPage
    }
    return "-"
}

# Pretty-print a captured default as a Lua table literal for the expansion blocks
# under the field table. Scalars and Vector/Angle/Color literals render inline;
# tables recurse with 4-space indent so a `{...}` cell can be shown whole.
function Format-LuaScalar($v) {
    if ($v -is [bool])      { return $v.ToString().ToLower() }
    if ($v -is [string])    { return '"' + ($v -replace '\\', '\\' -replace '"', '\"') + '"' }
    if ($v -is [ValueType]) { return (Format-LuaNum ([double]$v)) }
    if (Test-LiteralDefault $v) { return $v.text }
    return $null
}

function Format-LuaLiteral($v, [int]$depth) {
    $scalar = Format-LuaScalar $v
    if ($null -ne $scalar) { return $scalar }
    $pad  = '    ' * $depth
    $pad1 = '    ' * ($depth + 1)
    if ($v -is [Array]) {
        if ($v.Count -eq 0) { return '{}' }
        $lines = foreach ($item in $v) { $pad1 + (Format-LuaLiteral $item ($depth + 1)) + ',' }
        return "{`n" + ($lines -join "`n") + "`n$pad}"
    }
    if (Test-PlainObject $v) {
        $props = @($v.PSObject.Properties)
        if ($props.Count -eq 0) { return '{}' }
        $lines = foreach ($p in ($props | Sort-Object Name)) {
            $key = if ($p.Name -match '^[A-Za-z_]\w*$') { $p.Name } else { '["' + $p.Name + '"]' }
            $pad1 + $key + ' = ' + (Format-LuaLiteral $p.Value ($depth + 1)) + ','
        }
        return "{`n" + ($lines -join "`n") + "`n$pad}"
    }
    return 'nil'
}

# The value to expand in full below the table, or $null if the Default cell already
# shows it whole. Only non-empty plain tables (not a documented struct, which links
# to its own section) and non-empty non-numeric lists qualify.
function Get-ExpandableDefault($default, $f) {
    if (-not $default.Has) { return $null }
    $v = $default.Value
    if (Test-LiteralDefault $v) { return $null }
    if ($v -is [Array]) {
        if ($v.Count -eq 0) { return $null }
        if ((@($v | Where-Object { $_ -isnot [ValueType] }).Count) -eq 0) { return $null }  # pure number list, shown inline
        return $v
    }
    if (Test-PlainObject $v) {
        if ((@($v.PSObject.Properties).Count) -eq 0) { return $null }
        if (Is-Documentable ($f.Type.TrimEnd('?'))) { return $null }
        return $v
    }
    return $null
}

# Render a type as a (possibly linked) code span. Links only when the whole type
# is a single documentable class; compound types render as a plain code span.
function Render-Type([string]$type, [string]$thisPage) {
    return Get-ClassLink ($type.TrimEnd('?')) ("``" + (Format-Cell $type) + "``") $thisPage
}

# The "Extends" note. A documented parent (another wiki class) is linked; an
# external parent (Entity) stays a plain code span.
function Render-Extends([string]$parents, [string]$thisPage) {
    $rendered = foreach ($p in ($parents -split ',\s*')) { Get-ClassLink $p "``$p``" $thisPage }
    return "Extends " + ($rendered -join ', ') + "."
}

# The "Used in" backlink - the classes that reference this one through a field.
function Render-UsedBy([string]$name, [string]$thisPage) {
    if (-not $usedBy.ContainsKey($name)) { return "" }
    $links = foreach ($o in $usedBy[$name]) { Get-ClassLink $o "``$o``" $thisPage }
    return "Used in " + ($links -join ', ') + "."
}

# The first parent that is a documented wiki class (so its fields can be shown
# inline), or $null - external parents like Entity don't qualify.
function Get-DocumentedParent($cls) {
    if (-not $cls.Parent) { return $null }
    foreach ($p in ($cls.Parent -split ',\s*')) {
        if ((Is-Documentable $p) -and $owner.ContainsKey($p)) { return $p }
    }
    return $null
}

$BeginMarker = '<!-- BEGIN GENERATED API REFERENCE -->'
$EndMarker   = '<!-- END GENERATED API REFERENCE -->'
$GenNote     = '<!-- Generated by scripts/generate-wiki-api.ps1 from the source ---@class / ---@field annotations. Do not edit between these markers; re-run the script to update. -->'

# A field is Required only when the type is non-optional AND base provides no
# default to fall back on (so e.g. ExitDistance, which base sets, is not).
function Test-FieldRequired($f, $default) {
    return (-not $f.Optional) -and (-not $default.Has)
}

# A field table. Defaults are looked up under $defaultClass - for inherited
# fields shown on a derived class, that is the derived class (an author sets them
# on its instance), so the default reflects the context they appear in.
function Render-FieldTable([string]$defaultClass, $fields, [string]$thisPage, [bool]$withDefault) {
    if ($fields.Count -eq 0) { return "" }
    $sb = New-Object System.Text.StringBuilder
    if ($withDefault) {
        [void]$sb.AppendLine("| Field | Type | Required | Default | Description |")
        [void]$sb.AppendLine("|-|-|-|-|-|")
    } else {
        [void]$sb.AppendLine("| Field | Type | Required | Description |")
        [void]$sb.AppendLine("|-|-|-|-|")
    }
    foreach ($f in $fields) {
        $default = Get-FieldDefault $defaultsFor $defaultClass $f.Name
        $req = if (Test-FieldRequired $f $default) { "Yes" } else { "No" }
        $typeCell = Render-Type $f.Type $thisPage
        if ($withDefault) {
            $defCell = Render-DefaultCell $default $f $thisPage
            [void]$sb.AppendLine("| ``$($f.Name)`` | $typeCell | $req | $defCell | $(Format-Cell $f.Desc) |")
        } else {
            [void]$sb.AppendLine("| ``$($f.Name)`` | $typeCell | $req | $(Format-Cell $f.Desc) |")
        }
    }
    return $sb.ToString()
}

function Render-Class($cls, [string]$thisPage, [bool]$withDefault) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("## ``$($cls.Name)``")
    [void]$sb.AppendLine()

    $notes = @()
    if ($cls.Blurb)  { $notes += $cls.Blurb }
    if ($cls.Parent) { $notes += (Render-Extends $cls.Parent $thisPage) }
    $usedNote = Render-UsedBy $cls.Name $thisPage
    if ($usedNote) { $notes += $usedNote }
    foreach ($n in $notes) { [void]$sb.AppendLine($n); [void]$sb.AppendLine() }

    [void]$sb.Append((Render-FieldTable $cls.Name $cls.Fields $thisPage $withDefault))

    # Inline each documented ancestor's fields, so the entry is self-contained
    # without following the "Extends" link. Defaults use this class as context.
    $ancestor = Get-DocumentedParent $cls
    while ($ancestor) {
        $acls = $classes[$ancestor]
        $ancLink = Get-ClassLink $ancestor "``$ancestor``" $thisPage
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("Inherited from ${ancLink}:")
        [void]$sb.AppendLine()
        [void]$sb.Append((Render-FieldTable $cls.Name $acls.Fields $thisPage $withDefault))
        $ancestor = Get-DocumentedParent $acls
    }

    # Below the table(s), expand each non-documented table default in full - the
    # Default column can only summarise those as `{...}` / `[...]`. Own fields first,
    # then inherited; each name expanded once.
    if ($withDefault) {
        $seen = @{}
        $anc  = $cls
        while ($anc) {
            foreach ($f in $anc.Fields) {
                if ($seen.ContainsKey($f.Name)) { continue }
                $seen[$f.Name] = $true
                $val = Get-ExpandableDefault (Get-FieldDefault $defaultsFor $cls.Name $f.Name) $f
                if ($null -eq $val) { continue }
                [void]$sb.AppendLine()
                [void]$sb.AppendLine("#### ``$($f.Name)`` default")
                [void]$sb.AppendLine()
                [void]$sb.AppendLine('```lua')
                [void]$sb.AppendLine((Format-LuaLiteral $val 0))
                [void]$sb.AppendLine('```')
            }
            $p = Get-DocumentedParent $anc
            $anc = if ($p) { $classes[$p] } else { $null }
        }
    }

    [void]$sb.AppendLine()
    return $sb.ToString()
}

# A page carries a Default column only if at least one field on it has a captured
# default, so pages without any (parts, controls, ...) stay 3-column.
function Test-PageHasDefaults($cat) {
    foreach ($n in $pageList[$cat.File]) {
        foreach ($f in $classes[$n].Fields) {
            if ((Get-FieldDefault $defaultsFor $n $f.Name).Has) { return $true }
        }
    }
    return $false
}

# The generated table block for one category page (classes only - the intro above
# the markers is hand-written and preserved).
function Build-CategoryBlock($cat) {
    $withDefault = Test-PageHasDefaults $cat
    $sb = New-Object System.Text.StringBuilder
    foreach ($n in $pageList[$cat.File]) {
        [void]$sb.Append((Render-Class $classes[$n] $cat.File $withDefault))
    }
    return $sb.ToString().TrimEnd()
}

$liveCats = @($Categories | Where-Object { $pageList[$_.File].Count -gt 0 })

# The API landing page and the sidebar share one flat list of reference pages.
$listSb = New-Object System.Text.StringBuilder
foreach ($cat in $liveCats) { [void]$listSb.AppendLine("- [[$($cat.Title)]]") }
$listBlock = $listSb.ToString().TrimEnd()

# Replace the content between the markers, preserving everything else (the intro,
# and anything below the block). Scaffolds the file with a placeholder intro if it
# does not exist; refuses to touch a file that has no markers.
function Update-MarkedFile([string]$path, [string]$block, [string]$title) {
    # StringBuilder.AppendLine emits the platform newline (CRLF on Windows), so
    # force LF to keep output identical on Windows and Linux.
    $region = ("$BeginMarker`n$GenNote`n`n$block`n$EndMarker") -replace "`r`n", "`n"
    if (Test-Path -LiteralPath $path) {
        # Normalize to LF so a CRLF working copy (git autocrlf) doesn't read as a change.
        $content = (Get-Content -LiteralPath $path -Raw) -replace "`r`n", "`n"
        $start = $content.IndexOf($BeginMarker)
        $end   = $content.IndexOf($EndMarker)
        if ($start -lt 0 -or $end -lt $start) {
            Write-Warning "No markers in $(Split-Path -Leaf $path) - skipped (add the BEGIN/END markers to manage this page)."
            return 'skipped'
        }
        $new = $content.Substring(0, $start) + $region + $content.Substring($end + $EndMarker.Length)
        if ($new -eq $content) { return 'unchanged' }
        if (-not $Check) { Set-Content -LiteralPath $path -Value $new -NoNewline -Encoding utf8 }
        return 'updated'
    }
    $scaffold = "# $title`n`n_Write an intro for this page above the generated block._`n`n$region`n"
    if (-not $Check) { Set-Content -LiteralPath $path -Value $scaffold -NoNewline -Encoding utf8 }
    return 'created'
}

# --- Output ------------------------------------------------------------------

Write-Host "Parsed $($classes.Count) classes; $($liveCats.Count) reference pages."

$targets = @()
foreach ($cat in $liveCats) {
    $targets += @{ Path = (Join-Path $WikiPath "$($cat.File).md"); Block = (Build-CategoryBlock $cat); Title = $cat.Title }
}
$targets += @{ Path = (Join-Path $WikiPath "API.md"); Block = $listBlock; Title = "API" }
$targets += @{ Path = (Join-Path $WikiPath "_Sidebar.md"); Block = $listBlock; Title = "_Sidebar" }

if (-not (Test-Path $WikiPath)) {
    if ($Check) {
        Write-Host "Wiki not found at $WikiPath; parse-only check."
        foreach ($t in $targets) { Write-Host "  would manage $(Split-Path -Leaf $t.Path)" }
        return
    }
    throw "Wiki path not found: $WikiPath (pass -WikiPath to override)"
}

foreach ($t in $targets) {
    $status = Update-MarkedFile $t.Path $t.Block $t.Title
    Write-Host ("  {0,-9} {1}" -f $status, (Split-Path -Leaf $t.Path))
}
