# Istruzioni Codex — Capienza servizi prenotabili in parallelo (V1)

## Obiettivo

Implementare nella piattaforma Agenda la possibilità di configurare alcuni servizi come prenotabili contemporaneamente più volte sullo stesso staff/colonna, fino a una capienza massima configurabile.

Esempio:
- servizio: “Accesso sala pesi”
- durata: 60 minuti
- capienza contemporanea: 50
- prenotazioni consentite:
  - 08:15 → 09:15
  - 08:20 → 09:20
  - 08:40 → 09:40
  - ecc.
- lo slot resta prenotabile finché, nell’intervallo richiesto, il numero di prenotazioni sovrapposte resta inferiore a 50.

Questa è una V1 volutamente confinata: NON implementare colonna condivisa senza staff, waitlist automatica, heatmap occupazione, gestione gruppi, prenotazioni multiple nella stessa booking, o nuove entità risorsa.

---

## Regola di dominio finale

La capienza è una proprietà del servizio/variante servizio, non dello staff.

Lo staff resta l’asse temporale su cui viene verificata la disponibilità.

La regola corretta è:

> un determinato servizio può essere prenotato in parallelo fino a X volte per lo stesso staff, nella stessa location e nello stesso intervallo temporale.

Default:
- tutti i servizi esistenti devono restare individuali
- quindi capienza default = 1

---

## Scope obbligatorio

Implementare solo:

1. nuovo attributo di capienza sul servizio o, preferibilmente, sulla `service_variant`
2. aggiornamento API CRUD servizi
3. aggiornamento modello Flutter gestionale
4. aggiornamento form creazione/modifica servizio
5. aggiornamento calcolo disponibilità online
6. aggiornamento controllo finale in creazione prenotazione
7. aggiornamento schema completo e migrazione
8. test minimi di regressione

Non modificare:
- modello classi
- class_events
- class_bookings
- waitlist classi
- risorse condivise
- layout agenda
- logica cancellazione appuntamenti
- logica spostamento appuntamenti
- ricorrenze
- report, salvo eventuale compilazione se dipendono dal modello Service

---

## Dove salvare il dato

Preferire `service_variants` e non `services`.

Motivo:
- nel progetto esiste già separazione tra `services` e `service_variants`
- `services` contiene metadati generali: nome, descrizione, categoria
- `service_variants` contiene dati specifici per location: durata, prezzo, colore, bookable online
- la capienza può realisticamente variare per location

Esempio:
- stessa attività
- “Accesso sala pesi”
- sede A capienza 50
- sede B capienza 30

Campo consigliato:

```sql
parallel_capacity INT UNSIGNED NOT NULL DEFAULT 1
```

Nome accettabile alternativo:

```sql
capacity INT UNSIGNED NOT NULL DEFAULT 1
```

Usare `parallel_capacity` se si vuole evitare ambiguità con la capienza delle classi.

---

## Migrazione database

Creare una nuova migration in:

`agenda_core/config/migrations/`

Nome suggerito:

`20260427_service_variants_parallel_capacity.sql`

Contenuto richiesto:

```sql
ALTER TABLE service_variants
  ADD COLUMN parallel_capacity INT UNSIGNED NOT NULL DEFAULT 1
  COMMENT 'Numero massimo di prenotazioni contemporanee consentite per questa variante servizio nella stessa location/staff/intervallo'
  AFTER is_price_starting_from;

CREATE INDEX idx_service_variants_parallel_capacity
  ON service_variants(location_id, service_id, parallel_capacity);
```

Se l’ambiente MySQL non supporta `ADD COLUMN IF NOT EXISTS`, non usarlo, salvo pattern già adottato nel progetto.

Aggiornare anche:

`agenda_core/config/migrations/FULL_DATABASE_SCHEMA.sql`

La colonna deve comparire nella definizione di `service_variants`.

---

## Vincoli di validazione

Validare sempre lato backend:

- `parallel_capacity` obbligatorio solo internamente, mai nullable
- default = 1
- minimo = 1
- massimo consigliato = 999
- se valore mancante in input CRUD → mantenere valore esistente in update, usare 1 in create
- se valore 0, negativo, non numerico → errore validazione

Non accettare mai `NULL` come significato di “illimitato”.

La V1 non prevede capienza illimitata.

---

## Aggiornamento API servizi

