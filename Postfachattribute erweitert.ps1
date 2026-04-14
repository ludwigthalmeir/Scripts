
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
        return
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
    return
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
# USER INPUT
# =========================
$user = Read-Host "User eingeben"

Get-EXOMailbox -Identity $user |
    Select DisplayName, PrimarySmtpAddress, RecipientTypeDetails, ForwardingSmtpAddress, DeliverToMailboxAndForward

Get-EXOMailboxStatistics -Identity $user |
    Select TotalItemSize, ItemCount, LastLogonTime, StorageLimitStatus

Get-InboxRule -Mailbox $user

Get-MailboxPermission -Identity $user |
    Where-Object { $_.IsInherited -eq $false }

Pause
