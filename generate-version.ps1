$ErrorActionPreference = "Stop"

$versionFile = "version.json"
$version = Get-Content -Raw (Join-Path $PSScriptRoot $versionFile) | ConvertFrom-Json -AsHashtable

$major = $version.Major
$minor = $version.Minor
$patch = $version.Patch

Write-Host "Current version: $major.$minor.$patch"

$versionString = "$major.$minor.$patch"

$tag = git tag | Where-Object { $_ -eq $versionString }

if ($tag) {
    $commit = git rev-parse HEAD
    $tagCommit = git rev-parse $tag

    if ($commit -eq $tagCommit) {
        Write-Host "Tag $tag already exists, but is on the current commit, allowing.."
    }
    else {
        Write-Error "Tag $tag already exists, please increment the version number in version.json"
    }
}
else {
    Write-Host "Tag $versionString does not exist yet"
}

$targetFilename = Join-Path $PSScriptRoot "lua/tardis/libraries/libraries/libraries/sh_version_generated.lua"

$content = [System.Text.StringBuilder]::new()

$null = $content.AppendLine("-- AUTO GENERATED FILE - DO NOT EDIT --")
$null = $content.AppendLine("-- SOURCE FILE: $versionFile --")
$null = $content.AppendLine()
$null = $content.AppendLine("TARDIS.Version = {")
$null = $content.AppendLine("    Major = $major,")
$null = $content.AppendLine("    Minor = $minor,")
$null = $content.AppendLine("    Patch = $patch")
$null = $content.AppendLine("}")

Write-Host "Writing version to $targetFilename"

Set-Content -NoNewline -Path $targetFilename -Value $content