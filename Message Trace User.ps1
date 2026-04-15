# =========================
    # REQUIRED MODULES
    # =========================
    $requiredModules = @(
        "ExchangeOnlineManagement"
    )

    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host " MAIL OVERVIEW TOOL START" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host ""

    # =========================
    # MODULE CHECK + INSTALL
    # =========================
    foreach ($module in $requiredModules) {

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

        try {
            Import-Module $module -ErrorAction Stop
            Write-Host "Geladen ✔ $module" -ForegroundColor Green
        }
        catch {
            Write-Host "FEHLER beim Laden: $module" -ForegroundColor Red
            return
        }
    }

    # =========================
    # EXCHANGE CONNECT CHECK
    # =========================
    Write-Host "`nPrüfe Exchange Online Verbindung..." -ForegroundColor Yellow

    try {
        Get-EXOMailbox -ResultSize 1 -ErrorAction Stop | Out-Null
        Write-Host "Bereits verbunden ✔" -ForegroundColor Green
    }
    catch {
        Write-Host "Verbinde Exchange Online..." -ForegroundColor Yellow
        Connect-ExchangeOnline
    }

    # =========================
    # UI
    # =========================
    Write-Host ""
    Write-Host "1: Gesendete Emails"
    Write-Host "2: Empfangene Emails"
    Write-Host ""

    do {
        $choice = Read-Host "Auswahl (1/2)"
    } while ($choice -notin @("1","2"))

    # =========================
    # USER INPUT
    # =========================
    $user = Read-Host "User (UPN / Email)"

    if ([string]::IsNullOrWhiteSpace($user)) {
        Write-Host "Kein User angegeben!" -ForegroundColor Red
        return
    }

# =========================
# TIME RANGE (FIXED FULL DAYS)
# =========================
$days = Read-Host "Zeitraum in Tagen (Default 7)"
if (-not $days) { $days = 7 }

# Start = heute - X Tage um 00:00
$start = (Get-Date).Date.AddDays(-[int]$days)

# End = heute 23:59:59
$end = (Get-Date).Date.AddDays(1).AddSeconds(-1)

Write-Host "`nZeitraum:" -ForegroundColor Cyan
Write-Host "Von: $start"
Write-Host "Bis: $end"

    # =========================
    # DATA QUERY
    # =========================
    try {

        switch ($choice) {

            # =========================
            # SENT EMAILS
            # =========================
            "1" {
                $data = Get-MessageTraceV2 -StartDate $start -EndDate $end |
                    Where-Object { $_.SenderAddress -like "*$user*" }

                $title = "GESENDETE EMAILS"
            }

            # =========================
            # RECEIVED EMAILS
            # =========================
            "2" {
                $data = Get-MessageTraceV2 -StartDate $start -EndDate $end |
                    Where-Object { $_.RecipientAddress -like "*$user*" }

                $title = "EMPFANGENE EMAILS"
            }
        }
    }
    catch {
        Write-Host "Fehler beim Abrufen der Message Trace Daten" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
        return
    }

    # =========================
    # OUTPUT
    # =========================
    Write-Host "`n=============================" -ForegroundColor Cyan
    Write-Host " $title"
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host ""

    if (-not $data) {
        Write-Host "Keine Daten gefunden." -ForegroundColor Yellow
        return
    }

    $data |
        Sort-Object Received -Descending |
        Select-Object `
            Received,
            SenderAddress,
            Subject,
            Status |
        Format-Table -AutoSize

    # =========================
    # SUMMARY
    # =========================
    Write-Host "`n================ SUMMARY ================" -ForegroundColor Cyan

    $data |
    Sort-Object Received -Descending |
    Format-Table `
        @{Label="Received"; Expression={$_.Received}; Width=20},
        @{Label="Sender"; Expression={$_.SenderAddress}; Width=35},
        @{Label="Subject"; Expression={$_.Subject}; Width=80},
        @{Label="Status"; Expression={$_.Status}; Width=10} `
    -Wrap

    Pause
