$user = Read-Host "User eingeben"

    Get-EXOMailbox -Identity $user |
    Format-List DisplayName, PrimarySmtpAddress, RecipientTypeDetails,
    ProhibitSendQuota, ProhibitSendReceiveQuota

    Pause
}