Aggiornare tutti i punti in cui vengono letti o restituiti servizi/varianti.

Repository backend interessato:

`agenda_core/src/Infrastructure/Repositories/ServiceRepository.php`

Aggiungere `sv.parallel_capacity` nelle SELECT che restituiscono una variante servizio.

In particolare aggiornare almeno:

- `findById(...)`
- `findByLocationId(...)`
- eventuali metodi create/update service variant
- eventuali endpoint pubblici di booking che appiattiscono il servizio per il frontend

Il JSON restituito deve includere:

```json
{
  "parallel_capacity": 1
}
```

oppure, se il frontend usa camelCase nei model Dart:

```json
{
  "parallel_capacity": 1
}
```

mappato in Dart come `parallelCapacity`.

Non rinominare campi esistenti.

---

## Aggiornamento frontend gestionale Flutter

Aggiornare il modello `Service` o `ServiceVariant` in `agenda_backend`.

Cercare in:

- `agenda_backend/lib/core/models/service.dart`
- `agenda_backend/lib/features/services/data/services_api.dart`
- `agenda_backend/lib/features/services/data/services_repository.dart`
- dialog di creazione/modifica servizio

Aggiungere proprietà:

```dart
final int parallelCapacity;
```

Default lato Dart:

```dart
parallelCapacity: json['parallel_capacity'] as int? ?? 1
```

Quando si invia create/update servizio, includere:

```json
"parallel_capacity": <int>
```

solo nei payload dove vengono gestiti durata/prezzo/bookable online della variante.

---

## UI gestionale servizi

Nel dialog creazione/modifica servizio aggiungere campo numerico:

Label suggerita:

`Prenotazioni contemporanee`

Hint suggerito:

`1 = servizio individuale. Usa un valore maggiore per accessi o servizi condivisi.`

Validazione UI:

- obbligatorio
- intero
- minimo 1
- massimo 999

Default visibile:

`1`

Non usare switch “servizio condiviso” nella V1. Basta il campo numerico.

Per UX si può mostrare un testo helper:

`Esempio: sala pesi con capienza 50 consente fino a 50 prenotazioni sovrapposte.`

---

## Calcolo disponibilità online

Aggiornare il calcolo disponibilità oggi usato da:

`GET /v1/availability`

Nel frontend gestionale esiste già chiamata:

`GET /v1/availability?location_id=X&date=YYYY-MM-DD&service_ids=...&staff_id=...`

Il comportamento deve restare invariato per tutti i servizi con `parallel_capacity = 1`.

Per ogni slot candidato calcolare:

- `new_start_time`
- `new_end_time`
- `location_id`
- `staff_id`
- `service_id`
- `parallel_capacity`

Poi contare quante prenotazioni attive si sovrappongono.

Condizione overlap obbligatoria:

```sql
existing.start_time < new_end_time
AND existing.end_time > new_start_time
```

Query concettuale:

```sql
SELECT COUNT(*)
FROM booking_items bi
JOIN bookings b ON b.id = bi.booking_id
WHERE bi.location_id = :location_id
  AND bi.staff_id = :staff_id
  AND bi.service_id = :service_id
  AND bi.start_time < :new_end_time
  AND bi.end_time > :new_start_time
  AND b.status IN ('confirmed', 'pending')
```

Slot disponibile se:

```text
overlap_count < parallel_capacity
```

Slot non disponibile se:

```text
overlap_count >= parallel_capacity
```

Importante:
- non spezzare il tempo in slot da 5 minuti
- non creare tabelle contatore
- non salvare disponibilità residua nel DB
- calcolare sempre da `booking_items` + `bookings.status`

---

## Creazione prenotazione

Aggiornare anche il controllo finale nel POST di creazione booking.

Non basta mostrare lo slot disponibile: al momento della conferma bisogna rieseguire il controllo capienza dentro la transazione.

Flusso obbligatorio:

1. ricevi richiesta booking
2. risolvi service_variant per location
3. leggi `parallel_capacity`
4. calcola start/end
5. apri transazione
6. blocca/controlla le righe sovrapposte
7. conta overlap attivi
8. se `overlap_count >= parallel_capacity` → rollback + errore 409
9. altrimenti inserisci booking + booking_items
10. commit

Errore suggerito:

HTTP 409

