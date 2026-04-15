#!/usr/bin/env pwsh

# =========================
# MODULE CHECK + INSTALL
# =========================
$module = "ExchangeOnlineManagement"

Write-Host "Prüfe Modul: $module" -ForegroundColor Yellow

if (-not (Get-Module -ListAvailable -Name $module)) {
    Write-Host "Installiere $module ..." -ForegroundColor DarkYellow

    try {
        Install-Module $module -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "Installiert ✔" -ForegroundColor Green
    }
    catch {
        Write-Host "FEHLER bei Installation: $module" -ForegroundColor Red
        exit
    }
}

# =========================
# IMPORT MODULE
# =========================
try {
    Import-Module $module -ErrorAction Stop
    Write-Host "Modul geladen ✔" -ForegroundColor Green
}
catch {
    Write-Host "FEHLER beim Import: $module" -ForegroundColor Red
    exit
}

# =========================
# EXCHANGE CONNECT CHECK
# =========================
Write-Host "Prüfe Exchange Online Verbindung..." -ForegroundColor Yellow

try {
    Get-EXOMailbox -ResultSize 1 -ErrorAction Stop | Out-Null
    Write-Host "Bereits verbunden ✔" -ForegroundColor Green
}
catch {
    Write-Host "Keine aktive Session -> verbinde..." -ForegroundColor Yellow
    Connect-ExchangeOnline
}

# =========================
# MAIN QUERY
# =========================
Write-Host "`nLade Mailbox Daten..." -ForegroundColor Cyan

Get-EXOMailbox -ResultSize Unlimited |
    ForEach-Object {

        Get-EXOMailboxStatistics -Identity $_.Identity
    } |
    Select-Object DisplayName, TotalItemSize, ItemCount, StorageLimitStatus |
    Sort-Object TotalItemSize |
    Format-Table -AutoSize
