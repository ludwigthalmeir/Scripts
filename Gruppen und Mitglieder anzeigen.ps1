#!/usr/bin/env pwsh

# =========================
# MODULE SETUP
# =========================

$modules = @(
    "ExchangeOnlineManagement",
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Groups"
)

Write-Host "=============================" -ForegroundColor Cyan
Write-Host " MODULE SETUP" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

foreach ($module in $modules) {

    Write-Host "`nPrüfe Modul: $module" -ForegroundColor Yellow

    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installiere $module ..." -ForegroundColor DarkYellow

        try {
            Install-Module $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-Host "Installiert ✔" -ForegroundColor Green
        }
        catch {
            Write-Host "FEHLER bei Installation: $module" -ForegroundColor Red
            exit
        }
    }

    try {
        Import-Module $module -ErrorAction Stop
        Write-Host "Geladen ✔ $module" -ForegroundColor Green
    }
    catch {
        Write-Host "FEHLER beim Import: $module" -ForegroundColor Red
        exit
    }
}

# =========================
# CONNECT EXCHANGE
# =========================

Write-Host "`nExchange Verbindung prüfen..." -ForegroundColor Yellow

try {
    Get-EXOMailbox -ResultSize 1 -ErrorAction Stop | Out-Null
    Write-Host "Exchange bereits verbunden ✔" -ForegroundColor Green
}
catch {
    Write-Host "Verbinde Exchange Online..." -ForegroundColor Yellow
    Connect-ExchangeOnline
}

# =========================
# CONNECT GRAPH
# =========================

Write-Host "`nMicrosoft Graph prüfen..." -ForegroundColor Yellow

try {
    if (-not (Get-MgContext)) {
        throw "No context"
    }
    Write-Host "Graph bereits verbunden ✔" -ForegroundColor Green
}
catch {
    Write-Host "Verbinde Microsoft Graph..." -ForegroundColor Yellow

    Connect-MgGraph -Scopes @(
        "Group.Read.All",
        "GroupMember.Read.All"
    )
}

# =========================
# OUTPUT STORAGE
# =========================

$results = @()

# =========================
# EXCHANGE GROUPS
# =========================

Write-Host "`nLade Exchange Gruppen..." -ForegroundColor Yellow

$exchangeGroups = Get-DistributionGroup -ResultSize Unlimited

foreach ($group in $exchangeGroups) {

    $members = Get-DistributionGroupMember -Identity $group.Identity -ResultSize Unlimited -ErrorAction SilentlyContinue

    if (-not $members) {
        $results += [PSCustomObject]@{
            Group  = $group.DisplayName
            Email  = $group.PrimarySmtpAddress
            Type   = "Exchange Distribution"
            Member = "<keine Mitglieder>"
            Source = "Exchange"
        }
    }
    else {
        foreach ($m in $members) {
            $results += [PSCustomObject]@{
                Group  = $group.DisplayName
                Email  = $group.PrimarySmtpAddress
                Type   = "Exchange Distribution"
                Member = $m.PrimarySmtpAddress
                Source = "Exchange"
            }
        }
    }
}

# =========================
# MICROSOFT 365 GROUPS
# =========================

Write-Host "`nLade Microsoft 365 Gruppen..." -ForegroundColor Yellow

$m365Groups = Get-MgGroup -All -Property Id,DisplayName,Mail,GroupTypes

foreach ($group in $m365Groups) {

    if ($group.GroupTypes -contains "Unified") {

        $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue

        if (-not $members) {
            $results += [PSCustomObject]@{
                Group  = $group.DisplayName
                Email  = $group.Mail
                Type   = "Microsoft 365 Group"
                Member = "<keine Mitglieder>"
                Source = "Graph"
            }
        }
        else {
            foreach ($m in $members) {
                $results += [PSCustomObject]@{
                    Group  = $group.DisplayName
                    Email  = $group.Mail
                    Type   = "Microsoft 365 Group"
                    Member = $m.AdditionalProperties["displayName"]
                    Source = "Graph"
                }
            }
        }
    }
}

# =========================
# SECURITY GROUPS
# =========================

Write-Host "`nLade Security Gruppen..." -ForegroundColor Yellow

$securityGroups = Get-MgGroup -All -Property Id,DisplayName,SecurityEnabled,MailEnabled

foreach ($group in $securityGroups) {

    if ($group.SecurityEnabled -eq $true -and $group.MailEnabled -eq $false) {

        $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue

        if (-not $members) {
            $results += [PSCustomObject]@{
                Group  = $group.DisplayName
                Email  = "-"
                Type   = "Security Group"
                Member = "<keine Mitglieder>"
                Source = "Graph"
            }
        }
        else {
            foreach ($m in $members) {
                $results += [PSCustomObject]@{
                    Group  = $group.DisplayName
                    Email  = "-"
                    Type   = "Security Group"
                    Member = $m.AdditionalProperties["displayName"]
                    Source = "Graph"
                }
            }
        }
    }
}

# =========================
# FINAL OUTPUT
# =========================

Write-Host "`n=============================" -ForegroundColor Cyan
Write-Host "        ERGEBNISSE"
Write-Host "=============================" -ForegroundColor Cyan

if (-not $results -or $results.Count -eq 0) {
    Write-Host "Keine Gruppen gefunden." -ForegroundColor Yellow
}
else {
    $results |
        Sort-Object Group, Type, Member |
        Format-Table `
            @{Label="Gruppe"; Expression={$_.Group}; Width=35},
            @{Label="E-Mail"; Expression={$_.Email}; Width=35},
            @{Label="Typ"; Expression={$_.Type}; Width=22},
            @{Label="Mitglied"; Expression={$_.Member}; Width=35},
            @{Label="Quelle"; Expression={$_.Source}; Width=10} `
        -AutoSize
}
