param (
    [string]$SearchPattern = "",
    [string]$UserPrincipalName = "",
    [string]$TargetPath = ""
)

Write-Host "▶ Restore Public Folder gestartet..." -ForegroundColor Cyan

# --------------------------------------------------
# 1. Exchange Verbindung
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
# 2. Dumpster laden
# --------------------------------------------------
$dumpsterRoot = "\NON_IPM_SUBTREE\DUMPSTER_ROOT"

Write-Host "▶ Lese kompletten Dumpster..." -ForegroundColor Cyan

$results = Get-PublicFolder -Identity $dumpsterRoot -Recurse -ResultSize Unlimited

if ($SearchPattern) {
    $results = $results | Where-Object { $_.Name -like "*$SearchPattern*" }
}

if (-not $results) {
    Write-Host "❌ Keine Elemente gefunden" -ForegroundColor Red
    return
}

# --------------------------------------------------
# 3. Auswahl anzeigen
# --------------------------------------------------
Write-Host ""
Write-Host "✅ Gefundene Elemente: $($results.Count)" -ForegroundColor Green
Write-Host ""

$index = 1
$selectionTable = @()

foreach ($folder in $results) {

    $obj = [PSCustomObject]@{
        Nr       = $index
        Name     = $folder.Name
        Pfad     = $folder.ParentPath
        Identity = $folder.Identity
    }

    $selectionTable += $obj
    Write-Host ("[{0}] {1}" -f $index, $folder.Name)

    $index++
}

# --------------------------------------------------
# 4. Auswahl
# --------------------------------------------------
Write-Host ""
Write-Host "➡ Auswahlmöglichkeiten:" -ForegroundColor Cyan
Write-Host "  Nummer (z.B. 1)"
Write-Host "  mehrere: 1,2,3"
Write-Host "  oder Name/Pattern"
Write-Host ""

$userInput = Read-Host "Deine Auswahl"

$selectedFolders = @()

if ($userInput -match '^\d+(,\d+)*$') {

    $parts = $userInput -split ","

    foreach ($p in $parts) {

        $n = 0
        if ([int]::TryParse($p.Trim(), [ref]$n)) {

            $match = $selectionTable | Where-Object { $_.Nr -eq $n }

            if ($match) {
                $selectedFolders += $results | Where-Object { $_.Identity -eq $match.Identity }
            } else {
                Write-Host "⚠ Nummer $n nicht gefunden" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "⚠ Ungültige Eingabe: $p" -ForegroundColor Yellow
        }
    }

} else {
    $selectedFolders = $results | Where-Object {
        $_.Name -like "*$userInput*"
    }
}

if (-not $selectedFolders -or $selectedFolders.Count -eq 0) {
    Write-Host "❌ Keine passenden Elemente gefunden" -ForegroundColor Red
    return
}

# --------------------------------------------------
# 5. Zielpfad abfragen (wenn nicht gesetzt)
# --------------------------------------------------
if (-not $TargetPath) {
    Write-Host ""
    Write-Host "➡ Zielpfad angeben (z.B. \Folder\Subfolder)" -ForegroundColor Cyan
    $TargetPath = Read-Host "Zielpfad"
}

if (-not $TargetPath -or $TargetPath.Trim() -eq "") {
    Write-Host "❌ Kein Zielpfad angegeben" -ForegroundColor Red
    return
}

# --------------------------------------------------
# 6. Restore durchführen
# --------------------------------------------------
foreach ($folder in $selectedFolders) {

    Write-Host ""
    Write-Host "▶ Wiederherstellen: $($folder.Name)" -ForegroundColor Yellow
    Write-Host "→ Zielpfad: $TargetPath"

    try {
        Set-PublicFolder -Identity $folder.Identity -Path $TargetPath
        Write-Host "✔ Erfolgreich wiederhergestellt" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Fehler: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --------------------------------------------------
# 7. Fertig
# --------------------------------------------------
Write-Host ""
Write-Host "✔ Vorgang abgeschlossen" -ForegroundColor Cyan
