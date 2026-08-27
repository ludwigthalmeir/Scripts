$SharePointHostname = "SITE.sharepoint.com"
$SitePath = "/sites/SITENAME"

$LibraryName = "Documents"
$SharePointFolder = "Testordner 1"

$LocalTarget = "Y:\Migration"

Connect-MgGraph `
    -Scopes "Sites.Read.All","Files.Read.All" `
    -UseDeviceAuthentication `
    -NoWelcome

$Context = Get-MgContext

Write-Host ""
Write-Host "Angemeldet als: $($Context.Account)"
Write-Host "Tenant: $($Context.TenantId)"
Write-Host ""

$SiteIdPath = "$SharePointHostname`:$SitePath"

Write-Host "Suche SharePoint Site: $SiteIdPath"

$Site = Get-MgSite -SiteId $SiteIdPath

if (-not $Site) {
    Write-Error "Site nicht gefunden."
    exit
}

Write-Host "Site gefunden: $($Site.DisplayName)"
Write-Host ""

$Drive = Get-MgSiteDrive -SiteId $Site.Id |
    Where-Object { $_.Name -eq $LibraryName }

if (-not $Drive) {
    Write-Error "Bibliothek '$LibraryName' nicht gefunden."
    exit
}

Write-Host "Bibliothek gefunden: $($Drive.Name)"
Write-Host "Drive ID: $($Drive.Id)"
Write-Host ""

$EncodedFolderPath = [System.Uri]::EscapeDataString($SharePointFolder)

$FolderUri = "https://graph.microsoft.com/v1.0/drives/$($Drive.Id)/root:/$EncodedFolderPath"

try {
    $FolderItem = Invoke-MgGraphRequest `
        -Method GET `
        -Uri $FolderUri `
        -ErrorAction Stop
}
catch {
    Write-Error "Ordner '$SharePointFolder' wurde nicht gefunden."
    exit
}

Write-Host "Ordner gefunden: $($FolderItem.Name)"
Write-Host "Item ID: $($FolderItem.Id)"
Write-Host ""

function Download-DriveFolder {

    param(
        [string]$DriveId,
        [string]$ItemId,
        [string]$TargetFolder
    )

    if (!(Test-Path $TargetFolder)) {
        New-Item `
            -ItemType Directory `
            -Path $TargetFolder `
            -Force | Out-Null
    }

    $Children = Get-MgDriveItemChild `
        -DriveId $DriveId `
        -DriveItemId $ItemId `
        -All

    foreach ($Child in $Children) {

        $Extension = [System.IO.Path]::GetExtension($Child.Name)

        if ($Extension) {

            $FilePath = Join-Path $TargetFolder $Child.Name

            Write-Host "[DATEI ] $($Child.Name)"

            try {
                Invoke-MgGraphRequest `
                    -Method GET `
                    -Uri "https://graph.microsoft.com/v1.0/drives/$DriveId/items/$($Child.Id)/content" `
                    -OutputFilePath $FilePath
            }
            catch {
                Write-Warning "Download fehlgeschlagen: $($Child.Name)"
                Write-Warning $_.Exception.Message
            }

        }
        else {

            $FolderTarget = Join-Path $TargetFolder $Child.Name

            Write-Host "[ORDNER] $($Child.Name)"

            Download-DriveFolder `
                -DriveId $DriveId `
                -ItemId $Child.Id `
                -TargetFolder $FolderTarget
        }
    }
}

Write-Host ""
Write-Host "==========================================="
Write-Host "Starte Download"
Write-Host "Quelle : $LibraryName\$SharePointFolder"
Write-Host "Ziel   : $LocalTarget"
Write-Host "==========================================="
Write-Host ""

Download-DriveFolder `
    -DriveId $Drive.Id `
    -ItemId $FolderItem.Id `
    -TargetFolder $LocalTarget

Write-Host ""
Write-Host "==========================================="
Write-Host "Download abgeschlossen"
Write-Host "==========================================="
