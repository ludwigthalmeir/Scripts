param (
    [string]$Url
)

if (-not $Url) {
    $Url = Read-Host "Bitte URL eingeben"
}

# Dateiname aus URL holen
$FileName = Split-Path $Url -Leaf

Write-Host "▶ Starte Download: $Url"

Invoke-WebRequest -Uri $Url -OutFile $FileName

Write-Host "✔ Fertig: $FileName"
