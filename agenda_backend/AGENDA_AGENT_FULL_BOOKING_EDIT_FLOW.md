# AGENDA_AGENT_FULL_BOOKING_EDIT_FLOW.md

## Execution Policy
L’agent NON deve implementare, modificare o generare codice automaticamente.
Tutte le istruzioni contenute in questo file di progetto sono descrittive, non esecutive.
L’agent deve limitarsi ad analisi, pianificazione e spiegazioni finché non riceve una richiesta esplicita di esecuzione.

## SCOPO

Implementare la **MODIFICA COMPLETA** di una prenotazione riutilizzando lo **stesso booking flow** (servizi → staff → data/ora → riepilogo) e applicando un modello di **REPLACE ATOMICO**: la prenotazione originale resta valida fino al commit e viene marcata `replaced` solo dopo la creazione riuscita della nuova.

Questa implementazione deve includere TUTTO ciò che serve: **database**, **API**, **log/audit**, **notifiche**, **UI frontend**, **UI backend/CRM**, **test**, **migrazioni**, **backfill** e **criteri DONE**.

---

## DEFINIZIONI

* **Original booking**: prenotazione esistente che l’utente vuole modificare.
* **New booking**: prenotazione creata dal flow di modifica.
* **Replace**: operazione atomica che crea la new booking e marca la original come `replaced`, collegandole e scrivendo un evento audit immutabile.
* **Audit event**: record immutabile che descrive chi ha fatto cosa, quando e cosa è cambiato (before/after snapshot).

---

## REQUISITI NON NEGOZIABILI

* Non usare lock “lunghi” di slot durante la modifica.
* Non cancellare hard la prenotazione originale.
* La prenotazione originale deve rimanere attiva fino al commit.
* Il commit deve essere **atomico** (transazione DB).
* Availability in modalità edit deve **escludere** la prenotazione originale dai conflitti.
* Notifiche: inviare **una sola** notifica “booking modified”, mai “cancel + new”.
* KPI/report: `replaced` NON è `cancelled`.
* Audit: deve essere **immutabile**, completo e ricostruibile.

---

## DELIVERABLES

1. Migrazione DB per:

   * relazione old↔new
   * stato `replaced`
   * tabella eventi audit
2. Nuovo endpoint core `POST /bookings/{booking_id}/replace`
3. Adeguamento availability per escludere original_booking_id
4. Frontend: riuso flow completo con prefill + CTA “Conferma modifica”
5. Backend/CRM: visualizzazione corretta + link storico
6. Notifiche e template
7. Test automatici/minimi + checklist QA

---

## PARTE A — DATABASE (agenda_core DB)

### A1. SCELTA MODELLO RELAZIONE

Implementare **ENTRAMBE** le cose seguenti:

* Campi su `bookings` per query rapide
* Tabella dedicata `booking_replacements` per audit/relazioni storiche

### A2. MIGRAZIONE: CAMPI SU BOOKINGS

Creare migration SQL (nuovo file nella cartella migrazioni del core) che aggiunge:

* `bookings.status` deve supportare valore `replaced` (se enum, estendere enum; se string, solo vincolo logico)
* `bookings.replaces_booking_id` (nullable, FK verso bookings.id)
* `bookings.replaced_by_booking_id` (nullable, FK verso bookings.id)
* indici:

  * IDX_bookings_replaces_booking_id
  * IDX_bookings_replaced_by_booking_id

DDL (adattare nomi tabella/colonne ai reali del progetto):

```sql
ALTER TABLE bookings
  ADD COLUMN replaces_booking_id BIGINT NULL,
  ADD COLUMN replaced_by_booking_id BIGINT NULL;

CREATE INDEX IDX_bookings_replaces_booking_id ON bookings(replaces_booking_id);
CREATE INDEX IDX_bookings_replaced_by_booking_id ON bookings(replaced_by_booking_id);

ALTER TABLE bookings
  ADD CONSTRAINT FK_bookings_replaces_booking_id
  FOREIGN KEY (replaces_booking_id) REFERENCES bookings(id)
  ON DELETE SET NULL;

ALTER TABLE bookings
  ADD CONSTRAINT FK_bookings_replaced_by_booking_id
  FOREIGN KEY (replaced_by_booking_id) REFERENCES bookings(id)
  ON DELETE SET NULL;
```

### A3. MIGRAZIONE: TABELLA BOOKING_REPLACEMENTS

Creare tabella:

```sql
CREATE TABLE booking_replacements (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  original_booking_id BIGINT NOT NULL,
  new_booking_id BIGINT NOT NULL,
  actor_type VARCHAR(32) NOT NULL,
  actor_id BIGINT NULL,
  reason VARCHAR(255) NULL,
  created_at DATETIME NOT NULL,

  CONSTRAINT FK_booking_replacements_original
    FOREIGN KEY (original_booking_id) REFERENCES bookings(id)
    ON DELETE RESTRICT,

  CONSTRAINT FK_booking_replacements_new
    FOREIGN KEY (new_booking_id) REFERENCES bookings(id)
    ON DELETE RESTRICT
);

CREATE UNIQUE INDEX UQ_booking_replacements_original ON booking_replacements(original_booking_id);
CREATE UNIQUE INDEX UQ_booking_replacements_new ON booking_replacements(new_booking_id);
CREATE INDEX IDX_booking_replacements_created_at ON booking_replacements(created_at);
```

Regole:

* Una prenotazione originale può essere sostituita al massimo una volta (unique su original_booking_id).
* Una new booking può essere il risultato di un solo replace (unique su new_booking_id).

### A4. MIGRAZIONE: TABELLA BOOKING_EVENTS (AUDIT)

Creare tabella eventi immutabile:

```sql
CREATE TABLE booking_events (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  booking_id BIGINT NOT NULL,
  event_type VARCHAR(64) NOT NULL,
  actor_type VARCHAR(32) NOT NULL,
  actor_id BIGINT NULL,
  correlation_id VARCHAR(64) NULL,
  payload_json JSON NOT NULL,
  created_at DATETIME NOT NULL,

  CONSTRAINT FK_booking_events_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(id)
    ON DELETE RESTRICT
);

CREATE INDEX IDX_booking_events_booking_id ON booking_events(booking_id);
CREATE INDEX IDX_booking_events_event_type ON booking_events(event_type);
CREATE INDEX IDX_booking_events_created_at ON booking_events(created_at);
```

Regole:

* `payload_json` deve contenere snapshot before/after e riferimenti old/new.
* Eventi non si aggiornano mai (immutabili). Vietare UPDATE applicativamente.

### A4.1 EVENT TYPES IMPLEMENTATI (18/01/2026)

| Event Type | Trigger | Actor Type | File |
|------------|---------|------------|------|
| `booking_created` | Nuova prenotazione (normale) | `staff` / `customer` | `CreateBooking.php` |
| `booking_replaced` | Prenotazione originale sostituita | `staff` / `customer` | `ReplaceBooking.php` |
| `booking_created_by_replace` | Nuova prenotazione da replace | `staff` / `customer` | `ReplaceBooking.php` |
| `appointment_updated` | Modifica singolo item | `staff` | `AppointmentsController.php` |

**Nota:** Gli eventi `booking_replaced` e `booking_created_by_replace` condividono lo stesso `correlation_id`.

### A5. BACKFILL / COMPATIBILITÀ

* Non eseguire backfill di vecchi record.
* Nuove colonne devono essere nullable.
* Se `bookings.status` è enum rigido, migrare senza rompere valori esistenti.

---

## PARTE B — CORE API / DOMAIN (agenda_core)

### B1. NUOVO ENDPOINT

Creare endpoint:

`POST /bookings/{booking_id}/replace`

* `{booking_id}` = original booking id.
* Richiede autenticazione come owner della prenotazione (utente finale) o staff autorizzato.

Body: uguale al create booking (stesso schema) con in più:

* `original_booking_id` (deve combaciare con path param)
* `client_expected_version` (opzionale se esiste versioning; se non esiste, ignorare)
* `reason` (opzionale)

Response:

* `new_booking_id`
* `original_booking_id`
* `status` (success/failure)
* eventuale dettaglio errore (slot non disponibile, permesso negato, ecc.)

### B2. VALIDAZIONI OBBLIGATORIE

Prima di tutto:

* la prenotazione originale deve esistere
* deve essere `confirmed` (o stato attivo equivalente)
* deve essere modificabile (rispettare regole “modifiable until …” se presenti in progetto)
* deve appartenere allo stesso business/location del contesto
* l’utente deve avere permessi di modifica
* deve NON essere già `replaced` e deve NON avere `replaced_by_booking_id` valorizzato

### B3. AVAILABILITY IN EDIT MODE

In tutte le funzioni di availability/calcolo conflitti:

* aggiungere parametro `exclude_booking_id` (nullable)
* quando è valorizzato, escludere quel booking dai conflitti

Regola conflitti:

