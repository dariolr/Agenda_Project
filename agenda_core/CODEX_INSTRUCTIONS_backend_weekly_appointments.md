# CODEX — Implementazione “Vista Settimanale Appuntamenti” nel BACKEND (Agenda)

## Obiettivo
Aggiungere **solo** la visualizzazione settimanale degli appuntamenti nel progetto **backend (admin/gestionale)**, mantenendo **inalterate** tutte le logiche esistenti (giornaliera, drag/resize, overlay ghost, auto-scroll, scroll-lock, gestione posizioni, filtri, caching, permessi, timezone, parsing modelli, API client).

**Regola d’oro:** l’implementazione deve essere **additiva** e **retro-compatibile**. Nessun comportamento attuale deve cambiare.

---

## Vincoli non negoziabili (anti-regressione)
1. Non modificare semantica/contratti degli endpoint esistenti.
2. Non cambiare struttura dei modelli già usati dal day-view (campi, parsing, naming).
3. Non cambiare provider esistenti: se serve, crea wrapper/add-on o nuovi provider.
4. Qualsiasi refactor “per pulizia” è vietato se non strettamente necessario.
5. La timezone di business/logica deve restare quella già adottata dal progetto (timezone location/business). **Mai** basarsi sulla timezone del browser per la logica.
6. Nessun ripple/splash effect (coerente con preferenze progetto).
7. UI/UX: il day-view deve rimanere identico quando selezionato.

---

## Deliverable
- Aggiungere una modalità **Settimana** nel punto in cui oggi si visualizza il day-view degli appuntamenti nel backend.
- La modalità settimana deve:
  - mostrare range Lun–Dom con navigazione settimana precedente/successiva + “Oggi”
  - riusare filtri esistenti (staff/location/status/servizi ecc.)
  - usare lo stesso flusso di apertura dettaglio appuntamento già esistente
  - supportare **le stesse interazioni** disponibili nella day-view (se presenti nel backend): drag/resize/ghost overlay/auto-scroll/scroll-lock/position management
  - caricare gli appuntamenti del range settimanale in modo efficiente, con caching per week+filtri.

---

## Procedura operativa (Codex)

### 0) Preparazione e mappa punti di integrazione (OBBLIGATORIO)
1. In root repo, identifica il progetto backend (es. `agenda_backend/` o simile).
2. Cerca i file del day-view attuale:
   - cerca stringhe: `DayView`, `AgendaDay`, `AppointmentsDay`, `calendar day`, `timeline`, `slot`, `drag`, `resize`.
   - trova la **screen principale** che mostra gli appuntamenti nel backend (la chiameremo **AppointmentsScreen** anche se si chiama diversamente).
3. Trova dove vengono gestiti:
   - filtri (provider/state/UI)
   - timezone (utility o service)
   - caricamento appuntamenti (API client + repository/service + provider)
   - UI blocchi appuntamento (widget “AppointmentCard/Tile/Block”)
   - interazioni (drag/resize/ghost overlay/auto-scroll)
4. Crea una lista (nel tuo contesto di lavoro) dei file reali trovati, ma **non** rinominare nulla.

**Exit criteria:** hai individuato:
- (A) Screen/Widget che ospita la vista giornaliera
- (B) Provider che fornisce gli appuntamenti del giorno
- (C) Widget che disegna il singolo appuntamento
- (D) Manager/Controller del drag/resize (se esiste)
- (E) Modulo/utility timezone

---

### 1) Aggiungere modalità di visualizzazione (Giorno/Settimana) senza rompere nulla
1. Nella screen che oggi renderizza il day-view, aggiungi un controllo UI **additivo**:
   - TabBar o Segmented control “Giorno | Settimana”
   - default: **Giorno** (per compatibilità)
2. Implementa uno stato locale o provider leggero:
   - `enum CalendarViewMode { day, week }`
   - memorizza la scelta (solo se già esiste persistenza per altre preferenze; altrimenti no).
3. Quando `mode == day`: renderizza **esattamente** il widget attuale (nessuna modifica al costruttore o logica).
4. Quando `mode == week`: renderizza un nuovo widget **WeeklyAppointmentsView**.

**Exit criteria:** build ok, day-view identico.

---

### 2) Definizione range settimana (timezone corretta)
1. Implementa una utility **nuova** (file nuovo) adiacente alle utility di date esistenti, es:
   - `lib/.../utils/week_range.dart`
