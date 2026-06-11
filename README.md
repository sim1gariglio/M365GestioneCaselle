# Gestore Caselle e Liste ASL5

## 1. Panoramica
Il progetto consiste in uno strumento modulare sviluppato in **PowerShell** per la gestione e l'amministrazione centralizzata degli oggetti di posta su **Exchange Online (Microsoft 365)**. Lo script è progettato per operare in modalità sicura, mantenendo la sessione attiva e separando le logiche operative in base alla tipologia di destinatario.

---

## 2. Struttura dei File
Lo script è suddiviso in più file `.ps1` situati nella medesima cartella di lavoro, ognuno con una specifica responsabilità:

* **`Menu-Principale.ps1`**: Il punto di ingresso dell'applicazione. Inizializza la codifica UTF-8, carica i moduli, gestisce il ciclo principale del menu e smista le chiamate alle funzioni specifiche per tipologia di oggetto (Shared, Distribution List, Utenti) o script esterni.
* **`Funzioni-Exchange.ps1`**: Contiene il motore logico dello strumento:
  * Connessione automatica a Exchange Online (`Connetti-ExchangeOnline`).
  * Visualizzazione delle informazioni dettagliate dell'oggetto (`Mostra-InfoOggetto`).
  * Lettura e visualizzazione dei permessi/deleghe attive (`Visualizza-PermessiCasella`).
  * Selezione guidata degli utenti tramite filtro sul DisplayName (`Seleziona-Utente`).
  * Gestione puntuale dei permessi FullAccess e SendAs (`Gestisci-Permessi`).
  * Gestione membership per le distribution list (`Gestisci-MembriLista`).
* **`Configura-CA.ps1`**: Script richiamato esternamente dal menu principale per l'applicazione e la rimozione massiva/puntuale dei permessi di invio (`SendAs`) riferiti alla casella Compliance/Auditing (`ca@asl5.liguria.it`), utilizzata da un applicativo configurato su Azure.
* **`Ricerca-Avanzata.ps1`** *(Opzionale)*: Modulo di ricerca per similarità (`DisplayName -like`). Se presente nella cartella, viene caricato dinamicamente al posto della ricerca per indirizzo esatto.

---

## 3. Funzionalità Dettagliate per Menu

### 1. Shared Mailbox
* **Ricerca**: Indirizzo esatto (o logica avanzata tramite modulo esterno). Possibilità di creare la Shared Mailbox se non esistente.
* **Azioni**:
  * Informazioni casella (dimensione in MB e visibilità GAL).
  * Visualizzazione deleghe attive (FullAccess e SendAs).
  * Aggiunta utente (conferisce sia FullAccess che SendAs).
  * Rimozione utente (revoca sia FullAccess che SendAs).

### 2. Distribution List
* **Ricerca**: Indirizzo esatto di gruppi di distribuzione o sicurezza abilitati alla posta.
* **Azioni**:
  * Informazioni di base.
  * Visualizzazione membri correnti (in formato tabella).
  * Aggiunta membro alla lista.
  * Rimozione membro dalla lista.

### 3. Caselle Utente
* **Ricerca**: Indirizzo esatto della User Mailbox.
* **Azioni**:
  * Informazioni casella standard.
  * Visualizzazione deleghe attive.
  * Aggiunta utente con accesso (conferisce **solo** il permesso `FullAccess`, escludendo il SendAs per questioni di sicurezza).
  * Rimozione utente (revoca `FullAccess`).

### 4. Configura/Gestisci permessi CA
* Permette di agganciare la configurazione specifica per la casella CA (`ca@asl5.liguria.it`) legata all'applicativo Azure.
* Sottomenu dedicato per aggiungere o rimuovere il permesso `SendAs` della casella CA su una qualsiasi mailbox di destinazione.

---

## 4. Prerequisiti e Configurazione Iniziale
* **Modulo PowerShell**: È richiesto il modulo `ExchangeOnlineManagement`. Lo script ne verifica automaticamente la presenza e lo installa (se mancante) per l'utente corrente.
* **Autorizzazioni**: L'operatore che esegue lo script deve disporre di un account amministrativo con i ruoli appropriati per la gestione dei destinatari su Exchange Online.
* **Esecuzione**: Posizionarsi nel percorso della cartella ed eseguire:
  ```powershell
  .\Menu-Principale.ps1