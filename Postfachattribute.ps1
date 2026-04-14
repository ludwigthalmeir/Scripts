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
    # MAIN LOGIC
    # =========================
    $user = Read-Host "User eingeben"

    if ([string]::IsNullOrWhiteSpace($user)) {
        Write-Host "Kein User angegeben" -ForegroundColor Red
        return
    }

    Get-EXOMailbox -Identity $user |
        Format-List DisplayName,
                    PrimarySmtpAddress,
                    RecipientTypeDetails,
                    ProhibitSendQuota,
                    ProhibitSendReceiveQuota

    Read-Host "Enter zum Fortfahren"
}