```json
{
  "success": false,
  "error": {
    "code": "service_capacity_full",
    "message": "La capienza massima per questo servizio è stata raggiunta nell'orario selezionato."
  }
}
```

Non usare più `slot_conflict` quando il motivo è capienza raggiunta per servizio parallelo.

Per servizi individuali con `parallel_capacity = 1`, il comportamento può restare equivalente all’attuale conflitto slot.

---

## Logica multi-servizio

Attualmente la piattaforma supporta booking multi-servizio sequenziale.

Per la V1 mantenere questa logica.

Ogni item della prenotazione va controllato separatamente:

- servizio 1: start A / end A / capacity servizio 1
- servizio 2: start B / end B / capacity servizio 2
- ecc.

Se anche un solo item supera capienza:

- rollback intera prenotazione
- nessun booking_item creato
- errore 409

Non implementare capienza aggregata su tutta la booking.

---

## Logica staff

Non aggiungere campi allo staff.

Non aggiungere:

- `staff.capacity`
- `staff.parallel_capacity`
- `staff.max_parallel_bookings`
- `staff.concurrent_services_limit`

Lo staff rimane:

- asse agenda
- soggetto abilitato a eseguire servizi
- vincolato da staff_services
- vincolato da planning/disponibilità

La capienza parallela è del servizio/variante.

---

## Cancellazione appuntamenti

Non modificare la cancellazione.

Quando una prenotazione viene cancellata, la disponibilità torna corretta automaticamente perché il calcolo considera solo:

```sql
b.status IN ('confirmed', 'pending')
```

Quindi le prenotazioni cancellate non vengono più conteggiate.

Non introdurre contatori decrementali.

---

## Spostamento appuntamenti

Aggiornare i controlli di disponibilità usati nello spostamento appuntamento, se oggi riusano una logica diversa dal booking online.

Regola:

- quando si sposta un booking_item, il controllo capienza deve ignorare il booking_item stesso
- deve contare tutte le altre prenotazioni sovrapposte attive

Query concettuale:

```sql
AND bi.id <> :current_booking_item_id
```

oppure:

```sql
AND b.id <> :current_booking_id
```

in base a come è modellato lo spostamento.

---

## Prenotazione manuale da gestionale

Se il gestionale consente di forzare conflitti manualmente, mantenere il comportamento esistente.

Però, dove oggi viene mostrato un warning conflitto, aggiornare il messaggio per distinguere:

- conflitto staff individuale
- capienza servizio raggiunta

Nella V1 non bloccare nuove funzionalità manuali se il gestionale già consente override.

Per online booking invece non deve essere possibile superare la capienza.

---

## Performance

La query di overlap deve usare gli indici esistenti su `booking_items`.

Nel DB esiste già indice su:

```sql
booking_items(staff_id, start_time, end_time)
```

Aggiungere solo se necessario un indice più specifico:

```sql
CREATE INDEX idx_booking_items_capacity_check
ON booking_items(location_id, staff_id, service_id, start_time, end_time);
```

Valutare se aggiungerlo nella stessa migration.

Consigliato aggiungerlo perché il nuovo controllo filtra anche per `service_id`.

Migration finale consigliata:

```sql
ALTER TABLE service_variants
  ADD COLUMN parallel_capacity INT UNSIGNED NOT NULL DEFAULT 1
  COMMENT 'Numero massimo di prenotazioni contemporanee consentite per questa variante servizio nella stessa location/staff/intervallo'
  AFTER is_price_starting_from;

CREATE INDEX idx_service_variants_parallel_capacity
  ON service_variants(location_id, service_id, parallel_capacity);

CREATE INDEX idx_booking_items_capacity_check
  ON booking_items(location_id, staff_id, service_id, start_time, end_time);
```

---

## Compatibilità dati esistenti

Tutti i record esistenti devono assumere:

```text
parallel_capacity = 1
```

Nessun comportamento esistente deve cambiare.

Questo è un requisito bloccante.

---

## Test obbligatori

### Test 1 — servizio individuale invariato

Dato:
- servizio con `parallel_capacity = 1`
- prenotazione esistente 08:00 → 09:00

Quando:
- un cliente tenta 08:30 → 09:30 stesso servizio/staff/location

Allora:
- slot non disponibile
- conferma booking rifiutata
- comportamento equivalente al sistema attuale

---

### Test 2 — servizio parallelo disponibile