2. Deve esporre:
   - `WeekRange computeWeekRange(DateTime anchor, LocationTz tz)` (adatta ai tipi reali progetto)
   - dove `WeekRange` include: `start`, `end`, `days[]` (7 date locali), `label`.
3. Logica:
   - Converti `anchor` nella timezone di location/business **usando la stessa utility già esistente** nel progetto.
   - Trova il lunedì della settimana di `anchor` (ISO-8601).
   - `start`: lunedì 00:00:00 locale
   - `end`: domenica 23:59:59.999 locale (oppure `endExclusive = nextMonday 00:00:00`, usa convenzione coerente con API esistenti)
4. Non introdurre nuove librerie timezone se il progetto ne ha già una: riusa quella.

**Exit criteria:** test manuale: anchor su mercoledì produce lunedì-domenica corretti; cambio timezone location non cambia la data in modo errato.

---

### 3) Caricamento appuntamenti per range (senza cambiare gli endpoint esistenti)
#### Caso A — esiste già un endpoint “range”
1. Se nel backend/API client esiste già una funzione tipo:
   - `getAppointments(from, to, filters...)`
   - riusala.
2. Crea un **nuovo provider**:
   - `weeklyAppointmentsProvider(weekStart, weekEnd, filtersKey)`
3. Il provider deve:
   - richiamare repository/service esistente (no duplicazioni logica)
   - applicare stessi filtri (riusa oggetto filtri esistente)
   - restituire lista appuntamenti.

#### Caso B — NON esiste endpoint range
1. NON cambiare endpoint giorno esistente.
2. Implementa nel layer backend (Flutter) un aggregator:
   - per ciascun giorno dei 7: chiama il metodo “day” esistente
   - esegui richieste in parallelo con un limite (es. max 3-4 concurrent) se la codebase già ha un helper; altrimenti `Future.wait` semplice.
3. Unisci risultati, rimuovi duplicati (se per qualche ragione esistono).
4. Indica nel codice un TODO per endpoint range futuro, ma senza modificarlo ora.

**Caching:** la key deve includere:
- `weekStartISO`
- `filtersHash` (stesso metodo hash del day provider, o nuovo hash deterministico)
- `locationId/businessId` se applicabile

**Exit criteria:** cambiando settimana/filtri, refetch corretto; tornando indietro a una settimana già vista, usa cache (se pattern progetto lo prevede).

---

### 4) Normalizzazione dati per rendering settimanale
1. Aggiungi un mapper (file nuovo) che trasforma `List<Appointment>` in:
   - `Map<LocalDate, List<Appointment>> byDay`
2. Ordinamento:
   - per giorno: ordina per `startAt`
3. Gestione appuntamenti che attraversano mezzanotte:
   - non cambiare la logica core; in UI settimanale:
     - mostra nel giorno di start con badge “+1g” se `endAt` supera giorno
     - NON spezzare lato server.

**Exit criteria:** lista per ciascun giorno coerente con day-view.

---

### 5) UI WeeklyAppointmentsView (prima versione: stabile e veloce)
Implementa la vista settimanale in modo **robusto** e con rischio minimo:
- **Versione 1 (consigliata):** 7 colonne con lista verticale (non griglia a slot), perché:
  - meno complessa per overlap
  - zero rischio di rompere drag/resize se questi sono collegati ai blocchi

#### Struttura
1. Crea widget: `WeeklyAppointmentsView`
2. Header:
   - label range (es. “3–9 Mar 2026”)
   - buttons: prev/next week, today
3. Body:
   - `Row` con 7 colonne (o `ListView` orizzontale con 7 cards)
   - ogni colonna:
     - titolo giorno (Lun 03)
     - `Expanded` con `ListView` degli appointment del giorno
4. Ogni appointment usa **lo stesso widget** del day-view (AppointmentCard/Tile/Block):
   - se il widget day-view dipende da contesto “timeline”, crea un adapter wrapper che mappa props senza cambiare logica.

#### Interazioni
- Tap/click: deve aprire lo stesso dettaglio attuale (riusa route/dialog esistente).
- Drag/resize:
  - Se il day-view usa un controller/manager generico, riusalo.
  - Se è strettamente legato alla timeline/slot grid, nella V1 abilita drag solo se già supportato a livello card (no regressioni). In ogni caso **non** introdurre un nuovo comportamento diverso.

