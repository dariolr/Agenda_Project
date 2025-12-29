# Decisions — agenda_core

- JWT access + refresh token (rotazione)
- Prenotazione pubblica, login solo in conferma
- snake_case
- ISO 8601
- UTC nel DB
- Idempotency-Key su POST /bookings

---

## Decisioni DB Schema MVP (2025-12-26)

### 1. Appointment vs booking_items
**Contesto**: Il backend usa il modello `Appointment` con molti campi, il frontend usa `BookingRequest` più semplice.

**Decisione**: La tabella `booking_items` unifica entrambi i modelli:
- Corrisponde a `Appointment` del gestionale
- Supporta multi-servizio come richiesto da `BookingRequest.service_ids`
- Campi legacy `extra_minutes`/`extra_minutes_type` mappati su `extra_blocked_minutes`/`extra_processing_minutes`

### 2. Service vs ServiceVariant
**Contesto**: Il backend separa `Service` (metadati) da `ServiceVariant` (durata/prezzo per location). Il frontend ha tutto in `Service`.

**Decisione**: Mantenere la separazione del backend:
- `services`: nome, descrizione, categoria
- `service_variants`: durata, prezzo, bookable_online per location
- L'API pubblica può "appiattire" i dati per il frontend se necessario

### 3. Client vs User
**Contesto**: `Client` è l'anagrafica gestionale, `User` è chi prenota online.

**Decisione (DEFINITIVA)**:
- `users`: account GLOBALI per autenticazione (email unica globale, NESSUN business_id)
- `clients`: anagrafica PER BUSINESS (ha business_id, user_id opzionale)
- Un user può essere client di più business tramite più record `clients`
- Ogni business vede esclusivamente i propri clients

**ATTENZIONE Schema DB**: La tabella `clients` usa `is_archived` (non `is_active`):
```sql
-- CORRETTO:
WHERE is_archived = 0

-- SBAGLIATO:
WHERE is_active = 1  -- colonna non esiste!
```

**JWT**:
- Contiene SOLO `user_id`
- NON contiene `business_id`
- NON contiene `location_id`

**Derivazione contesto business**:
- `location_id` viene dal PATH: `/v1/locations/{location_id}/bookings`
- `business_id` viene da lookup DB: `SELECT business_id FROM locations WHERE id = :location_id`

**Flusso creazione booking autenticato**:
1. Leggi `location_id` dal PATH
2. Ricava `business_id` dal DB
3. Cerca record `clients` con `(business_id, user_id)`
4. Se non esiste, crealo automaticamente
5. Associa `client_id` alla booking

### 4. Idempotency implementation
**Contesto**: POST /bookings deve essere idempotente senza cambiare il payload client.

**Decisione**: Colonne dedicate in `bookings`:
- `idempotency_key`: UUID dall'header `Idempotency-Key`
- `idempotency_expires_at`: TTL 24 ore
- Più semplice di tabella separata, cleanup via UPDATE (null) non DELETE

**UNIQUE constraint**: `(business_id, idempotency_key)`

Alternativa valutata: `(business_id, user_id, idempotency_key)`
- Scartata perché `user_id` può essere NULL (prenotazioni manuali)
- MySQL: `NULL != NULL` → UNIQUE non protegge i record con user_id NULL
- UUID v4 ha 122 bit casuali → collisione tra utenti diversi praticamente impossibile

Regola: il client genera UUID v4 come Idempotency-Key, il server non lo modifica.

### 5. TimeBlock vs booking_items
**Contesto**: Il backend ha `TimeBlock` per blocchi multi-staff.

**Decisione**: Tabella separata `time_blocks` + `time_block_staff`:
- Non sono booking, sono blocchi di indisponibilità
- Relazione N:M con staff (un blocco può coinvolgere più operatori)
- Più pulito di usare booking_items con flag speciale

### 6. Refresh token storage
**Contesto**: Sicurezza sessioni.

**Decisione**: 
- Mai salvare token in chiaro, solo SHA-256 hash
- Rotation: nuova sessione ad ogni refresh, vecchia revocata
- Riutilizzo token revocato → revoca TUTTE le sessioni utente (possibile furto)
- `last_used_at` per tracking, `revoked_at` per revoca esplicita

### 7. Derivazione business_id/location_id
**Contesto**: Come garantire isolamento tenant.

**Decisione (DEFINITIVA)**:
- `location_id`: dal PATH parameter per booking (`/v1/locations/{location_id}/bookings`), query param per altri endpoint
- `business_id`: lookup DB da location_id (`SELECT business_id FROM locations WHERE id = ?`)
- MAI accettare questi ID dal payload client
- MAI inserire questi ID nel JWT
- Il server li ricava autonomamente per ogni request

**Endpoint booking**:
```
POST /v1/locations/{location_id}/bookings
```

**Endpoint public**:
```
GET /v1/services?location_id={location_id}
GET /v1/staff?location_id={location_id}
GET /v1/availability?location_id={location_id}
```

**Payload booking (INVARIABILE)**:
```json
{
  "service_ids": [int],
  "staff_id": int | null,
  "start_time": "ISO8601",
  "notes": "string | null"
}
```

### 8. Naming conventions
**Decisione**: Tutti i nomi colonna in snake_case per compatibilità con i modelli Flutter esistenti. I campi JSON dei client sono VINCOLANTI e non devono essere rinominati.

