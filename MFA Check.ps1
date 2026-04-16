
# =========================
# AUTO SETUP: MODULE CHECK
# =========================

$requiredModules = @(
    "Microsoft.Graph.Users",
    "Microsoft.Graph.Identity.SignIns",
    "Microsoft.Graph.Identity.DirectoryManagement"
)

Write-Host "`n[SETUP] Prüfe Microsoft Graph Module..." -ForegroundColor Cyan

foreach ($module in $requiredModules) {

    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installiere Modul: $module" -ForegroundColor Yellow
        Install-Module $module -Scope CurrentUser -Force -AllowClobber
    }

    Write-Host "Importiere Modul: $module" -ForegroundColor Green
    Import-Module $module -ErrorAction SilentlyContinue
}


# =========================
# GRAPH LOGIN CHECK
# =========================

Write-Host "`n[SETUP] Prüfe Graph Verbindung..." -ForegroundColor Cyan

if (-not (Get-MgContext)) {

    Connect-MgGraph -Scopes `
        "User.Read.All",
        "Directory.Read.All",
        "Policy.Read.All",
        "UserAuthenticationMethod.Read.All"
}


# =========================
# MFA & AUTH METHOD AUDIT
# =========================

$userUPN = Read-Host "UPN des Users (z.B. max@firma.de)"

$user = Get-MgUser -UserId $userUPN -Property Id,DisplayName,UserPrincipalName

if (-not $user) {
    Write-Host "User nicht gefunden!" -ForegroundColor Red
    exit
}

Write-Host "`n===============================" -ForegroundColor Cyan
Write-Host "MFA REPORT für $($user.DisplayName)"
Write-Host "===============================" -ForegroundColor Cyan


# =========================================================
# 1. AUTHENTICATION METHODS
# =========================================================

Write-Host "`n[1] AUTHENTIFIKATIONSMETHODEN" -ForegroundColor Yellow

$methods = Get-MgUserAuthenticationMethod -UserId $user.Id

if (-not $methods) {
    Write-Host "Keine Authentifizierungsmethoden gefunden" -ForegroundColor Red
} else {
    foreach ($m in $methods) {
        Write-Host "- $($m.AdditionalProperties.'@odata.type')"
    }
}


# =========================================================
# 2. MFA REGISTRATION STATUS
# =========================================================

Write-Host "`n[2] MFA REGISTRIERUNG STATUS" -ForegroundColor Yellow

$hasStrongMethod = $false

$strongMethods = @(
    "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod",
    "#microsoft.graph.phoneAuthenticationMethod",
    "#microsoft.graph.fido2AuthenticationMethod",
    "#microsoft.graph.softwareOathAuthenticationMethod",
    "#microsoft.graph.temporaryAccessPassAuthenticationMethod"
)

foreach ($m in $methods) {
    if ($strongMethods -contains $m.AdditionalProperties.'@odata.type') {
        $hasStrongMethod = $true
    }
}

if ($hasStrongMethod) {
    Write-Host "MFA registriert: JA" -ForegroundColor Green
} else {
    Write-Host "MFA registriert: NEIN" -ForegroundColor Yellow
}


# =========================================================
# 3. CONDITIONAL ACCESS CHECK
# =========================================================

Write-Host "`n[3] CONDITIONAL ACCESS HINWEIS" -ForegroundColor Yellow

$caPolicies = Get-MgIdentityConditionalAccessPolicy -All

if (-not $caPolicies) {
    Write-Host "Keine Conditional Access Policies gefunden" -ForegroundColor Red
    Write-Host "=> MFA wird vermutlich NICHT zentral erzwungen" -ForegroundColor Yellow
} else {
    Write-Host "Conditional Access Policies vorhanden: $($caPolicies.Count)" -ForegroundColor Cyan
    Write-Host "=> MFA kann erzwungen werden (abhängig von Policy Scope)" -ForegroundColor Cyan
}


# =========================================================
# SUMMARY
# =========================================================

Write-Host "`n[SUMMARY]" -ForegroundColor Cyan

if ($hasStrongMethod) {
    Write-Host "User hat MFA eingerichtet." -ForegroundColor Green
} else {
    Write-Host "User hat KEINE MFA Methoden registriert." -ForegroundColor Yellow
}

Write-Host "Hinweis: MFA Enforcement hängt von Conditional Access ab." -ForegroundColor DarkGray
