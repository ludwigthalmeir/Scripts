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
    Connect-ExchangeOnline -UseRPSSession
}

$results = @()

    Get-Mailbox -ResultSize Unlimited | ForEach-Object {
        $mailbox = $_
        $smtp = $mailbox.PrimarySmtpAddress

        # --- Full Access ---
        Get-MailboxPermission $mailbox.Identity |
        Where-Object {
            $_.User -notlike "NT AUTHORITY\SELF" -and
            $_.IsInherited -eq $false
        } | ForEach-Object {
            $results += [PSCustomObject]@{
                Mailbox    = $smtp
                User       = $_.User
                Type       = "Full Access"
                Rights     = ($_.AccessRights -join ", ")
                Deny       = $_.Deny
            }
        }

        # --- Send As ---
        Get-RecipientPermission $mailbox.Identity |
        Where-Object {
            $_.Trustee -ne "NT AUTHORITY\SELF" -and
            $_.AccessRights -like "*SendAs*"
        } | ForEach-Object {
            $results += [PSCustomObject]@{
                Mailbox    = $smtp
                User       = $_.Trustee
                Type       = "Send As"
                Rights     = "SendAs"
                Deny       = $_.Deny
            }
        }

        # --- Send on Behalf ---
        foreach ($user in $mailbox.GrantSendOnBehalfTo) {
            $results += [PSCustomObject]@{
                Mailbox    = $smtp
                User       = $user
                Type       = "Send on Behalf"
                Rights     = "SendOnBehalf"
                Deny       = $false
            }
        }
    }

    # 🔽 Sortierung für bessere Lesbarkeit
    $results = $results | Sort-Object Mailbox, Type, User

    # 🔽 Schöne Ausgabe gruppiert nach Mailbox
    $results | Format-Table `
        @{Label="Mailbox"; Expression={$_.Mailbox}; Width=30},
        @{Label="User"; Expression={$_.User}; Width=30},
        @{Label="Permission"; Expression={$_.Type}; Width=18},
        @{Label="Rights"; Expression={$_.Rights}; Width=20},
        @{Label="Deny"; Expression={$_.Deny}; Width=5} `
        -GroupBy Mailbox -AutoSize
