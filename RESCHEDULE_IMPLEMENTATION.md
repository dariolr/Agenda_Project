# Reschedule Implementation Summary

## 🎯 Obiettivi Completati

✅ **Implementazione reschedule prenotazione** con availability check  
✅ **Migration database** documentata (esecuzione manuale richiesta)  
✅ **Documentazione aggiornata** (decisions.md, api_contract_v1.md, feature docs)

---

## 📦 Componenti Implementati

### Backend (agenda_core)

#### 1. Database Layer
**File**: `src/Infrastructure/Repositories/BookingRepository.php`
- Nuovo metodo `rescheduleBooking()`
- Calcola offset temporale tra vecchio e nuovo start_time
- Aggiorna tutti i `booking_items` mantenendo durate e intervalli

#### 2. Use Case Layer
**File**: `src/UseCases/Booking/UpdateBooking.php`
- Esteso per supportare `start_time` nel payload
- Validazione formato ISO8601
- Chiamata a `rescheduleBooking()` se presente `start_time`
- Validazione cancellation policy (stesso vincolo di DELETE)

#### 3. Controller Layer
**File**: `src/Http/Controllers/BookingsController.php`
- Metodo `update()` esteso per accettare `start_time`
- Validazione payload: almeno un campo tra `status`, `notes`, `start_time`

#### 4. API Endpoint
```http
PUT /v1/locations/{location_id}/bookings/{id}
Authorization: Bearer <token>

{
  "start_time": "2025-12-30T14:00:00+01:00",
  "notes": "Riprogrammazione appuntamento"
}
```

---

### Frontend (agenda_frontend)

#### 1. API Client
**File**: `lib/core/network/api_client.dart`
- Nuovo metodo `updateBooking()` per PUT reschedule
- Parametri: `locationId`, `bookingId`, `startTime`, `notes?`

#### 2. Provider
**File**: `lib/features/booking/providers/my_bookings_provider.dart`
- Nuovo metodo `rescheduleBooking()`
- Update ottimistico lista prenotazioni dopo successo
- Gestione errori con state.error

#### 3. UI Dialog
**File**: `lib/features/booking/presentation/dialogs/reschedule_booking_dialog.dart`
- Date picker per nuova data
- Availability check in tempo reale (`getAvailability`)
- Lista slot disponibili (ChoiceChip)
- Campo note opzionale
- Validazione: disabilita conferma se slot non selezionato

#### 4. Screen Integration
**File**: `lib/features/booking/presentation/screens/my_bookings_screen.dart`
- Pulsante "Modifica" apre `RescheduleBookingDialog`
- SnackBar feedback successo/errore
- Condizionale su `booking.canModify`

#### 5. Localizzazioni
**File**: `lib/core/l10n/intl_it.arb`
- `rescheduleBookingTitle`: "Riprogramma prenotazione"
- `currentBooking`: "Prenotazione attuale"
- `selectNewDate`: "Seleziona nuova data"
- `selectNewTime`: "Seleziona nuovo orario"
- `confirmReschedule`: "Conferma modifica"
- `bookingRescheduled`: "Prenotazione riprogrammata con successo"
- `selectDate`: "Seleziona data"

---

## 📄 Documentazione Aggiornata

### 1. decisions.md
**File**: `agenda_core/docs/decisions.md`
- **Decision 19**: Reschedule Prenotazione
- Contesto, soluzione, vincoli, rationale
- TODO list per availability check backend

### 2. api_contract_v1.md
**File**: `agenda_core/docs/api_contract_v1.md`
- Aggiunto **Use Case 2: Reschedule** per PUT endpoint
- Esempio request con `start_time`
- Note implementative e TODO
- Error 400 per cancellation policy violation

### 3. my_bookings_feature.md
**File**: `agenda_frontend/docs/my_bookings_feature.md`
- Architettura aggiornata con `reschedule_booking_dialog.dart`
- Test manuali reschedule (sezione 3)
- Prossimi sviluppi con priorità availability check
- Changelog completo (2025-12-27)

### 4. 0012_cancellation_policy.sql
**File**: `agenda_core/migrations/0012_cancellation_policy.sql`
- Aggiunto commento EXECUTION con comando MySQL
- Note per trovare percorso MySQL se non in PATH

---

## ⚠️ Azione Richiesta: Migration Database

La migration **0012_cancellation_policy.sql** NON è stata eseguita automaticamente (MySQL non trovato nel PATH).

### Esecuzione Manuale

