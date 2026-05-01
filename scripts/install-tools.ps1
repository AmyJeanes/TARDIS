#!/usr/bin/env pwsh
# Installs pinned versions of glua_check, glua_ls, and the GLua API stubs into
# .tools/. Idempotent: re-running is a no-op when the requested versions are
# already present.
#
# Bumping a version: edit the constants below, commit, and CI + every fresh
# clone picks it up automatically.

$ErrorActionPreference = 'Stop'

# Pinned versions ------------------------------------------------------------
# Renovate (.github/renovate.json customManagers) bumps these on upstream
# releases; the Renovate PR runs the GLua Check job in CI so a release that
# surfaces new diagnostics is caught before merge.
# Releases: https://github.com/Pollux12/gmod-glua-ls/releases
# renovate: datasource=github-releases depName=Pollux12/gmod-glua-ls
$GluaLsVersion  = '1.0.15'
# Releases: https://github.com/luttje/glua-api-snippets/releases
# renovate: datasource=github-releases depName=luttje/glua-api-snippets versioning=loose
$GluaApiVersion = '2026-03-31_16-30-01'

# Paths ----------------------------------------------------------------------
$Root         = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ToolsRoot    = Join-Path $Root '.tools'
$BinDir       = Join-Path $ToolsRoot 'bin'
$GluaCheckDir = Join-Path $ToolsRoot "glua-check/$GluaLsVersion"
$GluaLsDir    = Join-Path $ToolsRoot "glua-ls/$GluaLsVersion"
$GluaApiDir   = Join-Path $ToolsRoot 'glua-api'
$GluaApiMark  = Join-Path $GluaApiDir '.version'

# Platform detection ---------------------------------------------------------
if ($IsWindows -or ($null -eq $IsWindows -and $env:OS -eq 'Windows_NT')) {
    $Platform = 'win32-x64'
    $ExeExt   = '.exe'
} elseif ($IsLinux) {
    $Platform = 'linux-x64'
    $ExeExt   = ''
} else {
    throw 'Unsupported platform: prebuilt glua_check / glua_ls binaries are only published for Windows and Linux x64.'
}

function Install-Archive {
    param(
        [Parameter(Mandatory)] [string] $Url,
        [Parameter(Mandatory)] [string] $Dest
    )
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    $tmp = New-TemporaryFile
    try {
        Write-Host "  downloading $Url"
        Invoke-WebRequest -Uri $Url -OutFile $tmp.FullName
        if ($Url.EndsWith('.zip')) {
            Expand-Archive -Path $tmp.FullName -DestinationPath $Dest -Force
        } elseif ($Url.EndsWith('.tar.gz')) {
            tar -xzf $tmp.FullName -C $Dest
            if ($LASTEXITCODE -ne 0) { throw "tar failed extracting $Url" }
        } else {
            throw "Unknown archive type for $Url"
        }
    } finally {
        Remove-Item $tmp.FullName -Force -ErrorAction SilentlyContinue
    }
}

function Install-Binary {
    param(
        [Parameter(Mandatory)] [string] $Name,        # 'glua_check' | 'glua_ls'
        [Parameter(Mandatory)] [string] $Dest         # versioned dir
    )
    $exe = Join-Path $Dest "$Name$ExeExt"
    if (Test-Path $exe) { return $exe }

    Write-Host "Installing $Name $GluaLsVersion -> $Dest"
    $assetExt = if ($Platform -eq 'win32-x64') { 'zip' } else { 'tar.gz' }
    $asset    = "$Name-$Platform.$assetExt"
    $url      = "https://github.com/Pollux12/gmod-glua-ls/releases/download/$GluaLsVersion/$asset"
    Install-Archive -Url $url -Dest $Dest

    if (-not (Test-Path $exe)) { throw "$Name binary missing after extraction: $exe" }
    if ($ExeExt -eq '') { chmod +x $exe }
    return $exe
}

# glua_check + glua_ls -------------------------------------------------------
$gluaCheckExe = Install-Binary -Name 'glua_check' -Dest $GluaCheckDir
$gluaLsExe    = Install-Binary -Name 'glua_ls'    -Dest $GluaLsDir

# glua-api stubs -------------------------------------------------------------
# .luarc.json points at .tools/glua-api directly, so the working dir IS the
# install target. A .version marker tracks which release is currently
# extracted; mismatch triggers a clean re-extract.
$currentMark = if (Test-Path $GluaApiMark) { (Get-Content $GluaApiMark -Raw).Trim() } else { '' }
if ($currentMark -ne $GluaApiVersion) {
    Write-Host "Installing glua-api stubs $GluaApiVersion -> $GluaApiDir"
    if (Test-Path $GluaApiDir) { Remove-Item $GluaApiDir -Recurse -Force }
    $url = "https://github.com/luttje/glua-api-snippets/releases/download/$GluaApiVersion/$GluaApiVersion.lua.zip"
    Install-Archive -Url $url -Dest $GluaApiDir
    Set-Content -Path $GluaApiMark -Value $GluaApiVersion
}

# Mirror binaries to .tools/bin/ — scripts/glua-check.ps1 invokes glua_check
# from here, and the glua-lsp Claude Code plugin's shim resolves glua_ls
# from each project's .tools/bin/ at LSP launch. Versioned dirs stay around
# so switching versions is just a path change, not a re-download.
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
Copy-Item $gluaCheckExe (Join-Path $BinDir "glua_check$ExeExt") -Force
Copy-Item $gluaLsExe    (Join-Path $BinDir "glua_ls$ExeExt"   ) -Force

Write-Host ''
Write-Host 'Tools ready:'
Write-Host "  glua_check $GluaLsVersion  -> $gluaCheckExe"
Write-Host "  glua_ls    $GluaLsVersion  -> $gluaLsExe"
Write-Host "  glua-api   $GluaApiVersion -> $GluaApiDir"
