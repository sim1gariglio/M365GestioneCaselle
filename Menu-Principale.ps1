[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

. .\Funzioni-Exchange.ps1

Write-Host "Inizializzazione modulo Exchange Online..." -ForegroundColor Cyan
Connetti-ExchangeOnline

$continuare = $true
while ($continuare) {
    Write-Host "`n--- GESTORE CASELLE ASL5 ---" -ForegroundColor Cyan
    Write-Host "1. Gestisci Shared Mailbox"
    Write-Host "2. Gestisci Distribution List"
    Write-Host "3. Gestisci Caselle Utente"
    Write-Host "4. Configura/Gestisci permessi CA (Script Esterno)"
    Write-Host "5. Esci (mantieni sessione attiva)" -ForegroundColor Yellow
    $scelta = Read-Host "`nSeleziona un numero"

    try {
        $tipi = $null
        $abilitaCreazione = $false
        $soloAccessoPermessi = $false

        switch ($scelta) {
            '1' { $tipi = @('SharedMailbox'); $abilitaCreazione = $true }
            '2' { $tipi = @('MailUniversalDistributionGroup', 'MailUniversalSecurityGroup') }
            '3' { $tipi = @('UserMailbox'); $soloAccessoPermessi = $true }
            '4' {
                if (Test-Path ".\Configura-CA.ps1") {
                    . .\Configura-CA.ps1
                } else {
                    Write-Host "File .\Configura-CA.ps1 non trovato nella cartella." -ForegroundColor Red
                }
                continue
            }
            '5' {
                Write-Host "`nUscita completata. Sessione Exchange attiva." -ForegroundColor Green
                $continuare = $false; break
            }
            default { Write-Host "Scelta non valida." -ForegroundColor Red; continue }
        }

        if ($tipi) {
            $nomePrefisso = Read-Host "Inserisci il prefisso esatto dell'indirizzo (es. 'ufficio', 'segreteria')"
            $fullTargetScelto = "$nomePrefisso@asl5.liguria.it"

            # Gestione ricerca modulare (attivabile/disattivabile creando il file Ricerca-Avanzata.ps1)
            $selezionato = $null
            if (Test-Path ".\Ricerca-Avanzata.ps1") {
                . .\Ricerca-Avanzata.ps1
                $selezionato = Cerca-ConLogicaAvanzata -nomeInput $nomePrefisso -tipiAccettati $tipi -abilitaCreazione $abilitaCreazione
            } else {
                # Modalità standard: Ricerca secca per indirizzo esatto
                $oggettoTrovato = Get-Recipient -Identity $fullTargetScelto -ErrorAction SilentlyContinue
                
                if ($oggettoTrovato -and ($tipi -contains $oggettoTrovato.RecipientTypeDetails)) {
                    $selezionato = $oggettoTrovato
                }
                elseif ($abilitaCreazione -and (-not $oggettoTrovato)) {
                    $confermaCreazione = Read-Host "Indirizzo non trovato. Vuoi creare la nuova Shared Mailbox '$fullTargetScelto'? (s/n)"
                    if ($confermaCreazione -eq 's') {
                        Write-Host "Creazione in corso..." -ForegroundColor Yellow
                        New-Mailbox -Shared -Name $nomePrefisso -Alias $nomePrefisso -PrimarySmtpAddress $fullTargetScelto
                        Start-Sleep -Seconds 5
                        $selezionato = Get-Recipient -Identity $fullTargetScelto
                    }
                } else {
                    Write-Host "Oggetto non trovato o tipologia non corrispondente al menu selezionato." -ForegroundColor Red
                }
            }
            
            if (-not $selezionato) { continue }

            # Sottomenu operativo
            $sub = $true
            while ($sub) {
                Write-Host "`n--- GESTIONE: $($selezionato.PrimarySmtpAddress) ---" -ForegroundColor Cyan
                Write-Host "1. Informazioni casella"
                
                if ($selezionato.RecipientTypeDetails -eq 'SharedMailbox' -or $selezionato.RecipientTypeDetails -eq 'UserMailbox') {
                    Write-Host "2. Visualizza deleghe attive"
                    Write-Host "3. Aggiungi utente"
                    Write-Host "4. Rimuovi utente"
                } elseif ($selezionato.RecipientTypeDetails -like '*DistributionGroup*') {
                    Write-Host "2. Visualizza membri"
                    Write-Host "3. Aggiungi membro"
                    Write-Host "4. Rimuovi membro"
                }
                Write-Host "0. Torna al menu principale"
                
                $act = Read-Host "Seleziona azione"
                switch ($act) {
                    '1' { Mostra-InfoOggetto -oggetto $selezionato }
                    '2' { 
                        if ($selezionato.RecipientTypeDetails -like '*DistributionGroup*') {
                            Write-Host "`nMembri attivi:" -ForegroundColor Yellow
                            Get-DistributionGroupMember -Identity $selezionato.PrimarySmtpAddress | Select-Object Name, PrimarySmtpAddress | Format-Table -AutoSize
                        } else {
                            Visualizza-PermessiCasella -fullTarget $selezionato.PrimarySmtpAddress
                        }
                    }
                    '3' {
                        if ($selezionato.RecipientTypeDetails -like '*DistributionGroup*') { Gestisci-MembriLista -nomeLista $selezionato.PrimarySmtpAddress -azione 'Aggiungi' }
                        else { Gestisci-Permessi -fullTarget $selezionato.PrimarySmtpAddress -azione 'Aggiungi' -soloAccesso $soloAccessoPermessi }
                    }
                    '4' {
                        if ($selezionato.RecipientTypeDetails -like '*DistributionGroup*') { Gestisci-MembriLista -nomeLista $selezionato.PrimarySmtpAddress -azione 'Rimuovi' }
                        else { Gestisci-Permessi -fullTarget $selezionato.PrimarySmtpAddress -azione 'Rimuovi' -soloAccesso $soloAccessoPermessi }
                    }
                    '0' { $sub = $false }
                    default { Write-Host "Scelta errata" -ForegroundColor Red }
                }
            }
        }
    }
    catch { Write-Host "Errore: $_" -ForegroundColor Red }
}