param (
    [string]$SearchPattern = "",
    [string]$TargetPath = "",
    [string]$UserPrincipalName = ""
)

Write-Host "▶ Restore Public Folder gestartet..." -ForegroundColor Cyan

# --------------------------------------------------
# 1. Exchange Verbindung sicherstellen
# --------------------------------------------------
if (-not (Get-Command Get-PublicFolder -ErrorAction SilentlyContinue)) {

    Write-Host "▶ Verbinde zu Exchange Online..." -ForegroundColor Yellow

    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Install-Module ExchangeOnlineManagement -Force -AllowClobber
    }

    Import-Module ExchangeOnlineManagement

    if ($UserPrincipalName) {
        Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName
    } else {
        Connect-ExchangeOnline
    }
}

# --------------------------------------------------
# 2. Dumpster laden (IMMER komplett!)
# --------------------------------------------------
$dumpsterRoot = "\NON_IPM_SUBTREE\DUMPSTER_ROOT"

Write-Host "▶ Lese kompletten Dumpster..." -ForegroundColor Cyan

$results = Get-PublicFolder -Identity $dumpsterRoot -Recurse -ResultSize Unlimited

# --------------------------------------------------
# 3. Optionaler Filter (nur wenn gesetzt!)
# --------------------------------------------------
if ($SearchPattern -and $SearchPattern.Trim() -ne "") {

    Write-Host "▶ Filter aktiv: $SearchPattern" -ForegroundColor Yellow

    $results = $results | Where-Object {
        $_.Name -like "*$SearchPattern*"
    }
}
else {
    Write-Host "▶ Kein Filter aktiv – zeige ALLE Elemente" -ForegroundColor Green
}

# --------------------------------------------------
# 4. Prüfen ob Ergebnisse vorhanden
# --------------------------------------------------
if (-not $results) {
    Write-Host "❌ Keine Elemente gefunden" -ForegroundColor Red
    return
}

Write-Host "✅ Gefundene Elemente:" $results.Count -ForegroundColor Green

# --------------------------------------------------
# 5. Ausgabe
# --------------------------------------------------
foreach ($folder in $results) {

    Write-Host ""
    Write-Host "📁 Name:     $($folder.Name)"
    Write-Host "📂 Pfad:     $($folder.ParentPath)"
    Write-Host "🔎 Identity: $($folder.Identity)"

    # Optional verschieben
    if ($TargetPath -and $TargetPath.Trim() -ne "") {
        try {
            Write-Host "➡ Verschiebe nach: $TargetPath" -ForegroundColor Yellow
            Set-PublicFolder -Identity $folder.Identity -Path $TargetPath
            Write-Host "✔ Erfolgreich verschoben" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Fehler:" $_.Exception.Message -ForegroundColor Red
        }
    }
}

# --------------------------------------------------
# 6. Export (immer hilfreich)
# --------------------------------------------------
$exportFile = "dumpster_export.csv"

$results | Select-Object Name, ParentPath, Identity |
    Export-Csv $exportFile -NoTypeInformation

Write-Host ""
Write-Host "✔ Export: $exportFile" -ForegroundColor Cyan
Write-Host "✔ Fertig" -ForegroundColor Cyan
