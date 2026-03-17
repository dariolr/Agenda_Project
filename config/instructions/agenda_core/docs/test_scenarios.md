# Test Scenarios — Agenda Core API

Questo documento definisce tutti i casi di test per validare il comportamento dell'API Agenda Core.
Aggiornato al: **27 dicembre 2025**

---

## 📋 Indice

- [Setup Test Environment](#setup-test-environment)
- [M1: Authentication](#m1-authentication)
- [M2: Public Browse](#m2-public-browse)
- [M3: Booking Creation](#m3-booking-creation)
- [M1.1: Booking Management](#m11-booking-management)
  - [View Bookings](#view-bookings)
  - [Cancel Booking](#cancel-booking)
  - [Reschedule Booking](#reschedule-booking)
- [Edge Cases & Error Handling](#edge-cases--error-handling)
- [Performance & Concurrency](#performance--concurrency)

---

## Setup Test Environment

### Prerequisiti

```bash
# Database di test
mysql -u root -p agenda_test < config/migrations/FULL_DATABASE_SCHEMA.sql

# Dati di test
mysql -u root -p agenda_test < config/migrations/seed_data.sql
```

### Test User Credentials

```json
{
  "test_user_1": {
    "email": "mario.rossi@test.com",
    "password": "TestPass123!",
    "user_id": 1
  },
  "test_user_2": {
    "email": "anna.bianchi@test.com",
    "password": "TestPass456!",
    "user_id": 2
  }
}
```

### Test Business/Location IDs

- **Business ID**: 1 (Salone Bella Vita)
- **Location ID**: 1 (Sede Centro, cancellation_hours: 24)
- **Location ID**: 2 (Sede Periferia, cancellation_hours: 48)

### Test Staff/Services

- **Staff ID**: 1 (Anna B., stylist)
- **Staff ID**: 2 (Luigi M., barber)
- **Service ID**: 1 (Taglio Uomo, 30 min, €20)
- **Service ID**: 2 (Taglio Donna, 45 min, €35)
- **Service ID**: 3 (Piega, 30 min, €15)

---

## M1: Authentication

### TEST-AUTH-001: Login con credenziali valide

**Request:**
```http
POST /v1/auth/login
Content-Type: application/json

{
  "email": "mario.rossi@test.com",
  "password": "TestPass123!"
}
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "abc123...",
    "expires_in": 900,
    "user": {
      "id": 1,
      "email": "mario.rossi@test.com",
      "first_name": "Mario",
      "last_name": "Rossi"
    }
  }
}
```

**Validazioni:**
- ✅ `access_token` è un JWT valido
- ✅ `expires_in` = 900 (15 minuti)
- ✅ `refresh_token` salvato in DB con scadenza 30-90 giorni

---

### TEST-AUTH-002: Login con password errata

**Request:**
```http
POST /v1/auth/login
Content-Type: application/json

{
  "email": "mario.rossi@test.com",
  "password": "WrongPassword!"
}
```

**Expected Response (401):**
```json
{
  "success": false,
  "error": {
    "code": "invalid_credentials",
    "message": "Invalid email or password"
  }
}
```

---

### TEST-AUTH-003: Refresh token con token valido

**Request:**
```http
POST /v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "abc123..."
}
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ_new...",
    "refresh_token": "xyz789_new...",
    "expires_in": 900
  }
}
```

**Validazioni:**
- ✅ Vecchio `refresh_token` invalidato (token rotation)
- ✅ Nuovo `refresh_token` salvato in DB
- ✅ Tentativo di riutilizzo vecchio token → 401

---

### TEST-AUTH-004: Logout invalida refresh token

**Request:**
```http
POST /v1/auth/logout
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "refresh_token": "abc123..."
}
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "Logged out successfully"
  }
}
```

**Validazioni:**
- ✅ `refresh_token` rimosso da DB
- ✅ Tentativo refresh dopo logout → 401 `invalid_refresh_token`

---

## M2: Public Browse

### TEST-BROWSE-001: Lista servizi per location

**Request:**
```http
GET /v1/services?location_id=1
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": 1,
        "name": "Taglio",
        "services": [
          {
            "id": 1,
            "name": "Taglio Uomo",
            "description": "Taglio classico o moderno",
            "default_duration_minutes": 30,
            "default_price": 20.00,
            "color": "#FF6B6B",
            "category_id": 1
          }
        ]
      }
    ]
  }
}
```

---

### TEST-BROWSE-002: Availability check base

**Request:**
```http
GET /v1/availability?location_id=1&date=2026-01-15&service_ids=1&staff_id=1
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "slots": [
      {
        "start_time": "2026-01-15T09:00:00+01:00",
        "end_time": "2026-01-15T09:30:00+01:00",
        "staff_id": 1,
        "staff_name": "Anna B."
      },
      {
        "start_time": "2026-01-15T09:30:00+01:00",
        "end_time": "2026-01-15T10:00:00+01:00",
        "staff_id": 1,
        "staff_name": "Anna B."
      }
    ]
  }
}
```

**Validazioni:**
- ✅ Solo slot liberi (no conflitti con booking esistenti)
- ✅ Rispetta orari lavoro staff
- ✅ Durata slot = somma durate servizi

---

### TEST-BROWSE-003: Availability con servizi multipli

**Request:**
```http
GET /v1/availability?location_id=1&date=2026-01-15&service_ids=1,3&staff_id=1
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "slots": [
      {
        "start_time": "2026-01-15T09:00:00+01:00",
        "end_time": "2026-01-15T10:00:00+01:00",
        "staff_id": 1,
        "staff_name": "Anna B."
      }
    ]
  }
}
```

**Validazioni:**
- ✅ Durata slot = 30 min (service 1) + 30 min (service 3) = 60 min
- ✅ Verifica disponibilità continuativa per entrambi i servizi

---

## M3: Booking Creation

### TEST-BOOKING-001: Creazione booking con slot disponibile

**Request:**
```http
POST /v1/locations/1/bookings
Authorization: Bearer <access_token>
X-Idempotency-Key: 550e8400-e29b-41d4-a716-446655440001
Content-Type: application/json

{
  "service_ids": [1],
  "staff_id": 1,
  "start_time": "2026-01-15T10:00:00+01:00",
  "notes": "Prima visita"
}
```

**Expected Response (201):**
```json
{
  "success": true,
  "data": {
    "id": 42,
    "business_id": 1,
    "location_id": 1,
    "client_id": 1,
    "status": "confirmed",
    "notes": "Prima visita",
    "total_price": 20.00,
    "total_duration_minutes": 30,
    "created_at": "2025-12-27T14:30:00+01:00",
    "items": [
      {
        "id": 101,
        "service_id": 1,
        "service_name": "Taglio Uomo",
        "staff_id": 1,
        "staff_name": "Anna B.",
        "location_id": 1,
        "start_time": "2026-01-15T10:00:00+01:00",
        "end_time": "2026-01-15T10:30:00+01:00",
        "price": 20.00,
        "duration_minutes": 30
      }
    ]
  }
}
```

**Validazioni:**
- ✅ Record `bookings` creato con `status='confirmed'`
- ✅ Record `booking_items` creato con `service_variant_id` risolto
- ✅ Record `clients` auto-creato se primo booking utente
- ✅ `idempotency_key` salvato con expires_at = +24h

---

### TEST-BOOKING-002: Creazione booking con slot occupato

**Setup:**
1. Crea booking A: staff_id=1, 2026-01-15 10:00-10:30
2. Tenta booking B: staff_id=1, 2026-01-15 10:15-10:45 (overlap)

**Request (Booking B):**
```http
POST /v1/locations/1/bookings
Authorization: Bearer <access_token>
X-Idempotency-Key: 550e8400-e29b-41d4-a716-446655440002
Content-Type: application/json

{
  "service_ids": [1],
  "staff_id": 1,
  "start_time": "2026-01-15T10:15:00+01:00"
}
```

**Expected Response (409):**
```json
{
  "success": false,
  "error": {
    "code": "slot_conflict",
    "message": "The requested time slot is no longer available",
    "details": {
      "conflicts": [
        {
          "booking_id": 42,
          "start_time": "2026-01-15T10:00:00+01:00",
          "end_time": "2026-01-15T10:30:00+01:00"
        }
      ]
    }
  }
}
```

**Validazioni:**
- ✅ Nessun record creato in `bookings` o `booking_items`
- ✅ Transazione rollback completata
- ✅ `FOR UPDATE` ha bloccato row durante check

---

### TEST-BOOKING-003: Idempotency key duplicata

**Setup:**
1. Crea booking con idempotency_key X (successo)
2. Riprova stessa request con idempotency_key X (entro 24h)

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 42,
    ...stesso booking del primo tentativo...
  }
}
```

**Validazioni:**
- ✅ Nessun nuovo booking creato
- ✅ Ritorna booking esistente con idempotency_key X
- ✅ HTTP status 200 (non 201)

---

### TEST-BOOKING-004: Booking servizi multipli sequenziali

**Request:**
```http
POST /v1/locations/1/bookings
Authorization: Bearer <access_token>
X-Idempotency-Key: 550e8400-e29b-41d4-a716-446655440003
Content-Type: application/json

{
  "service_ids": [1, 3],
  "staff_id": 1,
  "start_time": "2026-01-15T14:00:00+01:00"
}
```

**Expected Response (201):**
```json
{
  "success": true,
  "data": {
    "id": 43,
    "total_duration_minutes": 60,
    "total_price": 35.00,
    "items": [
      {
        "id": 102,
        "service_id": 1,
        "start_time": "2026-01-15T14:00:00+01:00",
        "end_time": "2026-01-15T14:30:00+01:00",
        "duration_minutes": 30,
        "price": 20.00
      },
      {
        "id": 103,
        "service_id": 3,
        "start_time": "2026-01-15T14:30:00+01:00",
        "end_time": "2026-01-15T15:00:00+01:00",
        "duration_minutes": 30,
        "price": 15.00
      }
    ]
  }
}
```

**Validazioni:**
- ✅ 2 `booking_items` con orari consecutivi
- ✅ `items[0].end_time` = `items[1].start_time`
- ✅ `total_duration` = somma durate
- ✅ `total_price` = somma prezzi

---

## M1.1: Booking Management

> **Nota:** Aggiornato al 27/12/2025 con formato response flat (no nested objects).

### View Bookings

#### TEST-VIEW-001: Lista bookings utente autenticato

**Request:**
```http
GET /v1/me/bookings
Authorization: Bearer <access_token>
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "upcoming": [
      {
        "booking_id": 123,
        "status": "confirmed",
        "start_time": "2026-01-20T14:00:00+01:00",
        "end_time": "2026-01-20T15:00:00+01:00",
        "service_names": ["Taglio", "Piega"],
        "staff_name": "Anna B.",
        "total_price": 35.00,
        "notes": null,
        "location_id": 1,
        "location_name": "Sede Centro",
        "location_address": "Via Roma 123",
        "location_city": "Milano",
        "business_id": 1,
        "business_name": "Salone Bella Vita",
        "can_modify": true,
        "can_modify_until": "2026-01-19T14:00:00+01:00",
        "created_at": "2025-12-20T10:00:00+01:00"
      }
    ],
    "past": [
      {
        "booking_id": 100,
        "status": "completed",
        "start_time": "2025-12-15T10:00:00+01:00",
        "end_time": "2025-12-15T11:00:00+01:00",
        "service_names": ["Taglio Uomo"],
        "staff_name": "Luigi M.",
        "total_price": 25.00,
        "notes": null,
        "location_id": 1,
        "location_name": "Sede Centro",
        "location_address": "Via Roma 123",
        "location_city": "Milano",
        "business_id": 1,
        "business_name": "Salone Bella Vita",
        "can_modify": false,
        "can_modify_until": null,
        "created_at": "2025-12-10T09:00:00+01:00"
      }
    ]
  }
}
```

**Validazioni:**
- ✅ `upcoming` ordinati per `start_time ASC`
- ✅ `past` ordinati per `start_time DESC`
- ✅ `can_modify = true` solo se `now < can_modify_until`
- ✅ `can_modify_until = start_time - cancellation_hours`
- ✅ `service_names` è array (aggregato da booking_items)
- ✅ `total_price` è somma prezzi di tutti booking_items
- ✅ Formato flat (no oggetti nested location/business)

---

#### TEST-VIEW-002: Can_modify calculation con location override

**Setup:**
- Location 1: `cancellation_hours = 24`
- Location 2: `cancellation_hours = 48`
- Booking A: location_id=1, start_time = now + 30 ore
- Booking B: location_id=2, start_time = now + 30 ore

**Expected:**
- Booking A: `can_modify = true` (30h > 24h)
- Booking B: `can_modify = false` (30h < 48h)

---

### Cancel Booking

#### TEST-CANCEL-001: Cancellazione entro deadline

**Setup:**
- Location cancellation_hours = 24
- Booking start_time = now + 48 ore
- Now = 2025-12-27T10:00:00

**Request:**
```http
DELETE /v1/locations/1/bookings/123
Authorization: Bearer <access_token>
```

**Expected Response (204):**
```
(empty body)
```

**Validazioni:**
- ✅ `bookings.status` → 'cancelled'
- ✅ `booking_items` non eliminati (audit trail)
- ✅ Slot liberato (disponibile in availability check)

---

#### TEST-CANCEL-002: Cancellazione oltre deadline

**Setup:**
- Location cancellation_hours = 24
- Booking start_time = now + 20 ore (entro deadline)

**Request:**
```http
DELETE /v1/locations/1/bookings/123
Authorization: Bearer <access_token>
```

**Expected Response (400):**
```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Cannot cancel booking within 24 hours of appointment start time",
    "details": {
      "cancellation_deadline": "2025-12-28T14:00:00+01:00"
    }
  }
}
```

**Validazioni:**
- ✅ Booking non modificato (status rimane 'confirmed')
- ✅ Messaggio include deadline precisa

---

#### TEST-CANCEL-003: Cancellazione booking di altro utente

**Setup:**
- Booking owner: user_id=1
- Request from: user_id=2

**Request:**
```http
DELETE /v1/locations/1/bookings/123
Authorization: Bearer <access_token_user_2>
```

**Expected Response (403):**
```json
{
  "success": false,
  "error": {
    "code": "unauthorized",
    "message": "You do not have permission to cancel this booking"
  }
}
```

---

### Reschedule Booking

#### TEST-RESCHEDULE-001: Reschedule con slot disponibile

**Setup:**
- Booking originale: staff_id=1, 2026-01-20 14:00-15:00 (servizi 1+3)
- Nuovo slot: 2026-01-22 10:00-11:00 (libero)
- Cancellation deadline: non violata

**Request:**
```http
PUT /v1/locations/1/bookings/123
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "start_time": "2026-01-22T10:00:00+01:00",
  "notes": "Riprogrammazione per impegno"
}
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "status": "confirmed",
    "notes": "Riprogrammazione per impegno",
    "items": [
      {
        "id": 456,
        "service_id": 1,
        "start_time": "2026-01-22T10:00:00+01:00",
        "end_time": "2026-01-22T10:30:00+01:00"
      },
      {
        "id": 457,
        "service_id": 3,
        "start_time": "2026-01-22T10:30:00+01:00",
        "end_time": "2026-01-22T11:00:00+01:00"
      }
    ]
  }
}
```

**Validazioni:**
- ✅ Tutti i `booking_items` aggiornati con nuovo orario
- ✅ Offset temporale preservato (servizio 3 inizia quando finisce servizio 1)
- ✅ Durate invariate
- ✅ Staff e servizi invariati
- ✅ Vecchio slot liberato, nuovo slot occupato

---

#### TEST-RESCHEDULE-002: Reschedule con slot occupato (availability check)

**Setup:**
1. Booking A: staff_id=1, 2026-01-22 10:00-10:30 (esistente)
2. Booking B: staff_id=1, 2026-01-20 14:00-14:30 (da spostare)
3. Tentativo reschedule B → 2026-01-22 10:00-10:30 (conflitto con A)

**Request:**
```http
PUT /v1/locations/1/bookings/124
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "start_time": "2026-01-22T10:00:00+01:00"
}
```

**Expected Response (409):**
```json
{
  "success": false,
  "error": {
    "code": "slot_conflict",
    "message": "The requested time slot is no longer available for this staff member",
    "details": {
      "conflicts": [
        {
          "booking_id": 123,
          "start_time": "2026-01-22T10:00:00+01:00",
          "end_time": "2026-01-22T10:30:00+01:00"
        }
      ]
    }
  }
}
```

**Validazioni:**
- ✅ Booking B non modificato (orario originale preservato)
- ✅ Transazione rollback completata
- ✅ `FOR UPDATE` ha bloccato row di Booking A durante check

---

#### TEST-RESCHEDULE-003: Reschedule multi-service con offset complesso

**Setup:**
- Booking originale:
  - Item 1: service_id=1, 2026-01-20 14:00-14:30 (30 min)
  - Item 2: service_id=3, 2026-01-20 14:30-15:00 (30 min)
  - Item 3: service_id=2, 2026-01-20 15:00-15:45 (45 min)
- Nuovo start: 2026-01-22 09:00:00

**Expected:**
- Item 1: 2026-01-22 09:00-09:30 (offset: +43h)
- Item 2: 2026-01-22 09:30-10:00 (offset: +43h)
- Item 3: 2026-01-22 10:00-10:45 (offset: +43h)

**Validazioni:**
- ✅ Offset calcolato correttamente: `new_start - old_start`
- ✅ Tutti gli item spostati con stesso offset
- ✅ Intervalli relativi preservati (no gap, no overlap)

---

#### TEST-RESCHEDULE-004: Reschedule oltre cancellation deadline

**Setup:**
- Location cancellation_hours = 24
- Booking start_time = now + 20 ore
- Tentativo reschedule a now + 48 ore

**Request:**
```http
PUT /v1/locations/1/bookings/123
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "start_time": "2025-12-29T14:00:00+01:00"
}
```

**Expected Response (400):**
```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Cannot modify booking within 24 hours of appointment start time",
    "details": {
      "cancellation_deadline": "2025-12-28T14:00:00+01:00"
    }
  }
}
```

**Validazioni:**
- ✅ Policy validata PRIMA dell'availability check
- ✅ Booking non modificato

---

#### TEST-RESCHEDULE-005: Reschedule dello stesso booking a slot parzialmente sovrapposto

**Setup:**
- Booking originale: 2026-01-20 14:00-15:00
- Reschedule a: 2026-01-20 14:30-15:30 (overlap 30 min)
- Nessun altro booking per questo staff

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "items": [
      {
        "start_time": "2026-01-20T14:30:00+01:00",
        "end_time": "2026-01-20T15:30:00+01:00"
      }
    ]
  }
}
```

