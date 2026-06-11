function Connect-Exchange {
    if (!(Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { 
        Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force 
    }
    if (!(Get-PSSession | Where-Object { $_.Name -like "ExchangeOnline*" })) { 
        Connect-ExchangeOnline -LoadCmdletHelp 
    }
}

function Show-Info {
    param ($oggetto)
    
    # Informazioni di base
    Write-Host "Nome (DisplayName): $($oggetto.DisplayName)"
    Write-Host "Indirizzo Principale: $($oggetto.PrimarySmtpAddress)"
    Write-Host "Alias: $($oggetto.Alias)"
    Write-Host "Tipo: $($oggetto.RecipientTypeDetails)"
    
    $statistiche = Get-EXOMailboxStatistics -Identity $oggetto.PrimarySmtpAddress -Properties TotalItemSize, LastLogonTime -ErrorAction SilentlyContinue

    if ($statistiche -and $statistiche.TotalItemSize.Value) {
        # Converte l'oggetto in stringa 
        $stringaValore = $statistiche.TotalItemSize.Value.ToString()
        
        # Estrae la parte numerica dei byte
        if ($stringaValore -match '\(([\d,\.]+)\sbytes\)') {
            $byteTotali = [long]($matches[1] -replace ',', '')
            $dimensioneMB = [math]::round($byteTotali / (1024 * 1024), 2)
        } else {
            $dimensioneMB = 0.0
        }
        
        $elementi = $statistiche.ItemCount
        
        # Recupera la data e l'ora dell'ultimo accesso
        $ultimoAccesso = $statistiche.LastLogonTime

        Write-Host "Dimensione (MB): $dimensioneMB"
        Write-Host "Numero elementi: $elementi"
        
        if ($ultimoAccesso) {
            Write-Host "Ultimo accesso: $ultimoAccesso" -ForegroundColor Cyan
        } else {
            Write-Host "Ultimo accesso: Mai / Dato non disponibile" -ForegroundColor Yellow
        }

    } else {
        Write-Host "Dimensione (MB): N/D"
        Write-Host "Numero elementi: N/D"
        Write-Host "Ultimo accesso: N/D"
    }
    
    Write-Host "Nascondi da GAL: $($oggetto.HiddenFromAddressListsEnabled)"
}

function Show-MailboxPermission {
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

function Select-User {
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

function Set-Permission {
    param ([string]$fullTarget, [string]$azione, [bool]$soloAccesso)
    $utente = Select-User
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

function Set-MemberList {
    param ([string]$nomeLista, [string]$azione)
    $utente = Select-User
    if (-not $utente) { return }
    
    if ($azione -eq 'Aggiungi') {
        Add-DistributionGroupMember -Identity $nomeLista -Member $utente.PrimarySmtpAddress
        Write-Host "Aggiunto $($utente.PrimarySmtpAddress) alla lista." -ForegroundColor Green
    } elseif ($azione -eq 'Rimuovi') {
        Remove-DistributionGroupMember -Identity $nomeLista -Member $utente.PrimarySmtpAddress -Confirm:$false
        Write-Host "Rimosso $($utente.PrimarySmtpAddress) dalla lista." -ForegroundColor Red
    }
}