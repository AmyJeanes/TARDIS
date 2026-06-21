<#
.SYNOPSIS
    Generates the API type-reference wiki pages from the TARDIS source annotations.

.DESCRIPTION
    Parses the ---@class / ---@field annotations on the extension content-authoring
    definition tables (interiors, exteriors, parts, controls, sequences, settings,
    tips, icon packs, GUI themes, screens) and emits one markdown page per category
    into the TARDIS.wiki repo. The pages are a pure projection of the source
    annotations - including the trailing description text on each ---@field - so they
    stay in sync once the descriptions pass lands. Re-run to update.

    These pages complement, not replace, the hand-written tutorial pages.

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

# --- Annotation parser -------------------------------------------------------

# Split "<type> <description>" where the type may contain spaces inside (), <>,
# [] or {}. The type ends at the first whitespace seen at bracket-depth 0 - except
# a space right after a ':' at depth 0, which is a fun(...): rettype separator.
function Split-FieldType([string]$rest) {
    $depth = 0
    $lastNonSpace = ''
    for ($i = 0; $i -lt $rest.Length; $i++) {
        $c = $rest[$i]
        if ($c -eq '(' -or $c -eq '[' -or $c -eq '{' -or $c -eq '<') { $depth++; $lastNonSpace = $c }
        elseif ($c -eq ')' -or $c -eq ']' -or $c -eq '}' -or $c -eq '>') { $depth--; $lastNonSpace = $c }
        elseif ($c -eq ' ' -or $c -eq "`t") {
            if ($depth -le 0 -and $lastNonSpace -ne ':') {
                return @{ Type = $rest.Substring(0, $i).Trim(); Desc = $rest.Substring($i).Trim() }
            }
        }
        else { $lastNonSpace = $c }
    }
    return @{ Type = $rest.Trim(); Desc = "" }
}

# Parse every .lua file, returning:
#   Classes : ordered hashtable name -> @{ Name; Parent; Blurb; Fields = @(@{Name;Type;Optional;Desc;Group}) }
#   Ctors   : className -> "TARDIS:NewX()"
function Parse-Annotations([string]$root) {
    $classes = [ordered]@{}
    $ctors   = @{}

    $files = Get-ChildItem -Path $root -Recurse -Filter *.lua -File |
        Where-Object { $_.FullName -notmatch '\\gmod_wire_expression2\\' }

    foreach ($file in $files) {
        $lines = Get-Content -LiteralPath $file.FullName
        $current = $null          # class currently collecting fields
        $pendingReturn = $null    # '---@return X' on the previous line (for ctor detection)
        $docBuffer = @()          # consecutive '--- ...' doc lines for the class below

        foreach ($line in $lines) {
            $trim = $line.Trim()

            # '--- ...' doc-comment lines (not '---@', not '----') accumulate as the
            # description of the ---@class directly below them - the standard EmmyLua
            # mechanism, so glua_ls also shows them on hover.
            if ($trim -match '^---(?![@-])\s?(.*)$') {
                $d = $matches[1].Trim()
                if ($d) { $docBuffer += $d }
                continue
            }
            # Any other line ends the run; only a ---@class on the very next line
            # should consume the docs, so snapshot and reset here (a blank line in
            # between therefore detaches them, matching EmmyLua).
            $pendingDoc = $docBuffer
            $docBuffer = @()

            # Constructor: '---@return X' immediately above 'function TARDIS:NewX('
            if ($trim -match '^function\s+TARDIS:(New[A-Za-z0-9_]+)\s*\(' -and $pendingReturn) {
                $ctors[$pendingReturn] = "TARDIS:$($matches[1])()"
            }

            if ($trim -match '^---@class\s+([A-Za-z0-9_]+)\s*(?::\s*(.+?))?\s*$') {
                $name = $matches[1]
                $parent = if ($matches[2]) { $matches[2].Trim() } else { $null }
                $blurb = if ($pendingDoc.Count) { $pendingDoc -join ' ' } else { $null }
                if ($classes.Contains($name)) {
                    $current = $classes[$name]
                    if (-not $current.Parent -and $parent) { $current.Parent = $parent }
                    if (-not $current.Blurb -and $blurb) { $current.Blurb = $blurb }
                } else {
                    $current = @{ Name = $name; Parent = $parent; Blurb = $blurb; Fields = @() }
                    $classes[$name] = $current
                }
                $current.PendingGroup = $null
                $pendingReturn = $null
                continue
            }

            # Index signature: ---@field [keytype] valuetype - a dynamic-key entry.
            if ($current -and $trim -match '^---@field\s+\[([^\]]+)\]\s+(.+)$') {
                $split = Split-FieldType $matches[2]
                $current.Fields += @{
                    Name = "[$($matches[1].Trim())]"; Type = $split.Type; Optional = $true
                    Desc = $split.Desc; Group = $current.PendingGroup
                }
                $current.PendingGroup = $null
                $pendingReturn = $null
                continue
            }

            if ($current -and $trim -match '^---@field\s+([A-Za-z0-9_]+\??)\s+(.+)$') {
                $fname = $matches[1]
                $opt = $false
                if ($fname.EndsWith('?')) { $fname = $fname.TrimEnd('?'); $opt = $true }
                $split = Split-FieldType $matches[2]
                if ($split.Type.EndsWith('?')) { $opt = $true }
                $current.Fields += @{
                    Name = $fname; Type = $split.Type; Optional = $opt
                    Desc = $split.Desc; Group = $current.PendingGroup
                }
                $current.PendingGroup = $null
                $pendingReturn = $null
                continue
            }

            # A plain '-- ...' line inside a class block becomes a group caption
            # for the fields that follow.
            if ($current -and $trim -match '^--\s?(?!\[)(?!-@)(.*)$' -and $trim -notmatch '^---@') {
                $text = $matches[1].Trim()
                if ($text) { $current.PendingGroup = $text }
                continue
            }

            # End of an annotation block.
            $current = $null
            $pendingReturn = if ($trim -match '^---@return\s+([A-Za-z0-9_]+)') { $matches[1] } else { $null }
        }
    }

    return @{ Classes = $classes; Ctors = $ctors }
}