**Validazioni:**
- ✅ `checkConflicts()` riceve `excludeBookingId=123`
- ✅ Overlap con se stesso ignorato
- ✅ Update completato con successo

---

#### TEST-RESCHEDULE-006: Update status/notes (no reschedule)

**Request:**
```http
PUT /v1/locations/1/bookings/123
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "status": "confirmed",
  "notes": "Cliente confermato via telefono"
}
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "status": "confirmed",
    "notes": "Cliente confermato via telefono",
    "items": [
      {
        "start_time": "2026-01-20T14:00:00+01:00",
        ...orario invariato...
      }
    ]
  }
}
```

**Validazioni:**
- ✅ Solo `status` e `notes` aggiornati
- ✅ `booking_items` invariati
- ✅ No availability check eseguito
- ✅ Cancellation policy NON validata (solo per reschedule/cancel)

---

## Edge Cases & Error Handling

### TEST-EDGE-001: Booking con service_variant non disponibile online

**Setup:**
- Service 1 ha variant per location 1 con `is_bookable_online=0`

**Request:**
```http
POST /v1/locations/1/bookings
Authorization: Bearer <access_token>
X-Idempotency-Key: 550e8400-e29b-41d4-a716-446655440004

{
  "service_ids": [1],
  "staff_id": 1,
  "start_time": "2026-01-15T10:00:00+01:00"
}
```

