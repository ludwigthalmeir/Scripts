param (
    [string]$SearchPattern = "_Kontakte",
    [string]$TargetPath = $null   # optional Ziel z.B. "\MoTo"
)

Write-Host "▶ Durchsuche Dumpster..."

$dumpsterRoot = "\NON_IPM_SUBTREE\DUMPSTER_ROOT"

$results = Get-PublicFolder -Identity $dumpsterRoot -Recurse -ResultSize Unlimited |
    Where-Object { $_.Name -like "*$SearchPattern*" }

if (!$results) {
    Write-Host "❌ Keine Treffer gefunden für: $SearchPattern"
    return
}

foreach ($folder in $results) {
    Write-Host "✔ Gefunden:" $folder.Identity

    if ($TargetPath) {
        try {
            Write-Host "  → Verschiebe nach $TargetPath"
            Set-PublicFolder -Identity $folder.Identity -Path $TargetPath
        }
        catch {
            Write-Host "  ❌ Fehler beim Verschieben:" $_.Exception.Message
        }
    }
}

Write-Host "✔ Fertig"
``
