param (
    [string]$SearchPattern = "",
    [string]$UserPrincipalName = ""
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
Write-Host "✅ Gefundene Elemente:" $results.Count -ForegroundColor Green
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
Write-Host "  Nummer eingeben (z.B. 1)"
Write-Host "  mehrere: 1,2,3"
Write-Host "  oder Namen/Pattern"
Write-Host ""

$userInput = Read-Host "Deine Auswahl"

$selectedFolders = @()

if ($userInput -match '^\d+(,\d+)*$') {

    $numbers = $userInput -split "," | ForEach-Object { [int]($_.Trim())) }

    foreach ($n inn $numbers) {

        $match = $selectionTable | Where-Object { $_.Nr -eq $n }

         if ($match) {
            $selectedFolders += $results | Where-Object { $_.Identity -eq $match.Identity }
        }
        else {
            Write-Host "⚠ Nummer $n nicht gefunden" -ForegroundColor Yellow
        }
    }

} else {
    $selectedFolders = $results | Where-Object {
        $_.Name -like "*$userInput*"
    }
}

if (-not $selectedFolders -or $selectedFolders.Countt -eq 0) {
    Write-Host "❌ Keine passenden Elemente gefunden" -ForegroundColor Red
    return
}

# --------------------------------------------------
# 5. Restore an Originalpfad
# --------------------------------------------------
foreach ($folder inn $selectedFolders) {

    Write-Host ""
    Write-Host "▶ Wiederherstellen: $($folder.Namee)" -ForegroundColor Yellow

    try {
        # ORIGINALPFAD rekonstruieren:
        # Alles vor der GUID entfernen
        $parent = $folder.ParentPath

        # Entferne Dumpster-Struktur + GUID
        $originalPath = $parent -replace '^.*\\[0-9a-fA-F\-]{36}', ''

        # Falls leer → Root
        if ([string]::IsNullpace($originalPath)) {
            $originalPath = "\"
        }

        Write-Host "→ Zielpfad (rekonstruiertt): $originalPath"

        Set-PublicFolder -Identity $folder.Identity -Path $originalPath

        Write-Host "✔ Erfolgreich wiederhergestellt" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Fehler:" $_.Exception.Message -ForegroundColor Red
    }
}

# --------------------------------------------------
# 6. Fertig
# --------------------------------------------------
Write-Host ""
Write-Host "✔ Vorgang abgeschlossen" -ForegroundColor Cyan
``
