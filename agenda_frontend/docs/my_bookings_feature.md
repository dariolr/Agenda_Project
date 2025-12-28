# Feature: Gestione Prenotazioni Utente

## Panoramica

Implementata la funzionalità completa di gestione prenotazioni per gli utenti registrati su **agenda_frontend**.

## Funzionalità implementate

### 1. Visualizzazione Prenotazioni (GET /v1/me/bookings)

- **Due tab separati**:
  - **Prossime**: Prenotazioni future con possibilità di modifica/cancellazione
  - **Passate**: Prenotazioni completate (solo consultazione)

- **Informazioni visualizzate per ogni prenotazione**:
  - Nome business e location
  - Servizi prenotati
  - Data e orario (inizio/fine)
  - Note opzionali
  - Badge stato modificabilità (verde/arancio)

### 2. Cancellazione Prenotazioni (DELETE /v1/locations/{location_id}/bookings/{id})

- **Validazione server-side con Cancellation Policy**:
  - Configurabile per business (default 24h) e location (override opzionale)
  - Controllo automatico: impossibile cancellare se meno di X ore dall'appuntamento
  - Errore HTTP 400 con deadline preciso in caso di violazione

- **UI**:
  - Pulsante "Annulla" visibile solo se `can_modify === true`
  - Dialog di conferma prima della cancellazione
  - Feedback immediato (SnackBar verde/rosso)
  - Rimozione ottimistica dalla lista locale

### 3. Countdown Modifica

- **Calcolo dinamico tempo rimanente**:
  - `can_modify_until` timestamp fornito dal backend
  - Formattazione intelligente:
    - `>24h`: "Modificabile fino a X giorni"
    - `1-24h`: "Modificabile fino a X ore"
    - `<1h`: "Modificabile fino a X minuti"

### 4. Modifica Prenotazioni (TODO)

- Pulsante "Modifica" presente ma non ancora implementato
- Mostra SnackBar "Funzione in sviluppo"
- Da collegare a flow di reschedule con verifica disponibilità

## Architettura

### Frontend (agenda_frontend)

```
lib/
├── core/
│   ├── models/
│   │   └── booking_item.dart          # Modello BookingItem
│   ├── network/
│   │   ├── api_client.dart            # getMyBookings(), deleteBooking(), updateBooking()
│   │   └── api_config.dart            # Endpoint /v1/me/bookings
│   └── l10n/
│       └── intl_it.arb                # Localizzazioni IT (30 chiavi totali)
└── features/
    └── booking/
        ├── providers/
        │   └── my_bookings_provider.dart  # State management (cancel + reschedule)
        └── presentation/
            ├── dialogs/
            │   └── reschedule_booking_dialog.dart  # Dialog reschedule
            └── screens/
                └── my_bookings_screen.dart  # UI completa

app/
└── router.dart                        # Rotta /my-bookings
```

### Backend (agenda_core)

```
src/
├── Http/
│   ├── Controllers/
│   │   └── BookingsController.php    # myBookings(), destroy(), update()
│   └── Kernel.php                     # Route GET /v1/me/bookings
├── UseCases/
│   ├── Booking/
│   │   ├── GetMyBookings.php         # Use case prenotazioni utente
│   │   ├── UpdateBooking.php         # Reschedule + validazione policy
│   │   └── DeleteBooking.php         # Validazione cancellation policy
└── Infrastructure/
    ├── Repositories/
    │   └── BookingRepository.php     # rescheduleBooking() method
    └── Migrations/
        └── FULL_DATABASE_SCHEMA.sql  # Include cancellation_hours

docs/
├── decisions.md                       # Decision 18 + Decision 19 (Reschedule)
├── api_contract_v1.md                 # GET /v1/me/bookings + PUT reschedule
└── db_schema_mvp.md                   # cancellation_hours schema
```

## Database Schema (cancellation_hours)

```sql
-- businesses table
ALTER TABLE businesses 
ADD COLUMN cancellation_hours INT UNSIGNED DEFAULT 24 NOT NULL
AFTER timezone;

-- locations table  
ALTER TABLE locations 
ADD COLUMN cancellation_hours INT UNSIGNED NULL DEFAULT NULL
AFTER timezone;
```

**Logica di fallback**:
1. Se `locations.cancellation_hours IS NOT NULL` → usa valore location
2. Altrimenti → usa `businesses.cancellation_hours` (default 24)
3. Valore `0` = nessuna restrizione di cancellazione

## API Response Example

```json
{
  "success": true,
  "data": {
    "upcoming": [
      {
        "id": 123,
        "business_id": 1,
        "business_name": "Salone Bella Vita",
        "location_id": 1,
        "location_name": "Sede Centro",
        "service_names": ["Taglio", "Piega"],
        "start_time": "2025-12-30T14:00:00+01:00",
        "end_time": "2025-12-30T15:30:00+01:00",
        "notes": "Preferisco appuntamento pomeridiano",
        "can_modify": true,
        "can_modify_until": "2025-12-29T14:00:00+01:00"
      }
    ],
    "past": [...]
  }
}
```

## Localizzazioni aggiunte (30 chiavi totali)

```
myBookings
upcomingBookings
pastBookings
noUpcomingBookings
noPastBookings
errorLoadingBookings
modifiable
notModifiable
modifiableUntilDays (plurale)
modifiableUntilHours (plurale)
modifiableUntilMinutes (plurale)
modify
cancel
yes
no
cancelBookingTitle
cancelBookingConfirm
bookingCancelled
bookingCancelFailed
modifyNotImplemented (deprecato)
rescheduleBookingTitle
currentBooking
selectNewDate
selectDate
selectNewTime
confirmReschedule
bookingRescheduled
```

