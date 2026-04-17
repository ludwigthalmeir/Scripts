#!/usr/bin/env pwsh

$repoDir = "/home/ludwig/Dokumente/Scripts"
$repoUrl = "https://github.com/ludwigthalmeir/Scripts.git"

# =========================
# 1. Verzeichnis prüfen / erstellen
# =========================
if (-not (Test-Path $repoDir)) {
    Write-Host "Ordner existiert nicht. Erstelle: $repoDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
}

Set-Location $repoDir

# =========================
# 2. Prüfen ob Git Repo existiert
# =========================
if (-not (Test-Path "$repoDir/.git")) {

    Write-Host "Kein Git-Repo gefunden. Klone Repository..." -ForegroundColor Cyan

    git clone $repoUrl .

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Clone erfolgreich." -ForegroundColor Green
    } else {
        Write-Host "Clone fehlgeschlagen!" -ForegroundColor Red
        exit 1
    }

} else {

    Write-Host "Git-Repo gefunden. Führe Pull aus..." -ForegroundColor Cyan

    git pull

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Update erfolgreich." -ForegroundColor Green
    } else {
        Write-Host "Pull fehlgeschlagen!" -ForegroundColor Red
        exit 1
    }
}

# =========================
# 3. Abschluss
# =========================
Write-Host "Repo ist synchronisiert." -ForegroundColor Green
