#!/usr/bin/env pwsh

$scriptPath = "/home/ludwig/Dokumente/Scripts"

# =========================
# MENU (EINFACH ERWEITERBAR)
# =========================
$menu = @(
    @{ Index = 1; Name = "Repo Update";        File = "RepoUpdate.ps1" }
    @{ Index = 2; Name = "Postfach Attribute"; File = "Postfachattribute.ps1" }
    @{ Index = 3; Name = "Postfach Attribute erweitert"; File = "Postfachattribute erweitert.ps1" }
    @{ Index = 4; Name = "Alle Postfächer Größe"; File = "Alle Postfächer Größe.ps1" }
    @{ Index = 5; Name = "Postfachberechtigungen einzelner User"; File = "Postfachberechtigungen einzelner User.ps1" }
    @{ Index = 6; Name = "Alle Postfächer Berechtigungen"; File = "Alle Postfächer Berechtigungen.ps1" }
    @{ Index = 7; Name = "Message Trace"; File = "Message Trace.ps1" }
    @{ Index = 8; Name = "Befristeter Zugriffspass"; File = "Befristeter Zugriffspass.ps1" }
    @{ Index = 9; Name = "Gruppen Mitglieder hinzufügen"; File = "Gruppen Mitglieder hinzufügen.ps1" }
    @{ Index = 10; Name = "Gruppen und Mitglieder anzeigen"; File = "Gruppen und Mitglieder anzeigen.ps1" }
    @{ Index = 11; Name = "Message Trace User"; File = "Message Trace User.ps1" }

)

# =========================
# LOOKUP MAP (EXTREM STABIL)
# =========================
$map = @{}
foreach ($item in $menu) {
    $map[[int]$item.Index] = $item
}

# =========================
# SCRIPT AUSFÜHREN
# =========================
function Run-Script($item) {

    $fullPath = Join-Path $scriptPath $item.File

    if (-not (Test-Path $fullPath)) {
        Write-Host "❌ Script nicht gefunden: $($item.File)" -ForegroundColor Red
        return
    }

    Write-Host "`n▶ Starte: $($item.Name)`n" -ForegroundColor Green

    & pwsh -NoProfile -ExecutionPolicy Bypass -File $fullPath

    Write-Host "`n✔ Fertig. Enter..."
    Read-Host
}

# =========================
# MAIN LOOP
# =========================
while ($true) {

    Clear-Host

    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "                 ADMIN MAIN                   " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($item in $menu) {
        Write-Host ("[{0}] {1}" -f $item.Index, $item.Name)
    }

    Write-Host ""
    Write-Host "[Q] Beenden"
    Write-Host ""

    $input = (Read-Host "Auswahl").Trim()

    if ($input -eq "Q") {
        break
    }

    # =========================
    # NUMERISCHE AUSWAHL (100% STABIL)
    # =========================
    if ($input -match "^\d+$") {

        $key = [int]$input

        if ($map.ContainsKey($key)) {
            Run-Script $map[$key]
        }
        else {
            Write-Host "❌ Keine Aktion für $key" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
