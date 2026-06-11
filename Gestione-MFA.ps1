function Connetti-MicrosoftGraph {
    # Verifica e carica il modulo di Graph
    if (!(Get-Module -ListAvailable -Name Microsoft.Graph)) { 
        Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force 
    }
    # Connessione con i permessi minimi necessari per leggere l'MFA
    if (!(Get-MgContext)) { 
        Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All"
    }
}

function Verifica-StatoMfaUtente {
    param ([string]$userEmail)
    
    Write-Host "`n--- STATO METODI DI AUTENTICAZIONE MFA ---" -ForegroundColor Cyan
    
    $utente = Get-MgUser -Filter "UserPrincipalName eq '$userEmail'" -ErrorAction SilentlyContinue
    
    if ($utente) {
        $metodi = Get-MgUserAuthenticationMethod -UserId $utente.Id -ErrorAction SilentlyContinue
        
        if ($metodi) {
            $metodi | Select-Object Id, MethodType, State | Format-Table -AutoSize
        } else {
            Write-Host "Nessun metodo MFA registrato o configurato per questo utente." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Utente '$userEmail' non trovato nel tenant Azure AD." -ForegroundColor Red
    }
}

function Reset-RegistrazioniMfa {
    param ([string]$userEmail)
    
    Write-Host "`n--- RESET METODI DI AUTENTICAZIONE ---" -ForegroundColor Cyan
    $utente = Get-MgUser -Filter "UserPrincipalName eq '$userEmail'" -ErrorAction SilentlyContinue
    
    if ($utente) {
        $conferma = Read-Host "Sei sicuro di voler richiedere una nuova registrazione MFA per $userEmail? (s/n)"
        if ($conferma -eq 's') {
            # Forza la re-impostazione della prova di autenticazione (revoca gli attuali metodi registrati)
            Revoke-MgUserSignInSession -UserId $utente.Id
            Write-Host "Sessioni revocate. L'utente dovrà riconfigurare l'MFA al prossimo accesso." -ForegroundColor Green
        } else {
            Write-Host "Operazione annullata." -ForegroundColor DarkGray
        }
    } else {
        Write-Host "Utente non trovato." -ForegroundColor Red
    }
}