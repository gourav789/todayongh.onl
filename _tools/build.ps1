$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')

$postFiles = Get-ChildItem (Join-Path $PSScriptRoot 'posts') -Filter '*.ps1' | Sort-Object Name
foreach ($f in $postFiles) {
    Write-Host ("=== " + $f.Name + " ===")
    . $f.FullName
}

Build-Listings
Write-Host ("DONE. Total posts: " + $script:PostIndex.Count)