* si possono ignorare SOLO conflitti con `exclude_booking_id`
* tutti gli altri conflitti devono bloccare la creazione

### B4. TRANSAZIONE ATOMICA (REPLACE)

Implementare la replace con transazione DB.

Pseudoflusso (OBBLIGATORIO):

1. BEGIN TRANSACTION
2. Rileggere original booking con FOR UPDATE (solo la riga booking, non lockare slot esterni)
3. Ricontrollare che non sia stata già sostituita
4. Eseguire availability check della new booking con `exclude_booking_id = original_booking_id`
5. Creare new booking (stessi servizi/booking_items, staff, risorse, note, ecc.)
6. Aggiornare old booking:

   * status = `replaced`
   * replaced_by_booking_id = new_booking_id
7. Aggiornare new booking:

   * replaces_booking_id = original_booking_id
8. Inserire row in `booking_replacements`
9. Inserire eventi audit (vedi B5)
10. COMMIT

Se uno qualunque degli step 4-9 fallisce:

* ROLLBACK
* la prenotazione originale rimane invariata

### B5. EVENTI AUDIT DA SCRIVERE

Scrivere eventi audit immutabili.

**✅ IMPLEMENTATO (18/01/2026)**

Scrivere SEMPRE:

* su original booking:

  * `event_type = booking_replaced`
* su new booking:

  * `event_type = booking_created_by_replace`

**AGGIUNTO (18/01/2026):** Oltre agli eventi di replace, vengono registrati:

* `booking_created` — per ogni nuova prenotazione (non da replace)
* `appointment_updated` — per ogni modifica a un singolo appointment

Payload minimo in `payload_json`:

* `original_booking_id`
* `new_booking_id`
* `before_snapshot`:

  * start/end (o start + duration)
  * staff_id
  * services/booking_items (ids + durata/prezzo)
  * location_id
  * notes
* `after_snapshot` con stessa struttura
* `reason` se presente
* `actor_type`/`actor_id`
* `created_at`

Actor mapping:

* se modifica da utente finale: actor_type = `customer`
* se modifica da staff/admin: actor_type = `staff`
* se modifica sistemica: actor_type = `system`

### B6. NOTIFICHE

Nel commit (post-commit hook o coda), inviare UNA sola notifica evento:

* `booking_modified`

Contenuto:

* old → new
* data/ora
* servizi
* operatore

Vietato:

* inviare `booking_cancelled` per old
* inviare `booking_created` per new come se fosse nuova prenotazione normale

### B7. KPI / REPORT

Assicurare che:

* `replaced` non incrementi contatore “cancellate”
* le query “upcoming bookings” escludano `replaced`
* le query storico possano includere `replaced` solo se richiesto

---

## PARTE C — FRONTEND CUSTOMER (agenda_frontend)

### C1. ENTRYPOINT MODIFICA

Da schermata “Le mie prenotazioni” esiste già testo e label “Modifica / Modificabile / Non modificabile”. Implementare comportamento:

* Se booking è modificabile → aprire flow booking in modalità edit
* Se non modificabile → mostrare messaggio già presente “Non modificabile” o equivalente

### C2. ROUTING E STATE

Aggiungere modalità `edit` al flow:

* `isEdit: true`
* `originalBookingId`

Requisiti:

* il flow deve usare gli stessi step
* tutti gli step devono essere sbloccati (servizi/staff/data/ora) in modalità edit
* i dati devono essere precompilati dal booking originale

### C3. PREFILL COMPLETO

All’avvio del flow edit:

* caricare dettagli booking originale (se non già disponibili nella lista)
* impostare selections:

  * location
  * servizi selezionati
  * staff
  * date/time
  * note

### C4. AVAILABILITY CALLS

Quando il flow in edit richiede disponibilità:

* passare `exclude_booking_id = originalBookingId` (o equivalente) alle API
* se l’API non supporta, usare endpoint dedicato availability edit (crearlo se serve)

### C5. CTA FINALE

Nel riepilogo:

* bottone = “Conferma modifica”
* chiamata API = `POST /bookings/{originalBookingId}/replace`

### C6. ERROR HANDLING

Se replace fallisce per conflitto:

* mostrare messaggio: “Lo slot non è più disponibile. La prenotazione originale è rimasta invariata.”
* mantenere il flow aperto e permettere scelta di altro slot

### C7. CONFIRMATION

Schermata conferma deve:

* indicare “Prenotazione aggiornata”
* mostrare codice/ID della nuova prenotazione
* avere link a “Le mie prenotazioni”

