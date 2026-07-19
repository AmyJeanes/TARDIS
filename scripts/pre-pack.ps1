$ErrorActionPreference = 'Stop'

# Run by gmod-addon-tools' publish-workshop workflow just before packing. The version is
# generated here rather than committed because it records the commit sha, and committing it
# would change that sha.
& "$PSScriptRoot/generate-version.ps1"
