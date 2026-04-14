#!/usr/bin/env pwsh

$scriptPath = "/home/ludwig/Dokumente/Scripts"

function Get-ScriptList {
    Get-ChildItem -Path $scriptPath -Filter "*.ps1" |
    Where-Object { $_.Name -ne "Main.ps1" -and $_.Name -ne "sync-repo.ps1" }
}

function Run-Script($file) {
    Write-Host "`nStarte: $($file.Name)`n" -ForegroundColor Green
    pwsh -File $file.FullName
    Write-Host "`nFertig. Enter drücken..." -ForegroundColor DarkGray
    Read-Host
}

while ($true) {

    Clear-Host
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host "       ADMIN MAIN         " -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host ""

    $scripts = Get-ScriptList

    if ($scripts.Count -eq 0) {
        Write-Host "Keine Skripte gefunden." -ForegroundColor Red
        exit
    }

    # =========================
    # Anzeige Menü (Nummer)
    # =========================
    for ($i = 0; $i -lt $scripts.Count; $i++) {
        Write-Host "[$i] $($scripts[$i].Name)"
    }

    Write-Host ""
    Write-Host "[G] Grafische Auswahl"
    Write-Host "[Q] Beenden"
    Write-Host ""

    $input = Read-Host "Auswahl"

    # =========================
    # Beenden
    # =========================
    if ($input -eq "Q") {
        break
    }

    # =========================
    # GUI Auswahl (wenn verfügbar)
    # =========================
    if ($input -eq "G") {

        if (Get-Command Out-GridView -ErrorAction SilentlyContinue) {

            $selected = $scripts | Out-GridView -Title "Script auswählen" -PassThru

            if ($selected) {
                Run-Script $selected
            }

        } else {
            Write-Host "Out-GridView nicht verfügbar (kein GUI Support)." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }

        continue
    }

    # =========================
    # Nummerische Auswahl
    # =========================
    if ($input -match "^\d+$") {

        $index = [int]$input

        if ($index -ge 0 -and $index -lt $scripts.Count) {
            Run-Script $scripts[$index]
        } else {
            Write-Host "Ungültige Auswahl." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }

        continue
    }

}