### 9. Timezone gestione (2025-12-26)
**Contesto**: Il calcolo degli slot disponibili necessita del timezone corretto della location.

**Decisione**: 
- Aggiungere colonna `timezone` (VARCHAR 50) a tabella `locations`
- Default value: 'Europe/Rome'
- ComputeAvailability use case legge timezone dalla location invece di hardcoded
- Format: nomi PHP DateTimeZone (es. 'Europe/Rome', 'America/New_York')

### 10. Restrizioni servizi per staff (2025-12-26)
**Contesto**: Non tutti gli staff possono erogare tutti i servizi.

**Decisione**: Tabella `staff_services` (N:M):
- Schema: `(staff_id, service_id)` PRIMARY KEY
- Logica: se tabella vuota → staff può fare tutto (permissivo di default)
- Se esistono record per uno staff → validare che possa erogare TUTTI i servizi richiesti
- Foreign keys CASCADE su delete

### 11. Orari di apertura per location (2025-12-26)
**Contesto**: Ogni location ha orari di apertura diversi per giorno della settimana.

**Decisione**: Tabella `location_schedules`:
- Schema: `location_id`, `day_of_week` (0=Sunday, 6=Saturday), `open_time`, `close_time`, `is_closed`
- UNIQUE constraint su `(location_id, day_of_week)`
- CHECK constraints: `day_of_week BETWEEN 0 AND 6`, `open_time < close_time OR is_closed = 1`
- Fallback a orari default (9:00-18:00, Lun-Ven) se non configurato

### 12. API gestionali (2025-12-27)
**Contesto**: Il gestionale (agenda_backend) necessita di API dedicate per CRUD clients e appointments.

**Decisione**: Separazione tra API booking (pubbliche) e API gestionali:
- **Appointments endpoints** (`/v1/locations/{id}/appointments`):
  - GET con date filter per vista calendario
  - PATCH per reschedule (solo owner)
  - POST /cancel per cancellazione (solo owner)
  - Ritornano booking_items con dati joined (client, service, staff)
  
- **Clients endpoints** (`/v1/clients`):
  - GET con business_id filter + search
  - POST/PUT/DELETE con validazione business ownership
  - Soft delete via `is_archived = 1`

**Permission model**:
- Clients: visibili solo al business di appartenenza
- Appointments: modificabili solo da user che ha creato la booking

### 13. Webhook infrastructure (2025-12-27)
**Contesto**: Necessità di notificare sistemi esterni agli eventi della piattaforma.

**Decisione**: Infrastruttura webhook preparatoria:
- `webhook_endpoints`: registrazione endpoint per business + eventi sottoscritti
- `webhook_deliveries`: log tentativi con retry logic (max 3 tentativi, backoff esponenziale)
- Payload firmato con HMAC-SHA256 usando `secret` dell'endpoint
- Eventi standard: `booking.created`, `booking.updated`, `booking.cancelled`, `appointment.rescheduled`

**NON implementato ora**: dispatcher asincrono e integrazione nei flussi (milestone futura).

### 14. Mock elimination strategy (2025-01-15)
**Contesto**: I progetti frontend (agenda_backend e agenda_frontend) inizialmente usavano dati mock hardcoded per sviluppo rapido. Necessità di passare completamente a dati reali tramite API.

**Decisione architetturale**:
- **NO mock data** nei provider di produzione
- **Repository pattern**: Ogni feature ha un repository dedicato che chiama ApiClient
- **Async loading**: Provider usano FutureProvider o Notifier con async initialization per caricare dati all'avvio
- **Fallback graceful**: In caso di errore API, mostrare stato error/empty piuttosto che fallback a mock

**Implementazione business/locations**:
- Creato `BusinessRepository` (PHP) e `BusinessController` per endpoint `/v1/businesses`
- Creato `LocationsController` per endpoint `/v1/businesses/{id}/locations` e `/v1/locations/{id}`
- Esteso `ApiClient` (Dart) con metodi `getBusinesses()` e `getLocations(businessId)`
- Sostituiti provider mock con:
  - `businessRepository` → chiama API per lista businesses
  - `locationsRepository` → chiama API per locations per business
  - `currentBusinessProvider` → FutureProvider che carica business selezionato
  - `currentLocationProvider` → Notifier con `_loadLocations()` async

**Rationale**: Eliminare mock garantisce che lo sviluppo frontend scopra subito problemi di integrazione API, validazione dati, e performance. I mock rimangono solo nei test unitari dove appropriato.

### 15. Test strategy and TODO resolution (2025-01-15)
**Contesto**: TODO comments sparsi nei test indicavano test mancanti o stub da implementare.

**Decisione**:
- **Test completi nel backend PHP** (agenda_core): validation, business logic, edge cases
- **Test minimi nel frontend Flutter**: integration tests opzionali, stub per CRUD verificano solo compilazione
- **TODO → Documentation**: Tutti i TODO nei test convertiti in commenti documentativi che spiegano la strategia

**Motivazione**: Evitare duplicazione test logica tra backend e frontend. Il frontend testa principalmente UI rendering, state management, e integrazione components. La logica di business è testata exhaustivamente nel backend.

**Casi specifici risolti**:
- `updateClientForBooking()`: Documentato che API backend PATCH /appointments/{id} non supporta modifica client_id (booking property vs appointment property)
- Stub test CRUD: Documentati come placeholder per future integration tests opzionali
- Integration tests: Aggiunti commenti su come eseguirli manualmente contro backend reale