**Expected Response (400):**
```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Service 1 is not available for online booking at this location"
  }
}
```

---

### TEST-EDGE-002: Reschedule con start_time formato invalido

**Request:**
```http
PUT /v1/locations/1/bookings/123
Authorization: Bearer <access_token>

{
  "start_time": "2026-01-22 10:00:00"
}
```

**Expected Response (400):**
```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Invalid start_time format. Use ISO8601."
  }
}
```

---

### TEST-EDGE-003: Booking con JWT scaduto

**Request:**
```http
POST /v1/locations/1/bookings
Authorization: Bearer <expired_token>
X-Idempotency-Key: 550e8400-e29b-41d4-a716-446655440005

{
  "service_ids": [1],
  "staff_id": 1,
  "start_time": "2026-01-15T10:00:00+01:00"
}
```

**Expected Response (401):**
```json
{
  "success": false,
  "error": {
    "code": "unauthorized",
    "message": "Access token expired"
  }
}
```

---

### TEST-EDGE-004: Reschedule booking già cancellato

**Setup:**
- Booking status = 'cancelled'

**Request:**
```http
PUT /v1/locations/1/bookings/123
Authorization: Bearer <access_token>

{
  "start_time": "2026-01-22T10:00:00+01:00"
}
```

**Expected Response (400):**
```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Cannot reschedule a cancelled booking"
  }
}
```