```bash
# Opzione 1: Se MySQL è installato
mysql -u root -p agenda_db < agenda_core/migrations/0012_cancellation_policy.sql

# Opzione 2: Trova percorso MySQL
find /usr/local -name mysql 2>/dev/null

# Opzione 3: Con Homebrew
brew --prefix mysql
# Poi: /percorso/completo/mysql -u root -p agenda_db < migration.sql
```

### Cosa Aggiunge la Migration

```sql
-- Businesses: campo cancellation_hours (default 24)
ALTER TABLE businesses 
ADD COLUMN cancellation_hours INT UNSIGNED NOT NULL DEFAULT 24;

-- Locations: campo cancellation_hours (NULL = usa business default)
ALTER TABLE locations 
ADD COLUMN cancellation_hours INT UNSIGNED NULL DEFAULT NULL;

-- Index per performance
ALTER TABLE locations
ADD KEY idx_locations_cancellation (business_id, cancellation_hours);
```

---

## 🔍 Testing Checklist

### Backend
- [ ] Eseguire migration 0012_cancellation_policy.sql
- [ ] Verificare campi `cancellation_hours` in businesses/locations
- [ ] Test PUT reschedule con `start_time` valido
- [ ] Test reschedule entro deadline → HTTP 400
- [ ] Test reschedule con formato `start_time` invalido → HTTP 400

### Frontend
- [ ] Login e navigazione a /my-bookings
- [ ] Click "Modifica" su prenotazione modificabile
- [ ] Verifica apertura RescheduleBookingDialog
- [ ] Selezione nuova data e verifica caricamento slot
- [ ] Selezione slot disponibile
- [ ] Conferma modifica → verifica aggiornamento lista
- [ ] Test reschedule entro deadline → verifica messaggio errore

---

## 📋 TODO Rimanenti

### Alta Priorità
- [ ] **Availability Check Backend**: Integrare verifica conflitti in `UpdateBooking::execute()`
  - Verificare staff disponibile nel nuovo slot
  - Gestire conflitti con prenotazioni esistenti
  - Usare `BookingRepository::checkConflicts()` con `FOR UPDATE`

### Media Priorità
- [ ] Recuperare `service_ids` da `BookingItem` per availability check accurato
- [ ] Test edge case: reschedule con multi-servizio sovrapposti
- [ ] Gestione timezone in reschedule dialog

### Bassa Priorità
- [ ] Email notifica reschedule (richiede M10)
- [ ] Preview durata totale in dialog
- [ ] Supporto cambio servizi durante reschedule

---

## 🎨 UX Flow

```
MyBookingsScreen
    ↓ (user click "Modifica" su booking modificabile)
RescheduleBookingDialog
    ↓ (user seleziona data)
API getAvailability(locationId, date, serviceIds)
    ↓ (backend ritorna slot disponibili)
Dialog mostra ChoiceChip con orari
    ↓ (user seleziona slot e conferma)
API updateBooking(locationId, bookingId, newStartTime)
    ↓ (backend aggiorna booking_items)
Provider aggiorna lista locale
    ↓
SnackBar "Prenotazione riprogrammata con successo"
```

---

## 🔧 Comandi Utili

```bash
# Frontend: Genera localizzazioni
cd agenda_frontend
dart run intl_utils:generate

# Frontend: Genera provider Riverpod
dart run build_runner build --delete-conflicting-outputs

# Frontend: Analisi codice
flutter analyze

# Backend: Verifica sintassi PHP
php -l agenda_core/src/UseCases/Booking/UpdateBooking.php
```

---

## 📖 Riferimenti

- **Decision 18**: Cancellation Policy (decisions.md:480-532)
- **Decision 19**: Reschedule (decisions.md:534-580)
- **API Contract**: PUT /v1/locations/{location_id}/bookings/{id} (api_contract_v1.md:660-760)
- **Feature Doc**: my_bookings_feature.md completo con changelog

---

## ✨ Highlights

- ✅ **Reschedule completo** frontend + backend
- ✅ **Availability check** real-time nel dialog
- ✅ **Validazione policy** server-side (no bypass client)
- ✅ **Update ottimistico** per UX fluida
- ✅ **Documentazione completa** con decision log
- ⚠️ **Migration manuale** richiesta (MySQL)
- 📝 **TODO backend**: Availability check in UpdateBooking

**Note**: Il reschedule è funzionale ma il backend non verifica ancora i conflitti di disponibilità. L'availability check avviene solo lato frontend. Per produzione, implementare la verifica server-side in `UpdateBooking::execute()`.