### 16. Provider loading patterns (2025-01-15)
**Contesto**: Riverpod offre FutureProvider e AsyncNotifier per loading asincrono, ma serve compatibilità con codice esistente.

**Decisione**:
- **FutureProvider**: Per liste read-only semplici (es. businesses list)
- **Notifier con async init**: Per state mutabile che richiede loading iniziale (es. locations con add/remove)
- **NO AsyncNotifier**: Evitare per compatibilità con logica sincrona esistente

**Pattern standard**:
```dart
// FutureProvider per read-only
@riverpod
Future<List<Business>> businesses(Ref ref) async {
  return ref.watch(businessRepositoryProvider).getAll();
}

// Notifier con async init per state mutabile
@riverpod
class Locations extends _$Locations {
  @override
  List<Location> build() => []; // Inizia vuoto
  
  Future<void> _loadLocations() async {
    final data = await repository.getAll();
    state = data;
  }
}
```

### 17. Multi-Business Path-Based URL (2025-12-29)
**Contesto**: SiteGround shared hosting non supporta wildcard DNS né subdomain dinamici. Serve routing multi-business.

**Problema**: `SubdomainResolver.getBusinessSlug()` usava `Uri.base.pathSegments` che è **statico** al caricamento JavaScript. Quando go_router cambiava il path, `Uri.base` non si aggiornava → loop infiniti o loading bloccato.

**Decisione**: Routing path-based con StateProvider dinamico:
- `routeSlugProvider` — StateProvider aggiornato dal router nel redirect
- `currentBusinessProvider` — Legge slug da `routeSlugProvider`, non più da `SubdomainResolver`
- Router estrae `:slug` dal path e aggiorna provider via `Future.microtask()`

**Struttura URL**:
```
/                      → Landing (no business)
/:slug                 → Redirect a /:slug/booking  
/:slug/booking         → Prenotazione
/:slug/login           → Login
/:slug/register        → Registrazione
/:slug/my-bookings     → Le mie prenotazioni
/reset-password/:token → Reset password (globale)
```

**Path riservati** (non sono slug): `reset-password`, `login`, `register`, `booking`, `my-bookings`, `change-password`, `privacy`, `terms`

**File modificati**:
- `lib/app/providers/route_slug_provider.dart` (NUOVO)
- `lib/app/router.dart` (REFACTORED)
- `lib/features/booking/providers/business_provider.dart` (usa routeSlugProvider)

**⚠️ ATTENZIONE**: NON usare `SubdomainResolver.getBusinessSlug()` per ottenere lo slug corrente. Usare sempre `ref.watch(routeSlugProvider)`.

---

## Regole di Dominio (2025-12-26)

### REGOLA DOMINIO 1 — Conflict Detection

**Principio**: Il DB NON impedisce overlap temporali. La validazione è a livello applicativo.

**Definizione conflitto**:
Un booking è in conflitto se esiste un `booking_item` tale che:
- stesso `staff_id`
- stessa `location_id`
- `start_time < new_end_time`
- `end_time > new_start_time`
- `booking.status IN ('confirmed', 'pending')`

**Implementazione obbligatoria**:
```sql
BEGIN;

-- Lock pessimistico
SELECT id FROM booking_items
WHERE staff_id = @staff_id
  AND location_id = @location_id
  AND start_time < @new_end_time
  AND end_time > @new_start_time
  AND booking_id IN (
    SELECT id FROM bookings 
    WHERE status IN ('confirmed', 'pending')
  )
FOR UPDATE;

-- Se count > 0 → ROLLBACK + HTTP 409 slot_conflict
-- Altrimenti:
INSERT INTO bookings (...) VALUES (...);
INSERT INTO booking_items (...) VALUES (...);

COMMIT;
```

---

### REGOLA DOMINIO 2 — Service Variants Resolution

**Principio**: Il client invia solo `service_ids`, mai `service_variant_id`.

**Flusso**:
1. Client invia `POST /v1/locations/{location_id}/bookings` con `service_ids: [1, 2]`
2. Server estrae `location_id` dal PATH
3. Per ogni `service_id`, server esegue lookup:
   ```sql
   SELECT id, duration_minutes, price 
   FROM service_variants
   WHERE service_id = @service_id 
     AND location_id = @location_id
     AND is_bookable_online = 1
     AND is_active = 1;
   ```
4. Server calcola `end_time` da `start_time + duration_minutes`
5. Server inserisce `booking_items` con `service_variant_id` risolto

**Constraint**: `UNIQUE (service_id, location_id)` garantisce al massimo una variant per combinazione.

**Errori**:
| Situazione | HTTP | Codice errore |
|------------|------|---------------|
| Variant non esiste per location | 400 | `service_not_available_at_location` |
| `is_bookable_online = 0` | 400 | `service_not_bookable_online` |
| `is_active = 0` | 400 | `service_not_available` |

**Motivazione**: Il frontend espone un modello `Service` semplificato con durata/prezzo diretti. La complessità delle variant per location è nascosta lato server.

---

## 17. Password Management Pattern (2025-12-27)

**Contesto**: Implementazione completa del flusso password reset e cambio password per utenti autenticati.

**Decisione**: Pattern a due fasi per password reset + endpoint dedicato per cambio password:

### Password Reset (utente non autenticato)
1. **Step 1 - Request Reset**: `POST /v1/auth/forgot-password`
   - Input: `email`
   - Output: Sempre 200 (anti email enumeration)
   - Backend: genera token (SHA-256 hash), salva in `password_reset_tokens`, invia email
   - Token validity: 1 ora

2. **Step 2 - Confirm Reset**: `POST /v1/auth/reset-password`
   - Input: `token` (da email), `password`
   - Validazione password: min 8 caratteri, maiuscola + minuscola + numero
   - Backend: verifica token non scaduto/usato, aggiorna password, invalida tutte le sessioni utente
   - Output: 200 success o 400 con error code (`invalid_reset_token`, `reset_token_expired`, `weak_password`)

### Change Password (utente autenticato)
**Endpoint**: `POST /v1/me/change-password` (richiede access token)
- Input: `current_password`, `new_password`
- Validazioni:
  - Current password corretta
  - New password != current password
  - New password rispetta policy (8 char, maiuscola, minuscola, numero)
- Output: 200 success o 400/401 error

**Frontend Implementation**:
- `/reset-password/:token` route per deep link da email
- `/change-password` route per utenti loggati
- Localizzazioni complete IT/EN
- Validazione real-time in UI

**Security**:
- Token SHA-256 hashed nel DB
- Token monouso (campo `used_at`)
- Scadenza 1 ora
- Password reset invalida tutte le sessioni (force re-login)
- Change password richiede autenticazione JWT

**Rationale**: Separare forgot/reset (pubblico, via email) da change (privato, richiede autenticazione) migliora security e UX.

---

## 18. Cancellation Policy & User Booking Management (2025-12-27)

**Contesto**: Gli utenti devono poter consultare e gestire i propri appuntamenti dal frontend pubblico. Appuntamenti passati: solo consultazione. Appuntamenti futuri: annullamento e modifica, con vincoli temporali.

**Decisione**: Implementare cancellation policy configurabile con granularità business/location + endpoint dedicato per gestione appuntamenti utente.

### Cancellation Policy Configuration

**Schema DB**:
```sql
-- businesses: policy di default per tutto il business
ALTER TABLE businesses ADD COLUMN cancellation_hours INT UNSIGNED NOT NULL DEFAULT 24;

-- locations: override opzionale per singola sede
ALTER TABLE locations ADD COLUMN cancellation_hours INT UNSIGNED NULL DEFAULT NULL;
```

**Logica**: 
- `cancellation_hours` = ore minime richieste prima dell'appuntamento per cancellare/modificare
- Valore di default: 24 ore
- Gerarchia: `location.cancellation_hours` → `business.cancellation_hours` → 24
- `cancellation_hours = 0` → nessuna cancellazione permessa
- `cancellation_hours = NULL` su location → usa policy del business

**Esempi**:
- Business con `cancellation_hours = 48`: utenti possono cancellare fino a 48h prima
- Location A con `cancellation_hours = 12`: override, solo 12h per questa sede
- Location B con `cancellation_hours = NULL`: usa il default del business (48h)

### User Booking Management API

**Endpoint**: `GET /v1/me/bookings` (richiede autenticazione)

**Response**:
```json
{
  "success": true,
  "data": {
    "upcoming": [
      {
        "id": 123,
        "status": "confirmed",
        "start_time": "2025-12-30T14:00:00+01:00",
        "end_time": "2025-12-30T15:30:00+01:00",
        "service_name": "Taglio + Piega",
        "staff_name": "Mario R.",
        "price": 45.00,
        "location": { "id": 1, "name": "Sede Centro", "address": "..." },
        "business": { "id": 1, "name": "Salone Bella Vita" },
        "can_modify": true,
        "can_modify_until": "2025-12-29T14:00:00+01:00",
        "notes": "Porta foto riferimento"
      }
    ],
    "past": [ ... ]
  }
}
```

**Campi chiave**:
- `can_modify`: `true` se ora corrente < `can_modify_until`
- `can_modify_until`: timestamp deadline calcolato da `start_time - cancellation_hours`
- Separazione `upcoming` (modificabili) vs `past` (solo consultazione)

### Validation in UpdateBooking / DeleteBooking

Entrambi i use case validano la policy prima di procedere:

```php
private function validateCancellationPolicy(array $booking): void {
    $startTime = new DateTimeImmutable($earliestStartFromItems);
    $now = new DateTimeImmutable();
    
    // Query policy con fallback
    $cancellationHours = $location->cancellation_hours 
        ?? $business->cancellation_hours 
        ?? 24;
    
    $deadline = $startTime->modify("-{$cancellationHours} hours");
    
    if ($now >= $deadline) {
        throw BookingException::validationError(
            "Cannot modify booking within {$cancellationHours} hours of start time"
        );
    }
}
```

**Errore HTTP 400**:
```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Cannot cancel booking within 24 hours of appointment start time",
    "details": {
      "cancellation_deadline": "2025-12-29T14:00:00+01:00"
    }
  }
}
```

### Frontend Implementation (agenda_frontend)

**Nuova feature**: `/my-bookings` route con:
- Lista appuntamenti futuri con badge "modificabile" basato su `can_modify`
- Lista appuntamenti passati (read-only)
- Bottoni "Annulla" e "Modifica" condizionali
- Dialog conferma cancellazione con spiegazione policy
- Form modifica che rispetta vincoli originali (staff, services, availability)