Dato:
- servizio con `parallel_capacity = 50`
- 49 prenotazioni sovrapposte nello stesso intervallo

Quando:
- un cliente tenta nuova prenotazione sovrapposta

Allora:
- slot disponibile
- booking confermata
- totale overlap diventa 50

---

### Test 3 — servizio parallelo pieno

Dato:
- servizio con `parallel_capacity = 50`
- 50 prenotazioni sovrapposte nello stesso intervallo

Quando:
- un cliente tenta nuova prenotazione sovrapposta

Allora:
- slot non disponibile
- POST booking risponde 409 `service_capacity_full`
- nessun record creato

---

### Test 4 — orari sfalsati

Dato:
- capienza 2
- booking A 08:15 → 09:15
- booking B 08:20 → 09:20

Quando:
- cliente tenta 09:15 → 10:15

Allora:
- deve essere consentita, perché alle 09:15 booking A non si sovrappone più
- la condizione corretta è `existing.start < new.end AND existing.end > new.start`

---

### Test 5 — cancellazione

Dato:
- capienza 2
- due prenotazioni sovrapposte confermate
- slot pieno

Quando:
- una prenotazione viene cancellata

Allora:
- una nuova prenotazione sovrapposta deve essere nuovamente consentita
- non serve nessun ricalcolo manuale

---

### Test 6 — concorrenza

Dato:
- capienza 1 o capienza quasi piena
- due richieste simultanee

Allora:
- solo una deve confermare
- l’altra deve ricevere 409
- non devono esistere più prenotazioni della capienza consentita

---

## File da cercare/modificare

### Backend PHP `agenda_core`

Cercare e aggiornare:

- `ServiceRepository.php`
- repository/use case disponibilità
- controller `GET /v1/availability`
- controller/use case `POST /v1/locations/{location_id}/bookings`
- CRUD servizi/varianti
- migration schema
- `FULL_DATABASE_SCHEMA.sql`
- eventuale documentazione API contract

Search consigliate:

```bash
grep -R "service_variants" -n src config
grep -R "slot_conflict" -n src config
grep -R "availability" -n src
grep -R "booking_items" -n src
grep -R "staff_id" -n src/Application src/Infrastructure src/Http
```

### Frontend gestionale `agenda_backend`

Cercare e aggiornare:

- `core/models/service.dart`
- `features/services/data/services_api.dart`
- `features/services/data/services_repository.dart`
- dialog creazione/modifica servizio
- eventuali generated/localizations se servono label nuove

Search consigliate:

```bash
grep -R "durationMinutes" -n lib/features/services lib/core/models
grep -R "isBookableOnline" -n lib/features/services lib/core/models
grep -R "service_variant" -n lib
grep -R "createService" -n lib/features/services
grep -R "updateService" -n lib/features/services
```

---

## Requisiti di non regressione

Non rompere:

- prenotazione online esistente
- prenotazione multi-servizio sequenziale
- selezione staff
- servizi non prenotabili online
- filtri location
- staff_services
- cancellazione appuntamenti
- spostamento appuntamenti
- calendario gestionale
- classi
- report

Tutti i servizi con `parallel_capacity = 1` devono comportarsi esattamente come prima.

---

## Terminologia UI

Italiano:

- Label: `Prenotazioni contemporanee`
- Hint: `1 = servizio individuale. Usa un valore maggiore per servizi condivisi.`
- Errore: `Inserisci un numero maggiore o uguale a 1.`

Inglese:

- Label: `Concurrent bookings`
- Hint: `1 = individual service. Use a higher value for shared services.`
- Error: `Enter a number greater than or equal to 1.`

---

## Output atteso da Codex

Codex deve produrre:

1. migration SQL nuova
2. aggiornamento `FULL_DATABASE_SCHEMA.sql`
3. backend aggiornato
4. frontend gestionale aggiornato
5. eventuali localizzazioni aggiornate
6. test o almeno checklist testabile
7. nessun cambiamento fuori scope

---

## Regola finale importante

Non introdurre un concetto di “staff che accetta X servizi simultanei”.

Il modello corretto è:

```text
service_variant.parallel_capacity = X
```

Il controllo si applica a:

```text
location_id + staff_id + service_id + intervallo temporale
```

La disponibilità è vera se:

```text
numero prenotazioni sovrapposte attive < parallel_capacity
```