---

### TEST-EDGE-005: Location ID mismatch tra path e booking

**Setup:**
- Booking originale: location_id=1
- Request path: `/v1/locations/2/bookings/123`

**Request:**
```http
PUT /v1/locations/2/bookings/123
Authorization: Bearer <access_token>

{
  "notes": "Test"
}
```

**Expected Response (404):**
```json
{
  "success": false,
  "error": {
    "code": "not_found",
    "message": "Booking not found"
  }
}
```

**Validazioni:**
- ✅ Query filtrata per `location_id=2 AND booking_id=123` → nessun match
- ✅ Previene accesso cross-location

---

## Performance & Concurrency

### TEST-PERF-001: Race condition su reschedule simultanei

**Setup:**
1. Booking A: staff_id=1, 2026-01-20 14:00-14:30
2. Slot target: 2026-01-22 10:00-10:30 (libero)

**Scenario:**
- Thread 1: Reschedule Booking A → target slot
- Thread 2: Reschedule Booking A → stesso target slot
- Esecuzione simultanea (delay < 100ms)

**Expected Outcome:**
- 1 request → **200 OK** (prima a completare transazione)
- 1 request → **409 Conflict** (rileva booking già spostato)

**Validazioni:**
- ✅ Una sola transazione committata
- ✅ Nessun double-booking
- ✅ `FOR UPDATE` ha serializzato accesso

