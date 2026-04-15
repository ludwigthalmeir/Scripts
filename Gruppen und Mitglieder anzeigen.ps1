 # =========================
    # AUTO MODULE CHECK
    # =========================
    $requiredModules = @(
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.Users",
        "Microsoft.Graph.Groups"
    )

    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host " MODULE CHECK / AUTO SETUP" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host ""

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
        }
    }

    # =========================
    # GRAPH CONNECT CHECK
    # =========================
    try {
        if (-not (Get-MgContext)) {
            throw "No Graph context"
        }
        Write-Host "Graph bereits verbunden ✔" -ForegroundColor Green
    }
    catch {
        Write-Host "Verbinde Microsoft Graph..." -ForegroundColor Yellow

        Connect-MgGraph -Scopes `
            "Group.Read.All",
            "GroupMember.Read.All",
            "User.Read.All"
    }

    # =========================
    # EXCHANGE CONNECT CHECK
    # =========================
    Write-Host "`nPrüfe Exchange Online Verbindung..." -ForegroundColor Yellow

    try {
        Get-EXOMailbox -ResultSize 1 -ErrorAction Stop | Out-Null
        Write-Host "Exchange bereits verbunden ✔" -ForegroundColor Green
    }
    catch {
        Write-Host "Verbinde Exchange Online..." -ForegroundColor Yellow
        Connect-ExchangeOnline
    }

    # =========================
    # MAIN LOGIC
    # =========================
    Write-Host "`n=================================" -ForegroundColor Cyan
    Write-Host "  ALLE GRUPPEN + MITGLIEDER"
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""

    $results = @()

    # =========================
    # EXCHANGE GROUPS
    # =========================
    Write-Host "Lade Exchange Gruppen..." -ForegroundColor Yellow

    $exchangeGroups = Get-DistributionGroup -ResultSize Unlimited

    foreach ($group in $exchangeGroups) {

        $type = switch ($group.RecipientTypeDetails) {
            "MailUniversalSecurityGroup"    { "Security (Mail-enabled)" }
            "MailUniversalDistributionGroup" { "Distribution Group" }
            default                         { $group.RecipientTypeDetails }
        }

        $members = Get-DistributionGroupMember -Identity $group.Identity -ResultSize Unlimited -ErrorAction SilentlyContinue

        if (-not $members) {
            $results += [PSCustomObject]@{
                Group  = $group.DisplayName
                Email  = $group.PrimarySmtpAddress
                Type   = $type
                Member = "<keine Mitglieder>"
                Source = "Exchange"
            }
        }
        else {
            foreach ($m in $members) {
                $results += [PSCustomObject]@{
                    Group  = $group.DisplayName
                    Email  = $group.PrimarySmtpAddress
                    Type   = $type
                    Member = $m.PrimarySmtpAddress
                    Source = "Exchange"
                }
            }
        }
