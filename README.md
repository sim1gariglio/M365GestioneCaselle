# Gestore Caselle e Liste ASL5

## 1. Panoramica
Il progetto consiste in uno strumento modulare sviluppato in **PowerShell** per la gestione e l'amministrazione centralizzata degli oggetti di posta su **Exchange Online (Microsoft 365)**. Lo script è predisposto per operare in modalità sicura, sfruttando sessioni interattive, mantenendo i token di sessione attivi per l'intera durata del turno lavorativo e separando le logiche operative in base alla tipologia di destinatario.

---

## 2. Struttura dei File
Lo script è suddiviso in più file `.ps1` situati nella medesima cartella di lavoro, ognuno con una specifica responsabilità:

* **`Menu-Principale.ps1`**: Il punto di ingresso dell'applicazione. Inizializza la codifica UTF-8, carica i moduli, gestisce il ciclo principale del menu e smista le chiamate alle funzioni specifiche per tipologia di oggetto o script esterni.
* **`Funzioni-Exchange.ps1`**: Contiene il motore logico dello strumento:
  * Connessione interattiva a Exchange Online (`Connect-ExchangeOnline`).
  * Visualizzazione delle informazioni dettagliate dell'oggetto (`Mostra-InfoOggetto`), inclusi i MB effettivi occupati, il numero di elementi e la data/ora dell'ultimo accesso (`LastLogonTime`) calcolati in modo robusto.
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
  * Informazioni casella: dimensione reale in MB, conteggio elementi, data ultimo accesso e visibilità GAL.
  * Visualizzazione deleghe attive (FullAccess e SendAs).
  * Aggiunta utente (conferisce sia FullAccess e SendAs).
  * Rimozione utente (revoca sia FullAccess che SendAs).

### 2. Distribution List
* **Ricerca**: Indirizzo esatto di gruppi di distribuzione o sicurezza abilitati alla posta.
* **Azioni**:
  * Informazioni di base.
  * Visualizzazione membri correnti (in formato tabella).
  * Aggiunta membro alla lista.
  * Rimozione membro alla lista.

### 3. Caselle Utente
* **Ricerca**: Indirizzo esatto della User Mailbox.
* **Azioni**:
  * Informazioni casella: dimensione reale in MB, conteggio elementi, data ultimo accesso e visibilità GAL.
  * Visualizzazione deleghe attive.
  * Aggiunta utente con accesso (conferisce **solo** il permesso `FullAccess`, escludendo il SendAs per questioni di sicurezza).
  * Rimozione utente (revoca `FullAccess`).

### 4. Configura/Gestisci permessi CA
* Permette di agganciare la configurazione specifica per la casella CA (`ca@asl5.liguria.it`) legata all'applicativo Azure.
* Sottomenu dedicato per aggiungere o rimuovere il permesso `SendAs` della casella CA su una qualsiasi mailbox di destinazione dell'azienda.

---

## 4. Prerequisiti e Configurazione Iniziale
* **Modulo PowerShell**: È richiesto il modulo `ExchangeOnlineManagement`. Lo script ne verifica automaticamente la presenza e ne guida l'installazione (se mancante) per l'utente corrente.
* **Autorizzazioni**: L'operatore che esegue lo script deve disporre di un account amministrativo su `admin.microsoft.com` (con ruolo di *Amministratore di Exchange* o superiore) per la gestione dei destinatari. È sufficiente un singolo login interattivo all'avvio della sessione di lavoro.
* **Esecuzione**: Posizionarsi nel percorso della cartella ed eseguire:
  ```powershell
  .\Menu-Principale.ps1