---

### TEST-PERF-002: Race condition su booking + reschedule

**Setup:**
- Slot target: 2026-01-22 10:00-10:30 (libero)

**Scenario:**
- Thread 1: `POST /bookings` → nuovo booking su target slot
- Thread 2: `PUT /bookings/123` → reschedule esistente su target slot
- Esecuzione simultanea

**Expected Outcome:**
- 1 request → **201 Created** / **200 OK**
- 1 request → **409 Conflict**

**Validazioni:**
- ✅ Una sola transazione occupa lo slot
- ✅ Lock acquisito da `checkConflicts()` FOR UPDATE

---

### TEST-PERF-003: Reschedule multi-item con 10+ servizi

**Setup:**
- Booking con 10 servizi consecutivi (totale 5 ore)
- Nuovo slot: disponibile per tutti i 10 servizi

**Expected:**
- Response time < 1s
- Tutti i 10 `booking_items` aggiornati con offset corretto
- Una sola query UPDATE per tutti gli items (batch)

**Validazioni:**
- ✅ No N+1 query problem
- ✅ Transazione unica

---

### TEST-PERF-004: Availability check con 50+ booking esistenti

**Setup:**
- Staff 1 ha 50 booking su 2026-01-22
- Request availability per 2026-01-22

**Expected:**
- Response time < 500ms
- Solo slot liberi ritornati
- Query con indici su `(staff_id, location_id, start_time, end_time)`