**Exit criteria:** settimana visibile, clic su appuntamento apre dettaglio, filtri funzionano, day-view invariato.

---

### 6) Parità funzionale con day-view (drag/resize/ghost/auto-scroll) — SOLO SE già presenti nel backend
> Applica questa sezione solo se nel backend la day-view ha davvero drag/resize ecc.  
> Se non esistono nel backend, NON introdurli ora.

1. Identifica i componenti esistenti:
   - ghost overlay
   - auto-scroll mentre trascini
   - lock scroll durante resize
   - position management / collision / snap
2. Riusa gli stessi componenti:
   - nessuna nuova logica di calcolo posizioni
   - nessun nuovo algoritmo overlap
3. Adattamento settimana:
   - drop su un giorno diverso deve aggiornare:
     - `date` (giorno target)
     - `time` (stesso orario relativo, o quello calcolato dal drop se esiste)
     - durata invariata
   - update deve chiamare lo stesso endpoint/metodo di update spostamento esistente.
4. Stato ottimistico:
   - se day-view usa optimistic update, riusa lo stesso meccanismo, solo cambiando l’invalidate del provider settimana.

**Exit criteria:** stesso feeling e stesse regole della day-view; nessun comportamento “nuovo” non richiesto.

---

### 7) Navigazione settimana e sincronizzazione con filtri
1. Introduci `anchorDate` per la settimana:
   - default: “oggi” in timezone location/business
2. I pulsanti prev/next cambiano `anchorDate` di ±7 giorni.
3. Bottone “Oggi” imposta `anchorDate = now`.
4. Qualsiasi cambio filtri deve:
   - invalidare la query settimana corrente
   - NON toccare la day-view

**Exit criteria:** nessun crash; switching day/week mantiene filtri coerenti.

---

### 8) Prestazioni e UX
1. Evita rebuild pesanti:
   - usa `const` dove possibile
   - separa header/body
2. Placeholder loading:
   - skeleton semplice per 7 colonne (se già esiste un componente skeleton, riusalo)
3. Error state:
   - mostra errore non invasivo + retry (stesso pattern del day-view)

---

### 9) Test (minimo obbligatorio)
Aggiungi/aggiorna test secondo lo stack esistente (unit/widget). Se il progetto non ha test, fai almeno verifiche manuali documentate nel PR description.

Checklist manuale:
1. Day-view identico (pixel/percorso) prima/dopo.
2. Toggle giorno/settimana non rompe nulla.
3. Range settimana corretto Lun–Dom in timezone location.
4. Filtri: applicati identici.
5. Click dettaglio: identico.
6. Navigazione prev/next/today: ok.
7. Nessun ripple/splash nuovo.
8. Nessun endpoint modificato.

---

## Linee guida di implementazione (per evitare regressioni)
- Introduci file nuovi in cartelle coerenti, es:
  - `.../views/weekly/weekly_appointments_view.dart`
  - `.../providers/weekly_appointments_provider.dart`
  - `.../utils/week_range.dart`
  - `.../mappers/appointments_by_day.dart`
- Evita modifiche ai file esistenti oltre a:
  - aggiungere toggle UI nella screen che ospita la day-view
  - agganciare il nuovo widget settimana
- Se devi toccare un file esistente “core” (API, models, drag manager), fermati e scegli un approccio additivo (wrapper/extension) salvo bug blocker.

---

## Output richiesto (PR)
1. Commit 1: aggiunta toggle e weekly view scaffold (senza networking)
2. Commit 2: provider + load data settimana (range + mapping)
3. Commit 3: polishing UI (header, loading, error)
4. Commit 4: eventuale parity drag/resize (solo se esiste già nel backend)

Nel PR description includi:
- elenco file aggiunti/modificati
- checklist test manuale completata
- dichiarazione: “Day-view behavior unchanged”

---

## STOP conditions (se trovi ambiguità nel repo)
Se trovi 2 o più “day view” diverse:
- integra la settimana **solo** nella view usata in produzione (quella raggiunta dal menu principale “Appuntamenti”).
Se timezone non è chiara:
- trova dove il day-view calcola “oggi” e riusalo. Non inventare nuove regole.

---

## Nota finale
Non introdurre una griglia a slot (tipo Google Calendar) nella prima iterazione se aumenta il rischio regressione. Prima rendi stabile la settimana come **7 liste**; poi, se richiesto, si può evolvere a griglia mantenendo le stesse logiche.
