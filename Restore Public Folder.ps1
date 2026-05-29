param (
    [string]$SearchPattern = "_Kontakte",
    [string]$TargetPath = "",
    [string]$UserPrincipalName = ""
)

Write-Host "▶ Restore Public Folder gestartet..." -ForegroundColor Cyan

# --------------------------------------------------
# 1. Prüfen ob Exchange Cmdlets verfügbar sind
# --------------------------------------------------
if (-not (Get-Command Get-PublicFolder -ErrorAction SilentlyContinue)) {

    Write-Host "▶ Exchange Cmdlets nicht gefunden" -ForegroundColor Yellow

    # Prüfen ob Modul existiert
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Host "▶ Installiere ExchangeOnlineManagement Modul..."
        Install-Module ExchangeOnlineManagement -Force -AllowClobber
    }

    Import-Module ExchangeOnlineManagement

    # Login
    if ($UserPrincipalName) {
        Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName
    } else {
        Connect-ExchangeOnline
    }
}

# --------------------------------------------------
# 2. Dumpster durchsuchen
# --------------------------------------------------
$dumpsterRoot = "\NON_IPM_SUBTREE\DUMPSTER_ROOT"

Write-Host "▶ Durchsuche Dumpster nach: $SearchPattern" -ForegroundColor Cyan

$results = Get-PublicFolder -Identity $dumpsterRoot -Recurse -ResultSize Unlimited |
    Where-Object { $_.Name -like "*$SearchPattern*" }

# --------------------------------------------------
# 3. Ergebnisse prüfen
# --------------------------------------------------
if (-not $results) {
    Write-Host "❌ Keine Treffer gefunden für: $SearchPattern" -ForegroundColor Red
    return
}

Write-Host "✅ Treffer gefunden:" $results.Count -ForegroundColor Green

# --------------------------------------------------
# 4. Verarbeitung
# --------------------------------------------------
foreach ($folder in $results) {

    Write-Host ""
    Write-Host "📁 Name: $($folder.Name)"
    Write-Host "📂 Pfad: $($folder.ParentPath)"
    Write-Host "🔎 Identity: $($folder.Identity)"

    if ($TargetPath) {
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
# 5. Fertig
# --------------------------------------------------
Write-Host ""
Write-Host "✔ Vorgang abgeschlossen" -ForegroundColor Cyan
