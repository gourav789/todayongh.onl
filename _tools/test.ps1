$ErrorActionPreference = 'Stop'
$out = Join-Path $env:TEMP 'test-gh.jpg'
try {
    Invoke-WebRequest -Uri 'https://soaps.sheknows.com/wp-content/uploads/2026/06/cassius-gun-sidwell-gh-abc.jpg' -OutFile $out -UseBasicParsing -TimeoutSec 30
    Write-Output ('Downloaded bytes: ' + (Get-Item $out).Length)
} catch {
    Write-Output ('DOWNLOAD ERROR: ' + $_.Exception.Message)
    return
}
try {
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile($out)
    Write-Output ('Image size: ' + $img.Width + 'x' + $img.Height)
    $img.Dispose()
    Write-Output 'System.Drawing OK'
} catch {
    Write-Output ('DRAWING ERROR: ' + $_.Exception.Message)
}
