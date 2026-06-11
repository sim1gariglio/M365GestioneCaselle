function Connetti-ExchangeOnline {
    if (!(Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { 
        Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force 
    }
    if (!(Get-PSSession | Where-Object { $_.Name -like "ExchangeOnline*" })) { 
        Connect-ExchangeOnline -LoadCmdletHelp 
    }
}

function Mostra-InfoOggetto {
    param ([object]$oggetto)
    Write-Host "`n--- INFORMAZIONI OGGETTO ---" -ForegroundColor Cyan
    Write-Host "Nome (DisplayName): $($oggetto.DisplayName)" -ForegroundColor White
    Write-Host "Indirizzo Principale: $($oggetto.PrimarySmtpAddress)" -ForegroundColor White
    Write-Host "Alias: $($oggetto.Alias)" -ForegroundColor White
    Write-Host "Tipo: $($oggetto.RecipientTypeDetails)" -ForegroundColor White
    if ($oggetto.RecipientTypeDetails -eq 'SharedMailbox' -or $oggetto.RecipientTypeDetails -eq 'UserMailbox') {
        $mb = Get-Mailbox -Identity $oggetto.PrimarySmtpAddress
        Write-Host "Dimensione (MB): $([math]::round($mb.TotalItemSize.Value.RawValue / 1MB, 2))" -ForegroundColor Gray
        Write-Host "Nascondi da GAL: $($mb.HiddenFromAddressListsEnabled)" -ForegroundColor Gray
    }
}

function Visualizza-PermessiCasella {
    param ([string]$fullTarget)
    Write-Host "`n--- PERMESSI ATTIVI PER: $fullTarget ---" -ForegroundColor Cyan
    
    $fullAccess = Get-MailboxPermission -Identity $fullTarget -ErrorAction SilentlyContinue | Where-Object { $_.AccessRights -eq "FullAccess" -and $_.User -notlike "NT AUTHORITY\*" }
    Write-Host "Accesso Completo (FullAccess) - Totale: $(@($fullAccess).Count)" -ForegroundColor White
    if ($fullAccess) { $i = 1; foreach ($item in $fullAccess) { Write-Host "  $i. Utente: $($item.User)" -ForegroundColor Gray; $i++ } }
    else { Write-Host "  Nessun utente ha l'accesso completo." -ForegroundColor DarkGray }

    $sendAs = Get-RecipientPermission -Identity $fullTarget -ErrorAction SilentlyContinue | Where-Object { $_.AccessRights -eq "SendAs" -and $_.Trustee -notlike "NT AUTHORITY\*" }
    Write-Host "`nInvio come (SendAs) - Totale: $(@($sendAs).Count)" -ForegroundColor White
    if ($sendAs) { $j = 1; foreach ($item in $sendAs) { Write-Host "  $j. Utente: $($item.Trustee)" -ForegroundColor Gray; $j++ } }
    else { Write-Host "  Nessun utente ha il permesso di invio." -ForegroundColor DarkGray }
}

function Seleziona-Utente {
    $c = Read-Host "Inserisci il cognome o parte del nome dell'utente"
    $u = Get-Recipient -Filter "DisplayName -like '*$c*'" -RecipientTypeDetails UserMailbox -ResultSize 50 | Sort-Object PrimarySmtpAddress
    if (-not $u) { Write-Host "Utente non trovato." -ForegroundColor Red; return $null }
    
    if ($u.Count -gt 1) {
        Write-Host "Trovati più utenti:" -ForegroundColor Yellow
        for ($k = 0; $k -lt $u.Count; $k++) { Write-Host "  $($k + 1). $($u[$k].PrimarySmtpAddress) - $($u[$k].DisplayName)" -ForegroundColor Gray }
        Write-Host "  0. Annulla" -ForegroundColor Red
        $idx = Read-Host "Seleziona numero"
        if ($idx -eq '0') { return $null }
        return $u[$idx - 1]
    }
    return $u[0]
}

function Gestisci-Permessi {
    param ([string]$fullTarget, [string]$azione, [bool]$soloAccesso)
    $utente = Seleziona-Utente
    if (-not $utente) { return }
    
    $fullUser = $utente.PrimarySmtpAddress
    if ($azione -eq 'Aggiungi') {
        if (-not $soloAccesso) { Add-RecipientPermission -Identity $fullTarget -Trustee $fullUser -AccessRights SendAs -Confirm:$false }
        Add-MailboxPermission -Identity $fullTarget -User $fullUser -AccessRights FullAccess -InheritanceType All -Confirm:$false
        Write-Host "Accesso FullAccess aggiunto per $fullUser." -ForegroundColor Green
    } elseif ($azione -eq 'Rimuovi') {
        if (-not $soloAccesso) { Remove-RecipientPermission -Identity $fullTarget -Trustee $fullUser -AccessRights SendAs -Confirm:$false }
        Remove-MailboxPermission -Identity $fullTarget -User $fullUser -AccessRights FullAccess -Confirm:$false
        Write-Host "Accesso FullAccess rimosso per $fullUser." -ForegroundColor Red
    }
}

function Gestisci-MembriLista {
    param ([string]$nomeLista, [string]$azione)
    $utente = Seleziona-Utente
    if (-not $utente) { return }
    
    if ($azione -eq 'Aggiungi') {
        Add-DistributionGroupMember -Identity $nomeLista -Member $utente.PrimarySmtpAddress
        Write-Host "Aggiunto $($utente.PrimarySmtpAddress) alla lista." -ForegroundColor Green
    } elseif ($azione -eq 'Rimuovi') {
        Remove-DistributionGroupMember -Identity $nomeLista -Member $utente.PrimarySmtpAddress -Confirm:$false
        Write-Host "Rimosso $($utente.PrimarySmtpAddress) dalla lista." -ForegroundColor Red
    }
}