**UX**:
- Se `can_modify = false`: bottoni disabilitati + tooltip con `can_modify_until`
- Countdown visivo ore rimanenti per modifica
- Localizzazioni IT/EN complete

**Constraints su modifica**:
- Stessi vincoli della prenotazione originale (availability, staff_services, etc.)
- Non può modificare se oltre deadline
- Reschedule = delete + create (transazionale)

### Rationale

**Business flexibility**: Ogni attività ha esigenze diverse (parrucchiere 24h vs medico 48h vs massaggiatore 2h). Location override permette eccezioni (es: sede remota con policy più rigida).

**User transparency**: Frontend mostra chiaramente deadline e motivazione, evitando frustrazione.

**Backend enforcement**: Policy validata server-side, impossibile bypassare da client.

**Default sensato**: 24h copre la maggioranza dei casi, evitando configurazione obbligatoria.

---

## Decision 19: Reschedule Prenotazione (2025-12-27)

### Contesto

Gli utenti devono poter riprogrammare le proprie prenotazioni future, scegliendo nuova data/ora mantenendo gli stessi servizi e operatore.

### Soluzione Implementata

**Backend**:
- Esteso `PUT /v1/locations/{location_id}/bookings/{id}` per accettare `start_time`
- Nuovo metodo `BookingRepository::rescheduleBooking()` che:
  - Calcola offset temporale tra vecchio e nuovo start_time
  - Aggiorna tutti i `booking_items` con nuovo orario mantenendo durate
  - Preserva intervalli relativi tra servizi multipli

**Frontend**:
- Dialog `RescheduleBookingDialog` con:
  - Date picker per nuova data
  - Availability check in tempo reale
  - Selezione slot disponibili
  - Campo note opzionale
- Integrazione con `myBookingsProvider.rescheduleBooking()`
- Validazione cancellation policy (stessa logica di cancellazione)

**API Endpoint**:
```http
PUT /v1/locations/{location_id}/bookings/{id}
Authorization: Bearer <token>

{
  "start_time": "2025-12-30T14:00:00+01:00",
  "notes": "Modifica appuntamento"
}
```

**Response (200)**:
```json
{
  "success": true,
  "data": {
    "id": 123,
    "items": [
      {
        "id": 456,
        "start_time": "2025-12-30T14:00:00+01:00",
        "end_time": "2025-12-30T15:00:00+01:00",
        ...
      }
    ],
    ...
  }
}
```

### Vincoli

1. **Cancellation Policy**: Stesso vincolo di cancellazione (default 24h)
2. **Availability Check**: ✅ Verificato slot libero per staff nel nuovo orario (transazionale)
3. **Preservazione Servizi**: Non permette cambio servizi, solo data/ora
4. **Multi-Item**: Aggiorna tutti i `booking_items` mantenendo sequenza originale
5. **Transazionalità**: Operazione atomica con `FOR UPDATE` per evitare race conditions

### Rationale

**UX semplificata**: Dialog dedicato invece di flow prenotazione completo.

**Mantenimento contesto**: Stessi servizi/staff evitano complessità ricalcolo durata/prezzo.

**Consistency**: Stessa policy di cancellazione per prevedibilità utente.

**Performance**: Update diretto booking_items invece di delete + recreate.

**Race Condition Safety**: `checkConflicts()` usa `FOR UPDATE` dentro transazione.

### Implementazione Completata (2025-12-27)

✅ **Backend**:
- `UpdateBooking::validateAvailabilityForReschedule()` verifica conflitti per ogni booking_item
- Transazione wrapping check + update per atomicità
- `BookingRepository::checkConflicts()` con `FOR UPDATE` e `excludeBookingId`
- Errore HTTP 409 con dettagli conflitti se slot occupato

✅ **Frontend**:
- Dialog con availability check real-time
- Gestione errore 409 con messaggio utente

### TODO

- [ ] Test edge case: reschedule con servizi multipli sovrapposti
- [ ] Email notifica reschedule (richiede M10)

---

## Decision 20: Distinzione Reschedule Client vs Gestionale (2025-12-27)

### Contesto

L'applicazione ha due frontend diversi:
- **agenda_frontend** (cliente): utente finale prenota e gestisce i propri appuntamenti
- **agenda_backend** (gestionale): staff e admin gestiscono tutti gli appuntamenti

### Problema

Come gestire il reschedule (spostamento) di appuntamenti nei due contesti?

### Soluzione: Due Pattern Distinti

| App | Endpoint | Granularità | Motivo |
|-----|----------|-------------|--------|
| **agenda_frontend** | `PUT /v1/locations/{id}/bookings/{id}` | Intera prenotazione | Cliente vede la prenotazione come unità atomica |
| **agenda_backend** | `PATCH /v1/locations/{id}/appointments/{id}` | Singolo appuntamento | Staff ha flessibilità per riorganizzare i singoli slot |

### Esempi Pratici

**Scenario Cliente**:
Mario ha prenotato "Taglio + Piega" alle 14:00. Vuole spostare a domani.
→ Usa `PUT /bookings/{id}` con `start_time` → entrambi i servizi si spostano insieme.

**Scenario Staff**:
Anna deve spostare solo la "Piega" di Mario alle 16:00 perché lo slot era già occupato.
→ Usa `PATCH /appointments/{id}` → sposta solo quel servizio, il "Taglio" resta.

