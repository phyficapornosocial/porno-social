$ErrorActionPreference = 'Stop'

$pattern = 'porno-social\.com|www\.porno-social\.com|support@porno-social\.com|dmca@porno-social\.com|privacy@porno-social\.com'

$literalMatches = Get-ChildItem -Path 'lib' -Recurse -Filter '*.dart' -File |
    Where-Object { $_.FullName -notlike '*lib\config\app_config.dart' } |
    Select-String -Pattern $pattern

if ($literalMatches) {
    Write-Host 'Hardcoded domain/email literals found outside lib/config/app_config.dart:'
    foreach ($match in $literalMatches) {
        Write-Host ("{0}:{1}: {2}" -f $match.Path, $match.LineNumber, $match.Line.Trim())
    }
    exit 1
}

Write-Host 'Domain literal guard passed.'