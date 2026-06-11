Write-Host "`n--- GESTIONE PERMESSI CA ---" -ForegroundColor Cyan

$trusteeGuid = "72cf7a90-8c4f-4958-8246-7813ede9bff1"
$trusteeEmail = "ca@asl5.liguria.it"

$fullTarget = Read-Host "Inserisci l'indirizzo email della casella di destinazione (es. ufficio@asl5.liguria.it)"

# Verifica che la casella esista prima di procedere
$verificaCasella = Get-Mailbox -Identity $fullTarget -ErrorAction SilentlyContinue

if ($verificaCasella) {
    $gestioneCa = $true
    while ($gestioneCa) {
        Write-Host "`nScegli l'operazione per la casella CA su $($fullTarget):" -ForegroundColor Yellow
        Write-Host "1. Aggiungi permessi CA"
        Write-Host "2. Rimuovi permessi CA"
        Write-Host "3. Torna indietro"
        
        $sceltaCa = Read-Host "Seleziona un numero"

        switch ($sceltaCa) {
            '1' {
                foreach ($ca in @($trusteeGuid, $trusteeEmail)) {
                    if (!(Get-RecipientPermission -Identity $fullTarget -Trustee $ca -ErrorAction SilentlyContinue)) {
                        Add-RecipientPermission -Identity $fullTarget -Trustee $ca -AccessRights SendAs -Confirm:$false
                        Write-Host "Permesso SendAs CA aggiunto con successo per: $ca" -ForegroundColor Green
                    } else {
                        Write-Host "Permesso SendAs CA già presente per: $ca" -ForegroundColor Gray
                    }
                }
            }
            '2' {
                foreach ($ca in @($trusteeGuid, $trusteeEmail)) {
                    if (Get-RecipientPermission -Identity $fullTarget -Trustee $ca -ErrorAction SilentlyContinue) {
                        Remove-RecipientPermission -Identity $fullTarget -Trustee $ca -AccessRights SendAs -Confirm:$false
                        Write-Host "Permesso SendAs CA rimosso per: $ca" -ForegroundColor Red
                    } else {
                        Write-Host "Nessun permesso SendAs CA trovato per: $ca" -ForegroundColor DarkGray
                    }
                }
            }
            '3' {
                Write-Host "Uscita dalla gestione CA." -ForegroundColor DarkGray
                $gestioneCa = $false
            }
            default { 
                Write-Host "Scelta non valida." -ForegroundColor Red 
            }
        }
    }
} else {
    Write-Host "La casella '$fullTarget' non è stata trovata nel tenant." -ForegroundColor Red
}