### Implementazione

**Backend (agenda_core)**:
```php
// PUT /bookings/{id} - Reschedule intero booking
if (isset($data['start_time'])) {
    $this->validateAvailabilityForReschedule($booking, $newStartTime);
    $this->bookingRepo->rescheduleBooking($bookingId, $newStartTime);
}

// PATCH /appointments/{id} - Reschedule singolo appointment
$this->appointmentRepo->updateAppointment($appointmentId, $startTime, $endTime, $staffId);
```

**Frontend Cliente (agenda_frontend)**:
- `MyBookingsProvider.rescheduleBooking()` → chiama PUT con `start_time`
- Dialog unico per scegliere nuova data/ora
- Tutti i servizi si spostano automaticamente

**Gestionale (agenda_backend)**:
- `AppointmentsProvider.moveAppointment()` → chiama PATCH
- Drag & drop singolo appuntamento
- Flessibilità totale per staff

### Rationale

1. **UX appropriata per ruolo**:
   - Cliente: semplicità, non deve gestire dettagli operativi
   - Staff: controllo granulare per ottimizzare agenda

2. **Backwards compatibility**:
   - Gestionale già usa PATCH /appointments (non cambia nulla)
   - PUT /bookings con start_time è additive

3. **Conflict detection**:
   - Entrambi i flussi verificano availability
   - FOR UPDATE lock evita race conditions

4. **Coerenza dati**:
   - Client vede sempre booking come unità
   - Staff può intervenire su singoli item se necessario

### Vincoli

- Il cliente **non** può modificare singoli servizi (solo annullare o spostare tutto)
- Lo staff **può** modificare singoli servizi ma deve gestire manualmente la coerenza
- Reschedule cliente soggetto a cancellation policy
- Reschedule staff **non** soggetto a policy (può sempre modificare)

---

## Decision 21: Sistema Permessi Operatori Gestionale (2025-12-28)

### Contesto
Il gestionale (agenda_backend) necessita di un sistema di autenticazione e autorizzazione per gli operatori. Attualmente:
- Gli utenti (`users`) sono globali e non hanno relazione diretta con i business
- I `clients` collegano utenti ai business, ma sono per chi prenota, non per chi gestisce
- Lo `staff` è anagrafica dipendenti, senza credenziali di login

### Problema
Come assegnare un utente (che può fare login) a uno o più business con permessi specifici?

### Decisione
Creare tabella `business_users` che collega `users` a `businesses` con ruoli e permessi.

### Schema
```sql
CREATE TABLE business_users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    role ENUM('owner', 'admin', 'manager', 'staff') DEFAULT 'staff',
    staff_id INT UNSIGNED NULL,  -- Link opzionale a record staff
    can_manage_bookings TINYINT(1) DEFAULT 1,
    can_manage_clients TINYINT(1) DEFAULT 1,
    can_manage_services TINYINT(1) DEFAULT 0,
    can_manage_staff TINYINT(1) DEFAULT 0,
    can_view_reports TINYINT(1) DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,
    invited_by INT UNSIGNED NULL,
    invited_at TIMESTAMP NULL,
    accepted_at TIMESTAMP NULL,
    UNIQUE (business_id, user_id)
);

-- Superadmin flag in users table
ALTER TABLE users ADD COLUMN is_superadmin TINYINT(1) DEFAULT 0;
```

### Modello Enterprise (Admin Platform)
Il sistema usa il modello **Enterprise** dove:
- **Superadmin** (globale) gestisce la piattaforma, non è legato a business specifici
- **Owner** gestisce il proprio business e invita operatori
- Nessuna self-registration di business

### Superadmin: Ruolo Globale

Il superadmin **NON ha record in `business_users`**. È un flag globale su `users.is_superadmin`.

**Comportamento:**
- Vede lista di TUTTI i business (con ricerca/filtri)
- Può creare nuovi business
- Può eliminare business
- Quando seleziona un business → opera come **admin** (accesso completo)
- Non appare nella lista operatori del business

```
┌─────────────────────────────────────────────────────────┐
│              SUPERADMIN (users.is_superadmin = 1)       │
│  Scope: GLOBALE (nessun record in business_users)       │
├─────────────────────────────────────────────────────────┤
│  • GET /v1/admin/businesses → Lista TUTTI i business    │
│  • POST /v1/admin/businesses → Crea business            │
│  • DELETE /v1/admin/businesses/{id} → Elimina           │
│  • Seleziona business → entra come admin                │
└─────────────────────────────────────────────────────────┘
```

### Gerarchia Ruoli (per business)

| Ruolo | Scope | Descrizione |
|-------|-------|-------------|
| **owner** | Business | Proprietario, controllo totale |
| **admin** | Business | Come owner, ma non può eliminare business |
| **manager** | Business | Gestisce appuntamenti, clienti, orari |
| **staff** | Business | Solo propri appuntamenti |

### Chi Può Assegnare Ruoli

| Assigner | Può Creare |
|----------|------------|
| superadmin | owner (alla creazione business) |
| owner | owner, admin, manager, staff |
| admin | admin, manager, staff |
| manager | ❌ |
| staff | ❌ |

### API Endpoints