---

## Automation Scripts

### Script: Run All Critical Tests

```bash
#!/bin/bash
# test_critical.sh

BASE_URL="https://api.agenda-test.local/v1"

echo "🧪 Running Critical Test Suite..."

# Login
ACCESS_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"mario.rossi@test.com","password":"TestPass123!"}' \
  | jq -r '.data.access_token')

echo "✅ Authentication OK"

# TEST-RESCHEDULE-001: Reschedule con slot disponibile
BOOKING_ID=$(curl -s -X POST "$BASE_URL/locations/1/bookings" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-Idempotency-Key: $(uuidgen)" \
  -H "Content-Type: application/json" \
  -d '{"service_ids":[1],"staff_id":1,"start_time":"2026-01-20T14:00:00+01:00"}' \
  | jq -r '.data.id')

RESCHEDULE_RESPONSE=$(curl -s -X PUT "$BASE_URL/locations/1/bookings/$BOOKING_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"start_time":"2026-01-22T10:00:00+01:00"}')

RESCHEDULE_STATUS=$(echo $RESCHEDULE_RESPONSE | jq -r '.success')
if [ "$RESCHEDULE_STATUS" = "true" ]; then
  echo "✅ TEST-RESCHEDULE-001 PASSED"
else
  echo "❌ TEST-RESCHEDULE-001 FAILED"
  echo $RESCHEDULE_RESPONSE | jq
fi

# TEST-RESCHEDULE-002: Slot occupato
CONFLICT_RESPONSE=$(curl -s -X PUT "$BASE_URL/locations/1/bookings/$BOOKING_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"start_time":"2026-01-22T10:00:00+01:00"}')

ERROR_CODE=$(echo $CONFLICT_RESPONSE | jq -r '.error.code')
if [ "$ERROR_CODE" = "slot_conflict" ]; then
  echo "✅ TEST-RESCHEDULE-002 PASSED"
else
  echo "❌ TEST-RESCHEDULE-002 FAILED (expected slot_conflict, got $ERROR_CODE)"
fi

echo ""
echo "📊 Test Suite Complete"
```