---

## PARTE D — BACKOFFICE / CRM (agenda_backend)

### D1. LISTA PRENOTAZIONI

Aggiornare query/filtri:

* di default mostrare solo prenotazioni attive (`confirmed`)
* escludere `replaced`

### D2. DETTAGLIO PRENOTAZIONE

Se una prenotazione è `replaced`:

* mostrare label “Sostituita”
* mostrare link alla prenotazione sostitutiva (replaced_by_booking_id)

Se una prenotazione sostituisce un’altra:

* mostrare “Sostituisce #ID” (replaces_booking_id)

### D3. STORICO MODIFICHE

Aggiungere sezione “Storico modifiche”:

* leggere booking_events
* mostrare eventi `booking_replaced` e `booking_created_by_replace`
* mostrare before/after (anche solo date/time + staff + servizi)

---

## PARTE E — SECURITY / PERMESSI

* Consentire replace solo a:

  * proprietario booking (customer)
  * staff/admin del business/location
* Bloccare replace se booking è già iniziato o passato (salvo policy)
* Applicare “modifiable until …” come già presente in app (label esistono)

---

## PARTE F — TEST OBBLIGATORI (DONE CRITERIA)

### F1. TEST API (minimi)

1. Replace success:

* crea new booking
* old diventa `replaced`
* campi link valorizzati (old.replaced_by = new, new.replaces = old)
* row booking_replacements creata
* 2 eventi booking_events creati

2. Replace conflict:

* availability conflict
* risposta errore
* old rimane `confirmed`
* nessuna new booking creata
* nessuna row replacements
* nessun evento audit

3. Replace double submit:

* seconda chiamata su same original deve fallire con errore “already replaced”

4. Permission denied:

* utente non owner/staff → 403

### F2. TEST UI FRONTEND

* Avvio flow edit con prefill
* Cambiare servizi, staff, data/ora
* Conferma → success → schermata aggiornata
* Conflitto slot → messaggio e retry
* Uscita senza conferma → nessuna modifica

### F3. KPI/REPORT

* `replaced` non risulta “cancellata”
* upcoming non mostra `replaced`

---

## PARTE G — IMPLEMENTAZIONE LOG (NON “LOGO”)

Implementare log applicativo (oltre al DB audit) per debugging:

* loggare correlation_id per replace
* loggare original_booking_id e new_booking_id
* loggare motivo errori availability

Non includere dati sensibili nelle log line.

---

## CHECKLIST FINALE (IL LAVORO È DONE SOLO SE)

* ✅ Esiste endpoint replace e funziona — `ReplaceBooking.php`
* ✅ Replace è atomico (rollback totale su errori)
* ✅ Availability in edit esclude original_booking_id — parametro `exclude_booking_id`
* ✅ Old booking non viene hard-deleted
* ✅ Old booking è `replaced`
* ✅ Relazione old↔new persistita (campi + tabella) — `booking_replacements`
* ✅ Audit events scritti con snapshot before/after — `booking_events` (18/01/2026)
* ⏳ Notifica unica "booking modified" — Da verificare
* ⏳ Frontend riusa flow completo con prefill e CTA corretta — Parziale
* ⏳ Backend/CRM mostra correttamente e non duplica in lista — Parziale
* ⏳ Tutti i test obbligatori passano — Da completare

### Stato Implementazione Audit (18/01/2026)

| Componente | Stato | Note |
|------------|-------|------|
| Tabella `booking_events` | ✅ | Migrazione eseguita |
| Tabella `booking_replacements` | ✅ | Migrazione eseguita |
| `booking_created` event | ✅ | `CreateBooking.php` |
| `booking_replaced` event | ✅ | `ReplaceBooking.php` |
| `booking_created_by_replace` event | ✅ | `ReplaceBooking.php` |
| `appointment_updated` event | ✅ | `AppointmentsController.php` |
| `booking_item_added` event | ✅ | `AppointmentsController.php` |
| `booking_item_deleted` event | ✅ | `AppointmentsController.php` |
| `booking_updated` event | ✅ | `UpdateBooking.php` |
| `booking_cancelled` event | ✅ | `DeleteBooking.php`, `AppointmentsController.php` |

---

## NOTE DI INTEGRAZIONE CON PROGETTO ESISTENTE

Nel progetto esistono già stringhe e UI per “Modifica”, “Modificabile”, “Non modificabile”, “Riprogramma prenotazione” e “Conferma modifica”: usare quelle invece di crearne di nuove.

Fine file.
