param (
    [string]$Url
)

if (-not $Url) {
    Write-Host "Verwendung: .\get.ps1 <URL>"
    exit
}

# Dateiname aus URL extrahieren
$FileName = Split-Path $Url -Leaf

Write-Host "Starte Download von: $Url"

Invoke-WebRequest -Uri $Url -OutFile $FileName

Write-Host "Download abgeschlossen: $FileName"