```
# Superadmin only (is_superadmin = true)
GET /v1/admin/businesses              → Lista tutti i business (con search)
POST /v1/admin/businesses             → Crea nuovo business + owner
DELETE /v1/admin/businesses/{id}      → Elimina business
GET /v1/admin/businesses/{id}         → Entra come admin

# Authenticated users (business_users)
GET /v1/me/businesses                 → Lista business dove user ha accesso
GET /v1/me/businesses/{id}            → Dettaglio business con ruolo/permessi

# Owner/Admin only
POST /v1/businesses/{id}/users        → Invita nuovo operatore
PUT /v1/businesses/{id}/users/{id}    → Modifica ruolo/permessi
DELETE /v1/businesses/{id}/users/{id} → Rimuovi accesso
```

### Flusso Superadmin

```
1. POST /v1/auth/login → JWT con user_id
2. Server verifica is_superadmin = true
3. GET /v1/admin/businesses?search=salone → Lista filtrata
4. Click su business → GET /v1/admin/businesses/{id}
5. Da qui opera come admin (bypass business_users check)
```

### Flusso Operatore Normale

```
1. POST /v1/auth/login → JWT con user_id
2. GET /v1/me/businesses → Lista da business_users
3. Seleziona business → salva currentBusinessId
4. Middleware valida accesso tramite business_users
```

### Middleware Access Check

```php
// Pseudocode per validazione accesso
function checkBusinessAccess($userId, $businessId): string {
    // 1. Superadmin bypassa tutto
    if ($this->userRepo->isSuperadmin($userId)) {
        return 'admin'; // Opera come admin
    }
    
    // 2. Verifica business_users
    $businessUser = $this->businessUserRepo->find($userId, $businessId);
    if (!$businessUser || !$businessUser['is_active']) {
        throw AuthException::forbidden('No access to this business');
    }
    
    return $businessUser['role'];
}
```

### Link Staff-User (opzionale)
Campo `staff_id` permette di collegare un operatore al suo record staff:
- Utile per mostrare solo il proprio calendario
- Permette "login as staff" per operatori singoli
- Se NULL, l'operatore vede tutto il team

### Migration
Inclusa in: `migrations/FULL_DATABASE_SCHEMA.sql` (sezione BUSINESS USERS)

### Impatto Frontend (agenda_backend)
1. Creare `features/auth/` con login/logout
2. Modificare `businessesProvider` per usare `/v1/me/businesses`
3. Aggiungere route guard per redirect a login
4. Salvare `currentBusinessId` dopo selezione

### 21. Sistema inviti via email (2025-12-28)
**Contesto**: Gli operatori devono essere invitati tramite email invece di essere aggiunti direttamente.

**Decisione**: Tabella `business_invitations` separata:
- Token univoco 64 caratteri (hex)
- Scadenza 7 giorni default
- Status: `pending`, `accepted`, `expired`, `revoked`
- Constraint: un solo invito pending per (business_id, email)

**Flusso invito**:
1. Owner/Admin crea invito con email + ruolo desiderato
2. Sistema genera token, salva in `business_invitations`
3. Email inviata con link `https://app/invite/{token}`
4. Destinatario apre link, fa login o register
5. `POST /v1/invitations/{token}/accept` verifica email match e crea record `business_users`

**Gerarchia ruoli per inviti**:
- Owner può invitare: admin, manager, staff
- Admin può invitare: manager, staff
- Manager può invitare: staff
- Staff non può invitare

**Migration**: Inclusa in `FULL_DATABASE_SCHEMA.sql` (sezione BUSINESS INVITATIONS)

### 22. Frontend integration operators (2025-12-28)
**Contesto**: Il gestionale (agenda_backend) necessita di UI per gestire operatori.

**Decisione**: Struttura modulare nella feature `business/`:
- **Modelli** in `core/models/`: `BusinessUser`, `BusinessInvitation`
- **Repository** in `features/business/data/`: `BusinessUsersRepository`
- **Provider** in `features/business/providers/`: `businessUsersProvider(businessId)` con Riverpod 3.x
- **UI** in `features/business/presentation/`:
  - `OperatorsScreen` - lista operatori + inviti pendenti
  - `dialogs/InviteOperatorDialog` - dialog/sheet per invitare
  - `dialogs/RoleSelectionDialog` - dialog/sheet per cambiare ruolo

**Pattern responsive**:
- Desktop: `showDialog()` con `AppFormDialog`
- Mobile/Tablet: `AppBottomSheet.show()` con sheet dedicati

**Localizzazione**: Chiavi `operators*` in `intl_it.arb` e `intl_en.arb`

### 23. Testing strategy (2025-12-28)
**Contesto**: M8 richiede test minimi per validare logica di business.

**Decisione**: Test PHPUnit focalizzati su logica pura, senza mock di classi `final`.

**Struttura test suite**:
```
tests/
├── AuthTest.php           # JWT, password hashing base
├── AuthUseCaseTest.php    # Validazione auth, sessioni, email
├── BookingTest.php        # Slot overlap, date validation
├── BookingUseCaseTest.php # Conflict detection, idempotency, durata
├── AvailabilityTest.php   # Slot generation, working hours, timezone
├── ExceptionsTest.php     # Auth e Booking exceptions
├── IdempotencyTest.php    # UUID v4 validation
├── PasswordHasherTest.php # Bcrypt security
├── RequestTest.php        # HTTP request parsing
├── ResponseTest.php       # HTTP response formatting
└── RouterTest.php         # Routing e middleware
```