### Script: Race Condition Simulator

```bash
#!/bin/bash
# test_race_condition.sh

BASE_URL="https://api.agenda-test.local/v1"
ACCESS_TOKEN="<your_token>"
BOOKING_ID=123

# Esegui due reschedule simultanei
(
  curl -s -X PUT "$BASE_URL/locations/1/bookings/$BOOKING_ID" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"start_time":"2026-01-22T10:00:00+01:00"}' &
  
  curl -s -X PUT "$BASE_URL/locations/1/bookings/$BOOKING_ID" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"start_time":"2026-01-22T10:00:00+01:00"}' &
  
  wait
) | jq -s 'map(.success) | group_by(.) | map({key: .[0], count: length})'

# Expected output: [{"key":true,"count":1}, {"key":false,"count":1}]
```

---

## Future Test Scenarios

### M10: Notifications

- **TEST-NOTIF-001**: Email conferma dopo booking creation
- **TEST-NOTIF-002**: Email notifica reschedule a cliente e staff
- **TEST-NOTIF-003**: SMS reminder 24h prima appuntamento
- **TEST-NOTIF-004**: Push notification cancellazione booking

### M4: Admin Dashboard

- **TEST-ADMIN-001**: Gestionale vede booking multi-location
- **TEST-ADMIN-002**: Report bookings per staff/periodo
- **TEST-ADMIN-003**: Modifica booking lato admin (no policy)

### M5: Reviews

- **TEST-REVIEW-001**: Cliente può recensire solo dopo status='completed'
- **TEST-REVIEW-002**: Review visibile solo dopo approvazione admin

---

## Maintenance

### Aggiornamento Scenari

Quando aggiungi una nuova feature:
1. Crea sezione dedicata (es: `## M2: Feature Name`)
2. Numera test sequenzialmente (`TEST-FEATURE-001`)
3. Includi setup, request, expected response, validazioni
4. Aggiungi script bash per automazione se applicabile

### Test Data Reset

```bash
# Ripristina DB test a stato pulito
mysql -u root -p agenda_test < test_data/reset.sql
mysql -u root -p agenda_test < test_data/seed.sql
```

---

**Ultimo aggiornamento**: 28 dicembre 2025  
**Versione API**: v1  
**Maintainer**: Team Agenda Core

---

## M8: Unit Test Suite (PHPUnit)

### Panoramica

Test suite implementata con PHPUnit 10.5.60. Focus su logica di business pura senza dipendenze dal database.

**Risultati**: 98 test, 195 asserzioni, 100% pass

### TEST-UNIT-AUTH: Auth Use Case Tests

| Test | Descrizione |
|------|-------------|
| `testPasswordHashingAndVerification` | Bcrypt hash + verify |
| `testLoginValidationRequiresEmail` | Email obbligatoria |
| `testLoginValidationRequiresValidEmailFormat` | Formato email valido |
| `testPasswordMinimumLength` | Password ≥ 8 caratteri |
| `testJwtGenerationAndValidation` | JWT create + validate |
| `testJwtRejectsInvalidToken` | Token malformato |
| `testJwtRejectsTamperedToken` | Token manomesso |
| `testRefreshTokenHashGeneration` | SHA-256 deterministic |
| `testRefreshTokenExpiryCheck` | Scadenza +30 giorni |
| `testRefreshTokenRevokedCheck` | Flag is_revoked |
| `testDisabledAccountCheck` | Account disabilitato |
| `testUserRoleValidation` | Ruoli validi |
| `testAuthExceptionInvalidCredentials` | Exception credentials |
| `testAuthExceptionAccountDisabled` | Exception disabled |
| `testAuthExceptionTokenExpired` | Exception expired |
| `testSessionExpiryCalculation` | TTL access/refresh |
| `testLogoutRequiresUserId` | User ID obbligatorio |

