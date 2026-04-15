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

 $user = Read-Host "User eingeben (UPN / Mail / Alias)"

    Write-Host "`nSuche Berechtigungen für: $user ..." -ForegroundColor Cyan

    $results = @()

    # =========================
    # ALLE MAILBOXEN DURCHSUCHEN
    # =========================
    Get-Mailbox -ResultSize Unlimited | ForEach-Object {

        $mailbox = $_
        $identity = $mailbox.Identity

        # =========================
        # FULL ACCESS
        # =========================
        Get-MailboxPermission -Identity $identity -ErrorAction SilentlyContinue |
        Where-Object {
            $_.User -like $user -and
            $_.AccessRights -contains "FullAccess" -and
            -not $_.IsInherited
        } | ForEach-Object {
            $results += [PSCustomObject]@{
                Mailbox = $mailbox.PrimarySmtpAddress
                Type    = "Full Access"
                Rights  = "FullAccess"
            }
        }

        # =========================
        # SEND AS
        # =========================
        Get-RecipientPermission -Identity $identity -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Trustee -like $user -and
            $_.AccessRights -contains "SendAs"
        } | ForEach-Object {
            $results += [PSCustomObject]@{
                Mailbox = $mailbox.PrimarySmtpAddress
                Type    = "Send As"
                Rights  = "SendAs"
            }
        }

        # =========================
        # SEND ON BEHALF
        # =========================
        if ($mailbox.GrantSendOnBehalfTo) {
            foreach ($delegate in $mailbox.GrantSendOnBehalfTo) {

                if ($delegate -like "*$user*") {
                    $results += [PSCustomObject]@{
                        Mailbox = $mailbox.PrimarySmtpAddress
                        Type    = "Send on Behalf"
                        Rights  = "SendOnBehalf"
                    }
                }
            }
        }
    }

    # =========================
    # OUTPUT
    # =========================
    if ($results.Count -eq 0) {
        Write-Host "`nKeine Berechtigungen gefunden." -ForegroundColor Yellow
    }
    else {
        $results |
            Sort-Object Mailbox, Type |
            Format-Table -AutoSize
    }
