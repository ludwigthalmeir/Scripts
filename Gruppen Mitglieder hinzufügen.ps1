# =========================
# MODULE CHECK + EXO LOGIN
# =========================
function Ensure-ExchangeOnline {
    
    # Prüfen ob Modul vorhanden
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Host "📦 ExchangeOnlineManagement wird installiert..." -ForegroundColor Yellow
        Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
    }

    # Modul laden
    Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue

    # Prüfen ob bereits verbunden
    try {
        Get-ConnectionInformation | Out-Null
        Write-Host "✔ Exchange Online bereits verbunden" -ForegroundColor Green
    }
    catch {
        Write-Host "🔐 Verbinde mit Exchange Online..." -ForegroundColor Yellow
        Connect-ExchangeOnline -ShowBanner:$false
    }
}
    Clear-Host

    Write-Host @"
"==============================================" 
             GRUPPENTYP AUSWÄHLEN		
"==============================================" 

[1] Sicherheitsgruppe
[2] Verteilergruppe
[3] Microsoft 365 Gruppe

"=============================================="
"@ -ForegroundColor Cyan

    do {
        $choice = Read-Host "➤ Auswahl (1-3)"
    } while ($choice -notin @("1","2","3"))

    switch ($choice) {
        "1" { $type = "Security" }
        "2" { $type = "Distribution" }
        "3" { $type = "M365" }
    }

    # 🔽 Ab hier war dein Fehler – gehört in die Funktion!
    $GroupName = Read-Host "Gruppenname"

    # 🔍 Gruppe suchen
    switch ($type) {

        "Security" {
            $group = Get-DistributionGroup -Identity $GroupName -ErrorAction SilentlyContinue |
                     Where-Object { $_.RecipientTypeDetails -eq "MailUniversalSecurityGroup" }
        }

        "Distribution" {
            $group = Get-DistributionGroup -Identity $GroupName -ErrorAction SilentlyContinue |
                     Where-Object { $_.RecipientTypeDetails -eq "MailUniversalDistributionGroup" }
        }

        "M365" {
            $group = Get-UnifiedGroup -Identity $GroupName -ErrorAction SilentlyContinue
        }
    }

    # 🆕 Erstellen falls nicht vorhanden
    if (-not $group) {
        Write-Host "Gruppe existiert nicht." -ForegroundColor Yellow

        $create = Read-Host "Erstellen? (j/n)"
        if ($create -ne "j") { return }

        $alias = Read-Host "Alias"
        $smtp  = Read-Host "SMTP-Adresse"

        switch ($type) {

            "Security" {
                $group = New-DistributionGroup `
                    -Name $GroupName `
                    -Alias $alias `
                    -PrimarySmtpAddress $smtp `
                    -Type Security
            }

            "Distribution" {
                $group = New-DistributionGroup `
                    -Name $GroupName `
                    -Alias $alias `
                    -PrimarySmtpAddress $smtp
            }

            "M365" {
                $group = New-UnifiedGroup `
                    -DisplayName $GroupName `
                    -Alias $alias `
                    -PrimarySmtpAddress $smtp
            }
        }

        Write-Host "Gruppe erstellt ✔" -ForegroundColor Green
    }
    else {
        Write-Host "Gruppe gefunden ✔" -ForegroundColor Green
    }

    # 👥 User hinzufügen
    Write-Host ""
    Write-Host "User hinzufügen (leer = fertig)" -ForegroundColor Cyan

    while ($true) {

        $user = Read-Host "User"

        if ([string]::IsNullOrWhiteSpace($user)) { break }

        $recipient = Get-Recipient $user -ErrorAction SilentlyContinue
        if (-not $recipient) {
            Write-Host "User nicht gefunden: $user" -ForegroundColor Red
            continue
        }

        try {
            switch ($type) {
                "Security"     { Add-DistributionGroupMember -Identity $GroupName -Member $user }
                "Distribution" { Add-DistributionGroupMember -Identity $GroupName -Member $user }
                "M365"         {
                    Add-UnifiedGroupLinks `
                        -Identity $GroupName `
                        -LinkType Members `
                        -Links $user
                }
            }

            Write-Host "✔ $user hinzugefügt" -ForegroundColor Green
        }
        catch {
            Write-Host "✖ Fehler bei $user" -ForegroundColor Red
        }
    }

    Read-Host "`nEnter zum Fortfahren"