### TEST-UNIT-BOOKING: Booking Use Case Tests

| Test | Descrizione |
|------|-------------|
| `testBookingRequiresServiceIds` | service_ids obbligatorio |
| `testBookingRequiresValidStartTime` | start_time obbligatorio |
| `testBookingRejectsPastStartTime` | No date passate |
| `testBookingAcceptsFutureStartTime` | Date future OK |
| `testTotalDurationCalculation` | Somma durate servizi |
| `testEndTimeCalculation` | start + duration = end |
| `testConflictDetection` | Overlap rilevato |
| `testNoConflictForAdjacentBookings` | Adiacenti OK |
| `testNoConflictForNonOverlappingBookings` | Separati OK |
| `testConflictWhenNewBookingContainsExisting` | Nuovo contiene esistente |
| `testConflictWhenExistingContainsNew` | Esistente contiene nuovo |
| `testIdempotencyKeyFormat` | UUID v4 valido |
| `testIdempotencyKeyRejectsInvalidFormat` | UUID invalido |
| `testTotalPriceCalculation` | Somma prezzi |
| `testValidBookingStatuses` | pending/confirmed/... |
| `testDefaultBookingStatusIsPending` | Default = pending |
| `testSequentialServiceSlotCalculation` | Multi-service sequential |

### TEST-UNIT-AVAILABILITY: Availability Tests

| Test | Descrizione |
|------|-------------|
| `testWorkingHoursParsingAM` | Parse orari apertura |
| `testWorkingHoursSpansDayCorrectly` | Calcolo ore totali |
| `testGenerateSlots30MinInterval` | Slot 30 min |
| `testGenerateSlots15MinInterval` | Slot 15 min |
| `testFilterOutBookedSlots` | Escludi occupati |
| `testFilterSlotsForServiceDuration` | Servizio > slot |
| `testStaffBreakTimeExcludedFromAvailability` | Pausa pranzo |
| `testStaffAvailableOutsideBreak` | Fuori pausa OK |
| `testAnyStaffAvailableReturnsSlot` | Multi-staff OR |
| `testNoStaffAvailableReturnsUnavailable` | Tutti occupati |
| `testAvailabilityForDateRange` | Range date |
| `testExcludeClosedDays` | Domenica chiuso |
| `testBufferTimeBetweenAppointments` | Buffer 15 min |
| `testNoBufferWhenNotConfigured` | Buffer 0 |
| `testSlotConversionBetweenTimezones` | UTC ↔ Rome |
| `testSlotsGeneratedInBusinessTimezone` | Timezone business |

### Esecuzione Test

```bash
# Tutti i test con output dettagliato
cd agenda_core
./vendor/bin/phpunit --testdox

# Solo test Auth
./vendor/bin/phpunit --filter AuthUseCaseTest

# Solo test Booking
./vendor/bin/phpunit --filter BookingUseCaseTest

# Solo test Availability
./vendor/bin/phpunit --filter AvailabilityTest

# Coverage report (richiede xdebug)
./vendor/bin/phpunit --coverage-html coverage/
```

### File Test

```
tests/
├── AuthTest.php           # 6 test - JWT base, password
├── AuthUseCaseTest.php    # 17 test - Logica auth completa
├── AvailabilityTest.php   # 16 test - Slot e disponibilità
├── BookingTest.php        # 7 test - Overlap e date
├── BookingUseCaseTest.php # 18 test - Logica booking
├── ExceptionsTest.php     # 7 test - Domain exceptions
├── IdempotencyTest.php    # 5 test - UUID validation
├── PasswordHasherTest.php # 4 test - Bcrypt
├── RequestTest.php        # 5 test - HTTP request
├── ResponseTest.php       # 7 test - HTTP response
└── RouterTest.php         # 7 test - Routing
```