# --- Ownership ---------------------------------------------------------------

$parsed  = Parse-Annotations $LuaRoot
$classes = $parsed.Classes
$ctors   = $parsed.Ctors

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
    }
}

foreach ($cat in $Categories) {
    $page = $cat.File
    $queue = New-Object System.Collections.Generic.Queue[string]
    $seen  = @{}
    foreach ($r in $cat.Roots) { if ($classes.Contains($r)) { $queue.Enqueue($r); $seen[$r] = $true } }

    while ($queue.Count -gt 0) {
        $cname = $queue.Dequeue()
        foreach ($f in $classes[$cname].Fields) {
            foreach ($ref in (Get-Refs $f.Type)) {
                if ($owner.ContainsKey($ref)) { continue }  # owned elsewhere -> will link
                $owner[$ref] = $page
                [void]$pageList[$page].Add($ref)
                if (-not $seen.ContainsKey($ref)) { $queue.Enqueue($ref); $seen[$ref] = $true }
            }
        }
    }
}

# --- Rendering ---------------------------------------------------------------

function Get-Anchor([string]$name) { return $name.ToLower() }

function Format-Cell([string]$s) {
    if (-not $s) { return "" }
    return $s.Replace('|', '\|')
}

# Render a type as a (possibly linked) code span. Links only when the whole type
# is a single documentable class; compound types render as a plain code span.
function Render-Type([string]$type, [string]$thisPage) {
    $display = Format-Cell $type
    $stripped = $type.TrimEnd('?')
    if ((Is-Documentable $stripped) -and $owner.ContainsKey($stripped)) {
        $anchor = Get-Anchor $stripped
        $target = if ($owner[$stripped] -eq $thisPage) { "#$anchor" } else { "$($owner[$stripped])#$anchor" }
        return "[``$display``]($target)"
    }
    return "``$display``"
}

$BeginMarker = '<!-- BEGIN GENERATED API REFERENCE -->'
$EndMarker   = '<!-- END GENERATED API REFERENCE -->'
$GenNote     = '<!-- Generated by scripts/generate-wiki-api.ps1 from the source ---@class / ---@field annotations. Do not edit between these markers; re-run the script to update. -->'

function Render-Class($cls, [string]$thisPage) {
    $anchor = Get-Anchor $cls.Name
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("## ``$($cls.Name)``")
    [void]$sb.AppendLine()

    $notes = @()
    if ($cls.Blurb)  { $notes += $cls.Blurb }
    if ($ctors.ContainsKey($cls.Name)) { $notes += "Create with ``$($ctors[$cls.Name])``." }
    if ($cls.Parent) { $notes += "Extends ``$($cls.Parent)``." }
    foreach ($n in $notes) { [void]$sb.AppendLine($n); [void]$sb.AppendLine() }

    $tableOpen = $false
    $lastGroup = $null
    foreach ($f in $cls.Fields) {
        if ($f.Group -and $f.Group -ne $lastGroup) {
            if ($tableOpen) { [void]$sb.AppendLine() }
            [void]$sb.AppendLine("**$($f.Group)**")
            [void]$sb.AppendLine()
            $tableOpen = $false
            $lastGroup = $f.Group
        }
        if (-not $tableOpen) {
            [void]$sb.AppendLine("| Field | Type | Required | Description |")
            [void]$sb.AppendLine("|-|-|-|-|")
            $tableOpen = $true
        }
        $req = if ($f.Optional) { "" } else { "yes" }
        $typeCell = Render-Type $f.Type $thisPage
        [void]$sb.AppendLine("| ``$($f.Name)`` | $typeCell | $req | $(Format-Cell $f.Desc) |")
    }
    [void]$sb.AppendLine()
    return $sb.ToString()
}

# The generated table block for one category page (classes only - the intro above
# the markers is hand-written and preserved).
function Build-CategoryBlock($cat) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($n in $pageList[$cat.File]) {
        [void]$sb.Append((Render-Class $classes[$n] $cat.File))
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
