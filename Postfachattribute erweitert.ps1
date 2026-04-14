# =========================
# AUTO MODULE CHECK + INSTALL
# =========================
function Ensure-Module($name) {

    if (-not (Get-Module -ListAvailable -Name $name)) {
        Write-Host "Modul fehlt -> installiere: $name" -ForegroundColor Yellow
        Install-Module $name -Scope CurrentUser -Force -AllowClobber
    }

    Import-Module $name -ErrorAction Stop
}

# =========================
# EXO VERBINDUNG SICHERN
# =========================
function Ensure-EXOConnection {

    try {
        Get-ConnectionInformation -ErrorAction Stop | Out-Null
        Write-Host "EXO bereits verbunden" -ForegroundColor Green
    }
    catch {
        Write-Host "Keine EXO Verbindung -> verbinde..." -ForegroundColor Yellow
        Connect-ExchangeOnline -ShowBanner:$false
    }
}

# =========================
# MODULE SETUP
# =========================
Ensure-Module ExchangeOnlineManagement
Ensure-EXOConnection

# =========================
# INPUT
# =========================
$user = Read-Host "User eingeben"

Write-Host "`n===== MAILBOX INFO =====`n" -ForegroundColor Cyan

Get-EXOMailbox -Identity $user |
    Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails, ForwardingSmtpAddress, DeliverToMailboxAndForward

Write-Host "`n===== STATISTICS =====`n" -ForegroundColor Cyan

Get-EXOMailboxStatistics -Identity $user |
    Select-Object TotalItemSize, ItemCount, LastLogonTime, StorageLimitStatus

Write-Host "`n===== INBOX RULES =====`n" -ForegroundColor Cyan

Get-InboxRule -Mailbox $user

Write-Host "`n===== PERMISSIONS =====`n" -ForegroundColor Cyan

Get-MailboxPermission -Identity $user |
    Where-Object { $_.IsInherited -eq $false }

# =========================
# PAUSE
# =========================
Read-Host "`nFertig - Enter zum Beenden"
