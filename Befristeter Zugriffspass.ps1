# =========================
    # GRAPH AUTH CHECK
    # =========================
    try {
        if (-not (Get-MgContext)) {
            throw "No Graph context"
        }
    }
    catch {
        Write-Host "Kein aktiver Microsoft Graph Login -> verbinde..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes "User.Read.All","Directory.Read.All","UserAuthenticationMethod.ReadWrite.All"
    }

    # =========================
    # INPUT
    # =========================
    $user = Read-Host "User (UPN) eingeben"
    if (-not $user) {
        Write-Host "Kein User angegeben" -ForegroundColor Red
        return
    }

    $hours = Read-Host "Gültigkeit in Stunden (z.B. 1, 4, 8)"
    if (-not $hours -or -not ($hours -as [int])) {
        Write-Host "Ungültige Stundenangabe" -ForegroundColor Red
        return
    }

    # =========================
    # TIME CALCULATION
    # =========================
    $start = Get-Date
    $end = $start.AddHours([int]$hours)

    # =========================
    # PARAMETER
    # =========================
    $params = @{
        startDateTime      = $start.ToString("o")
        lifetimeInMinutes  = ([int]$hours * 60)
        isUsableOnce       = $true
    }

    # =========================
    # CREATE TAP
    # =========================
    try {
        $tap = New-MgUserAuthenticationTemporaryAccessPassMethod `
            -UserId $user `
            -BodyParameter $params

        Write-Host "`n================ TAP CREATED ================" -ForegroundColor Green
        Write-Host "User   : $user"
        Write-Host "Start  : $start"
        Write-Host "Ende   : $end"
        Write-Host "TAP    : $($tap.TemporaryAccessPass)" -ForegroundColor Yellow
    }
    catch {
        Write-Host "`nFEHLER beim Erstellen des TAP" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
    }

    Read-Host "`nEnter zum Fortfahren"