**Pattern adottati**:
- Classi repository sono `final` → NO mock, test della logica pura
- Test di validazione indipendenti dal DB
- Test di calcolo (durata, slot, conflict) con dati in memoria
- Setup JWT_SECRET in `setUp()` / `tearDown()`

**Risultato**: 98 test, 195 asserzioni, 100% pass

**Comandi**:
```bash
# Eseguire tutti i test
./vendor/bin/phpunit --testdox

# Eseguire test specifici
./vendor/bin/phpunit --filter AuthUseCaseTest
```

---

## Vincoli e Divieti

### VIETATO
- Aggiungere `business_id` a `users`
- Inserire `business_id` o `location_id` nel JWT
- Richiedere `business_id` o `location_id` nel payload
- Rinominare colonne esistenti
- Modificare il payload booking
- Implementare booking prima dell'autenticazione
- Spostare logica di dominio nel frontend
- Permettere self-registration di business (modello Enterprise)

### OBBLIGATORIO
- `location_id` nel PATH per ogni request business-scoped
- `business_id` ricavato via lookup DB da `location_id`
- Query gestionali filtrate per `clients.business_id`
- Creazione automatica record `clients` al primo booking autenticato
- Validazione `business_users` per API gestionali (M11+)

---

## Ordine Implementazione

1. **M1 Auth**: login, refresh token con rotazione, me, logout
2. **M2 Public browse**: services, staff, availability
3. **M3 Booking**: POST /v1/locations/{location_id}/bookings (protetto)
4. **M4 Gestionale**: compatibilità con backend esistente
5. **M11 Permessi operatori**: business_users, auth gestionale

---

## M10 Notification System - Decisione Architetturale (2025-12-28)

### Contesto
Necessità di inviare notifiche email per il ciclo di vita delle prenotazioni (conferma, cancellazione, reminder) su hosting condiviso (SiteGround) con budget limitato.

### Decisione: Architettura Multi-Provider con Strategy Pattern

**Provider selezionabile via `.env`**:
```ini
MAIL_PROVIDER=brevo  # smtp | brevo | mailgun
```

**Motivazioni**:
1. **Vendor lock-in evitato**: Cambio provider con modifica singola variabile
2. **Fallback progression**: Brevo API → Brevo SMTP → errore
3. **Testing semplificato**: Provider sostituibile in test
4. **Costi ottimizzati**: Brevo free tier 300/giorno sufficiente per MVP

### Gerarchia Email Sender (priorità)

| Priorità | Fonte | Esempio |
|----------|-------|---------|
| **1° (alta)** | `locations.email` | `sede.roma@salonemario.it` |
| **2°** | `businesses.email` | `info@salonemario.it` |
| **3° (fallback)** | `.env MAIL_FROM_*` | `noreply@romeolab.it` |

**Logica implementata**:
```php
$fromEmail = $variables['sender_email'] 
    ?? $variables['location_email'] 
    ?? $variables['business_email'] 
    ?? null;  // null = usa .env fallback
```

Questo permette:
- **Multi-sede**: ogni sede può avere email dedicata
- **Multi-business**: ogni business può avere email dedicata
- **Fallback sicuro**: se nessuna email configurata, usa quella del `.env`

### Alternativa considerata: Provider unico (SMTP)
**Scartata perché**:
- SiteGround SMTP ha limiti di invio (100/ora)
- Nessun tracking deliverability
- Nessun retry automatico

### Alternativa considerata: Invio sincrono
**Scartata perché**:
- Booking POST bloccato durante invio email
- Timeout se SMTP lento
- Nessun retry su errore temporaneo

### Implementazione scelta: Coda asincrona
- `notification_queue` con status, retry_count, scheduled_at
- Worker via cron (ogni minuto)
- Notifiche non bloccano flusso principale
- Retry automatico con backoff

### File implementati
```
src/Infrastructure/Notifications/
├── EmailProviderInterface.php
├── SmtpProvider.php
├── BrevoProvider.php
├── MailgunProvider.php
├── EmailService.php (factory)
└── EmailTemplateRenderer.php

src/Infrastructure/Notifications/
└── NotificationRepository.php

src/UseCases/Notifications/
├── QueueBookingConfirmation.php
├── QueueBookingCancellation.php
└── QueueBookingReminder.php

bin/
├── notification-worker.php
├── queue-reminders.php
├── run-worker.sh
└── run-reminders.sh

migrations/
└── FULL_DATABASE_SCHEMA.sql  # Include notification_queue, notification_templates, notification_settings
```

### Cron setup produzione
```bash
# Processa coda ogni minuto (usa wrapper per portabilità PHP path)
* * * * * /path/to/agenda_core/bin/run-worker.sh

# Accoda reminder ogni ora
0 * * * * /path/to/agenda_core/bin/run-reminders.sh
```

### Configurazione .env
```ini
MAIL_PROVIDER=brevo
BREVO_API_KEY=xkeysib-xxxxx
BREVO_SMTP_KEY=xsmtpsib-xxxxx
MAIL_FROM_ADDRESS=noreply@tuodominio.it
MAIL_FROM_NAME="Agenda"
```

### Frontend (agenda_backend)
- Campo email aggiunto al dialog modifica location
- Localizzazioni: `teamLocationEmailLabel`, `teamLocationEmailHint`