## Navigazione

- **Icona nella AppBar di BookingScreen** (solo se autenticato):
  - `Icons.event_note`
  - Tooltip: "Le mie prenotazioni"
  - Naviga a `/my-bookings`

## Testing

### Test manuali da eseguire:

1. **Visualizzazione**:
   - [ ] Login e navigazione a /my-bookings
   - [ ] Verifica tab "Prossime" con prenotazioni future
   - [ ] Verifica tab "Passate" con prenotazioni completate
   - [ ] Verifica badge verde/arancio su prenotazioni modificabili

2. **Cancellazione**:
   - [ ] Cancellazione prenotazione modificabile (>24h dall'inizio)
   - [ ] Tentativo cancellazione entro deadline (<24h) → HTTP 400
   - [ ] Dialog di conferma funzionante
   - [ ] SnackBar di successo/errore

3. **Reschedule (Riprogrammazione)**:
   - [ ] Click "Modifica" su prenotazione modificabile
   - [ ] Apertura dialog RescheduleBookingDialog
   - [ ] Selezione nuova data e verifica availability check
   - [ ] Selezione nuovo slot disponibile
   - [ ] Conferma modifica → HTTP 200
   - [ ] Verifica aggiornamento prenotazione in lista
   - [ ] Tentativo reschedule entro deadline (<24h) → HTTP 400

4. **Countdown**:
   - [ ] Verifica formattazione "X giorni" per >24h
   - [ ] Verifica formattazione "X ore" per 1-24h
   - [ ] Verifica formattazione "X minuti" per <1h

5. **Responsive**:
   - [ ] Test su mobile (tab touch)
   - [ ] Test su tablet
   - [ ] Test su desktop

## Prossimi sviluppi

1. **Availability Check Backend**:
   - ✅ Frontend implementato con availability check
   - ⚠️ Backend: Integrare verifica conflitti in `UpdateBooking::execute()`
   - Verificare staff disponibile nel nuovo slot
   - Gestire conflitti con prenotazioni esistenti

2. **Notifiche**:
   - Email di conferma cancellazione
   - Email notifica reschedule
   - Reminder automatici prima dell'appuntamento
   - (Milestone M10 documentato)

3. **Filtri avanzati**:
   - Ricerca per business/location
   - Filtro per status (confirmed, cancelled, etc.)
   - Ordinamento personalizzato

4. **Miglioramenti UX**:
   - Mostrare preview durata totale in reschedule dialog
   - Calcolo automatico prezzo se cambia data (prezzi time-based)
   - Supporto cambio servizi durante reschedule

## Note implementative

- **Provider Riverpod**: `MyBookingsNotifier` con stato immutabile
- **Gestione errori**: Try-catch con state.error per UI feedback
- **Ottimizzazione**: 
  - Rimozione ottimistica dalla lista per cancellazione
  - Update ottimistico per reschedule
- **Reschedule Logic**:
  - Dialog dedicato con availability check real-time
  - Calcolo offset temporale mantenendo durate servizi
  - Preservazione sequenza multi-servizio
- **Accessibilità**: Tooltip e label semantici per screen reader
- **Pattern**: Repository pattern via ApiClient centralizzato

## Comandi utili

```bash
# Code generation (dopo modifiche provider)
dart run build_runner build --delete-conflicting-outputs

# Localizzazione (dopo modifiche .arb)
dart run intl_utils:generate

# Analisi codice
flutter analyze

# Migrazione DB backend (schema completo)
mysql -u root -p agenda_db < agenda_core/migrations/FULL_DATABASE_SCHEMA.sql
```

## Riferimenti

- **Decision Backend**: `agenda_core/docs/decisions.md` #18 (Cancellation Policy), #19 (Reschedule)
- **API Contract**: `agenda_core/docs/api_contract_v1.md` (GET /v1/me/bookings, PUT reschedule)
- **DB Schema**: `agenda_core/docs/db_schema_mvp.md` (cancellation_hours)
- **Agents Instructions**: `agenda_frontend/.github/copilot-instructions.md`
- **Migration**: `agenda_core/migrations/FULL_DATABASE_SCHEMA.sql`

## Changelog

### 2025-12-27 — Reschedule Implementation

**Backend**:
- ✅ Esteso `PUT /v1/locations/{location_id}/bookings/{id}` per accettare `start_time`
- ✅ Nuovo metodo `BookingRepository::rescheduleBooking()` con calcolo offset temporale
- ✅ Validazione cancellation policy in `UpdateBooking::execute()`
- ✅ Aggiornato `BookingsController::update()` per supportare reschedule
- ⚠️ TODO: Availability check in `UpdateBooking` (verifica conflitti)

**Frontend**:
- ✅ Dialog `RescheduleBookingDialog` con date picker e slot selection
- ✅ Metodo `myBookingsProvider.rescheduleBooking()`
- ✅ Integrazione availability API per slot disponibili
- ✅ 7 nuove localizzazioni IT
- ✅ Update ottimistico lista prenotazioni

**Documentazione**:
- ✅ Decision 19 aggiunta a `decisions.md`
- ✅ API contract aggiornato con esempio reschedule
- ✅ Feature doc aggiornata con testing reschedule

### 2025-12-26 — Initial Release

- ✅ Visualizzazione prenotazioni (upcoming/past)
- ✅ Cancellazione con cancellation policy
- ✅ Schema cancellation_hours incluso in FULL_DATABASE_SCHEMA.sql
- ✅ Decision 18 documentata
- ✅ 23 localizzazioni IT base

