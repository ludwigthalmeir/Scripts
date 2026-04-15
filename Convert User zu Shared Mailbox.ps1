<# 
Konvertiert User-Mailbox → Shared Mailbox
Optional: entfernt Microsoft 365 Lizenzen (User-Entscheidung)
#>

# -----------------------------
# 1. Exchange Online Modul
# -----------------------------
$exoModule = "ExchangeOnlineManagement"

if (-not (Get-Module -ListAvailable -Name $exoModule)) {
    Write-Host "Installiere ExchangeOnlineManagement..." -ForegroundColor Yellow
    Install-Module $exoModule -Scope CurrentUser -Force -AllowClobber
}
Import-Module $exoModule

# -----------------------------
# 2. Microsoft Graph Modul
# -----------------------------
$graphModule = "Microsoft.Graph"

if (-not (Get-Module -ListAvailable -Name $graphModule)) {
    Write-Host "Installiere Microsoft.Graph..." -ForegroundColor Yellow
    Install-Module $graphModule -Scope CurrentUser -Force -AllowClobber
}
Import-Module $graphModule

# -----------------------------
# 3. Exchange Online verbinden
# -----------------------------
Connect-ExchangeOnline -ShowBanner:$false

# -----------------------------
# 4. User Eingabe
# -----------------------------
$user = Read-Host "UPN des Users eingeben (z.B. max@domain.de)"

$mailbox = Get-Mailbox -Identity $user -ErrorAction SilentlyContinue

if (-not $mailbox) {
    Write-Host "Mailbox nicht gefunden!" -ForegroundColor Red
    Disconnect-ExchangeOnline -Confirm:$false
    exit
}

# -----------------------------
# 5. Konvertierung zur Shared Mailbox
# -----------------------------
try {
    Write-Host "Konvertiere zu Shared Mailbox..." -ForegroundColor Yellow
    Set-Mailbox -Identity $user -Type Shared
    Write-Host "Konvertierung erfolgreich." -ForegroundColor Green
}
catch {
    Write-Host "Fehler: $_" -ForegroundColor Red
    Disconnect-ExchangeOnline -Confirm:$false
    exit
}

# -----------------------------
# 6. Entscheidung: Lizenz entfernen?
# -----------------------------
Write-Host ""
$choice = Read-Host "Sollen die Microsoft 365 Lizenzen entfernt werden? (J/N)"

if ($choice -match "^[JjYy]") {

    Write-Host "Verbinde zu Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.ReadWrite.All"

    # Lizenzen abrufen
    $licenses = Get-MgUserLicenseDetail -UserId $user

    if ($licenses) {
        $skuIds = $licenses | Select-Object -ExpandProperty SkuId

        Write-Host "Folgende Lizenzen werden entfernt:" -ForegroundColor Yellow
        $licenses | ForEach-Object {
            Write-Host " - $($_.SkuPartNumber)" -ForegroundColor Gray
        }

        try {
            Set-MgUserLicense -UserId $user -AddLicenses @() -RemoveLicenses $skuIds
            Write-Host "Lizenzen erfolgreich entfernt." -ForegroundColor Green
        }
        catch {
            Write-Host "Fehler beim Entfernen: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Keine Lizenzen vorhanden." -ForegroundColor Green
    }

    Disconnect-MgGraph
}
else {
    Write-Host "Lizenzentfernung übersprungen." -ForegroundColor Cyan
}

# -----------------------------
# 7. Cleanup
# -----------------------------
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "Fertig." -ForegroundColor Green
