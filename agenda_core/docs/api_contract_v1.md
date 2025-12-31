# API Contract v1 — agenda_core

Base URL: `/v1`

---

## Health Check

### GET /health

No authentication required.

Response (200):
```json
{
  "status": "ok",
  "timestamp": "2025-01-15T10:00:00+01:00",
  "version": "1.0.0"
}
```

---

## Response Format

### Success
```json
{
  "success": true,
  "data": { ... }
}
```

### Error
```json
{
  "success": false,
  "error": {
    "code": "error_code",
    "message": "Human readable message",
    "details": { ... }
  }
}
```

---

## Auth Endpoints (globale, no business context)

### POST /v1/auth/login

Request:
```json
{
  "email": "user@example.com",
  "password": "secret"
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "abc123...",
    "expires_in": 900,
    "user": {
      "id": 1,
      "email": "user@example.com",
      "first_name": "Mario",
      "last_name": "Rossi"
    }
  }
}
```

Note: `refresh_token` viene anche settato come cookie httpOnly.

---

### POST /v1/auth/register

Request:
```json
{
  "email": "newuser@example.com",
  "password": "SecurePass123!",
  "first_name": "Mario",
  "last_name": "Rossi",
  "phone": "+39123456789"
}
```

Oppure con campo `name` unificato:
```json
{
  "email": "newuser@example.com",
  "password": "SecurePass123!",
  "name": "Mario Rossi"
}
```

Response (201):
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "abc123...",
    "expires_in": 900,
    "user": {
      "id": 4,
      "email": "newuser@example.com",
      "first_name": "Mario",
      "last_name": "Rossi"
    }
  }
}
```

Errors:
- `email_already_exists` (409): Email già registrata
- `weak_password` (400): Password non sufficientemente sicura (min 8 caratteri, maiuscola, minuscola, numero)

---

### POST /v1/auth/forgot-password

Request:
```json
{
  "email": "user@example.com"
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "message": "If the email exists, a password reset link has been sent"
  }
}
```

Note: Ritorna sempre 200 per evitare email enumeration.

---

### POST /v1/auth/reset-password

Request:
```json
{
  "token": "abc123def456...",
  "password": "NewSecurePass456!"
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "message": "Password has been reset successfully"
  }
}
```

Errors:
- `invalid_reset_token` (400): Token non valido o già usato
- `reset_token_expired` (400): Token scaduto (validità 1 ora)
- `weak_password` (400): Password non sufficientemente sicura

---

### POST /v1/auth/refresh

Request (body o cookie):
```json
{
  "refresh_token": "abc123..."
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "new-token...",
    "expires_in": 900
  }
}
```

Note: Implementa token rotation (vecchio refresh token invalidato).

---

### POST /v1/auth/logout

Headers: `Authorization: Bearer <access_token>`

Request (body o cookie):
```json
{
  "refresh_token": "abc123..."
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "message": "Logged out successfully"
  }
}
```

---

### GET /v1/me

Headers: `Authorization: Bearer <access_token>`

Response (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "Mario",
    "last_name": "Rossi",
    "phone": "+39...",
    "is_active": true,
    "staff_memberships": [
      {
        "staff_id": 1,
        "business_id": 1,
        "business_name": "Salone Bella Vita",
        "role": "stylist",
        "display_name": "Mario R."
      }
    ]
  }
}
```

---

### PUT /v1/me

Aggiorna il profilo dell'utente autenticato.

Headers: `Authorization: Bearer <access_token>`

Request (tutti i campi opzionali):
```json
{
  "first_name": "Mario",
  "last_name": "Rossi",
  "email": "nuova@email.com",
  "phone": "+39 333 1234567"
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "email": "nuova@email.com",
      "first_name": "Mario",
      "last_name": "Rossi",
      "phone": "+39 333 1234567",
      "is_active": true
    }
  }
}
```

Errors:
- `unauthorized` (401): Access token non valido o scaduto
- `validation_error` (400): Email già in uso da altro utente

---

### POST /v1/me/change-password

Headers: `Authorization: Bearer <access_token>`

Request:
```json
{
  "current_password": "OldPass123!",
  "new_password": "NewSecurePass456!"
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "message": "Password changed successfully"
  }
}
```

Errors:
- `unauthorized` (401): Access token non valido o scaduto
- `validation_error` (400): Current password e new password sono obbligatori
- `invalid_credentials` (400): Current password errata
- `weak_password` (400): New password non sufficientemente sicura
- `validation_error` (400): New password uguale a current password

Note: 
- La password deve contenere almeno 8 caratteri
- Deve includere: maiuscola, minuscola, numero
- La nuova password deve essere diversa da quella corrente

---

### GET /v1/me/bookings

Headers: `Authorization: Bearer <access_token>`

Get all bookings for the authenticated user (upcoming and past).

Response (200):
```json
{
  "success": true,
  "data": {
    "upcoming": [
      {
        "booking_id": 123,
        "status": "confirmed",
        "start_time": "2025-12-30T14:00:00+01:00",
        "end_time": "2025-12-30T15:30:00+01:00",
        "service_names": ["Taglio", "Piega"],
        "staff_name": "Mario Rossi",
        "total_price": 45.00,
        "notes": "Note opzionali",
        "location_id": 1,
        "location_name": "Sede Centro",
        "location_address": "Via Roma 123",
        "location_city": "Milano",
        "business_id": 1,
        "business_name": "Salone Bella Vita",
        "can_modify": true,
        "can_modify_until": "2025-12-29T14:00:00+01:00",
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
        "staff_name": "Luigi Bianchi",
        "total_price": 25.00,
        "notes": null,
        "location_id": 1,
        "location_name": "...",
        "business_id": 1,
        "business_name": "...",
        "can_modify": false,
        "can_modify_until": null,
        "created_at": "2025-12-10T09:00:00+01:00"
      }
    ]
  }
}
```

Note:
- `booking_id`: ID univoco del booking (alias `id` per compatibilità frontend)
- `service_names`: Array di nomi servizi (aggregati da booking_items)
- `staff_name`: Nome completo dello staff (primo assegnato)
- `total_price`: Somma dei prezzi di tutti i booking_items
- `can_modify`: `true` se now < can_modify_until
- `can_modify_until`: deadline calcolata da `start_time - cancellation_hours`
- `cancellation_hours`: policy configurata a livello location o business (default 24h)
- Upcoming bookings ordinati per start_time ASC (prossimo prima)
- Past bookings ordinati per start_time DESC (recente prima)
- Formato flat (no nested objects) per semplicità parsing

---

## Superadmin Endpoints (30/12/2025)

Endpoint riservati ai superadmin (`users.is_superadmin = 1`).

### GET /v1/admin/businesses

Lista tutti i business della piattaforma.

**Auth required**: Yes (superadmin only)

Query params:
- `search`: Filtra per nome (opzionale)
- `limit`: Max risultati (default 50, max 100)
- `offset`: Per paginazione

Response (200):
```json
{
  "success": true,
  "data": {
    "businesses": [
      {
        "id": 1,
        "name": "Salone Bella Vita",
        "slug": "salone-bella-vita",
        "email": "info@bellavita.it",
        "phone": "+39 06 12345678",
        "timezone": "Europe/Rome",
        "currency": "EUR",
        "is_active": true,
        "created_at": "2025-01-01T10:00:00+01:00"
      }
    ],
    "total": 15,
    "limit": 50,
    "offset": 0
  }
}
```

Errors:
- `forbidden` (403): Non superadmin

---

### POST /v1/admin/businesses

Crea un nuovo business con owner.

**Auth required**: Yes (superadmin only)

Request:
```json
{
  "name": "Nuovo Salone",
  "slug": "nuovo-salone",
  "admin_email": "admin@nuovosalone.it",
  "email": "info@nuovosalone.it",
  "phone": "+39 333 1234567",
  "timezone": "Europe/Rome",
  "currency": "EUR"
}
```

Note: 
- `name` e `slug` sono obbligatori
- `admin_email` (opzionale): email dell'admin del business
  - Se omesso, il business viene creato senza owner (assegnabile in seguito via PUT)
  - Se l'email non esiste, viene creato un nuovo utente
  - Viene inviata email di benvenuto con link reset password (24h)

Response (201):
```json
{
  "success": true,
  "data": {
    "business": {
      "id": 2,
      "name": "Nuovo Salone",
      "slug": "nuovo-salone",
      "email": "info@nuovosalone.it",
      "phone": "+39 333 1234567",
      "timezone": "Europe/Rome",
      "currency": "EUR",
      "is_active": true,
      "created_at": "2025-12-30T10:00:00+01:00"
    },
    "owner": {
      "id": 1,
      "user_id": 123,
      "business_id": 2,
      "role": "owner"
    }
  }
}
```

Errors:
- `forbidden` (403): Non superadmin
- `validation_error` (400): Slug già esistente o campo mancante

---

### PUT /v1/admin/businesses/{id}

Modifica un business esistente.

**Auth required**: Yes (superadmin only)

Request (tutti i campi opzionali):
```json
{
  "name": "Nome Aggiornato",
  "slug": "slug-aggiornato",
  "admin_email": "nuovo-admin@email.it",
  "email": "nuova@email.it",
  "phone": "+39 333 9999999",
  "timezone": "Europe/Rome",
  "currency": "EUR"
}
```

Note:
- Se `admin_email` viene fornito su business senza owner, viene assegnato come owner
- Se `admin_email` viene cambiato, la ownership viene trasferita
- Il vecchio admin diventa "admin", il nuovo diventa "owner"
- Viene inviata email di benvenuto al nuovo admin

Response (200):
```json
{
  "success": true,
  "data": {
    "business": {
      "id": 2,
      "name": "Nome Aggiornato",
      "slug": "slug-aggiornato",
      "email": "nuova@email.it",
      "phone": "+39 333 9999999",
      "timezone": "Europe/Rome",
      "currency": "EUR",
      "is_active": true,
      "created_at": "2025-12-30T10:00:00+01:00"
    }
  }
}
```

Errors:
- `forbidden` (403): Non superadmin
- `validation_error` (400): Slug già in uso da altro business
- `not_found` (404): Business non trovato

---

### POST /v1/admin/businesses/{id}/resend-invite

Reinvia email di invito all'admin del business.

**Auth required**: Yes (superadmin only)

Genera un nuovo token reset password (validità 24h) e invia email di benvenuto.
Utile se l'admin non ha impostato la password in tempo.

Response (200):
```json
{
  "success": true,
  "data": {
    "message": "Invite email sent successfully",
    "admin_email": "admin@example.com"
  }
}
```

Errors:
- `forbidden` (403): Non superadmin
- `not_found` (404): Business non trovato
- `not_found` (404): Business non ha un admin associato

---

### DELETE /v1/admin/businesses/{id}

Soft-delete di un business (imposta `is_active = false`).

**Auth required**: Yes (superadmin only)

Response (200):
```json
{
  "success": true,
  "data": {
    "message": "Business deleted successfully",
    "id": 2
  }
}
```

Errors:
- `forbidden` (403): Non superadmin
- `not_found` (404): Business non trovato

---

## Management Endpoints (admin/staff access)

### GET /v1/businesses

Headers: `Authorization: Bearer <access_token>`

Ritorna la lista di tutti i businesses. (In produzione potrebbe filtrare per user permissions).

Response (200):
```json
{
  "success": true,
  "data": {
    "businesses": [
      {
        "id": 1,
        "name": "Salone Bella Vita",
        "slug": "salone-bella-vita",
        "email": "info@bellavita.it",
        "phone": "+39 06 12345678",
        "timezone": "Europe/Rome",
        "currency": "EUR",
        "is_active": true,
        "created_at": "2025-01-01T00:00:00Z"
      }
    ]
  }
}
```

---

### GET /v1/businesses/{business_id}

Headers: `Authorization: Bearer <access_token>`

Response (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Salone Bella Vita",
    "slug": "salone-bella-vita",
    "email": "info@bellavita.it",
    "phone": "+39 06 12345678",
    "timezone": "Europe/Rome",
    "currency": "EUR",
    "is_active": true,
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-15T10:00:00Z"
  }
}
```

Error - Not Found (404):
```json
{
  "success": false,
  "error": {
    "code": "not_found",
    "message": "Business not found"
  }
}
```

---

### GET /v1/businesses/{business_id}/locations

Headers: `Authorization: Bearer <access_token>`

Ritorna tutte le locations di un business.

Response (200):
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "business_id": 1,
        "name": "Sede Centrale",
        "address": "Via Roma 123, Roma",
        "city": "Roma",
        "region": "Lazio",
        "country": "IT",
        "timezone": "Europe/Rome",
        "latitude": 41.9028,
        "longitude": 12.4964,
        "phone": "+39 06 12345678",
        "email": "roma@bellavita.it",
        "currency": "EUR",
        "is_default": true,
        "is_active": true,
        "created_at": "2025-01-15T10:00:00Z",
        "updated_at": "2025-01-15T10:00:00Z"
      }
    ]
  }
}
```

---

### GET /v1/businesses/{business_id}/locations/public

**No authentication required** (pubblico, per booking flow).

Ritorna le locations attive di un business con campi limitati per il frontend di prenotazione.

Response (200):
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "business_id": 1,
        "name": "Sede Centrale",
        "address": "Via Roma 123",
        "city": "Roma",
        "phone": "+39 06 12345678",
        "timezone": "Europe/Rome",
        "is_default": true
      }
    ]
  }
}
```

Nota: Endpoint usato dal frontend di prenotazione per mostrare le sedi disponibili. Se il business ha più di una location, l'utente può scegliere dove prenotare.

---

### GET /v1/locations/{location_id}

Headers: `Authorization: Bearer <access_token>`

Response (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "business_id": 1,
    "name": "Sede Centrale",
    "address": "Via Roma 123, Roma",
    "city": "Roma",
    "postal_code": "00100",
    "country": "IT",
    "timezone": "Europe/Rome",
    "latitude": 41.9028,
    "longitude": 12.4964,
    "phone": "+39 06 12345678",
    "email": "roma@bellavita.it",
    "currency": "EUR",
    "is_active": true,
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-15T10:00:00Z"
  }
}
```

---

## Public Endpoints (business-scoped via query param)

### GET /v1/services?location_id=1

Response (200):
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
            "description": "...",
            "default_duration_minutes": 30,
            "default_price": 20.00,
            "color": "#FF6B6B",
            "category_id": 1
          }
        ]
      }
    ],
    "services": [ ... ]
  }
}
```

---

### GET /v1/staff?location_id=1

Response (200):
```json
{
  "success": true,
  "data": {
    "staff": [
      {
        "id": 1,
        "display_name": "Anna B.",
        "role": "stylist",
        "color": "#FF6B6B",
        "avatar_url": null
      }
    ]
  }
}
```

---

### GET /v1/availability?location_id=1&date=2024-01-15&service_ids=1,2&staff_id=1

Parameters:
- `location_id` (required): ID della location
- `date` (required): Data in formato YYYY-MM-DD
- `service_ids` (required): IDs servizi separati da virgola
- `staff_id` (optional): Filtra per staff specifico

Response (200):
```json
{
  "success": true,
  "data": {
    "slots": [
      {
        "start_time": "2024-01-15T09:00:00+01:00",
        "end_time": "2024-01-15T10:15:00+01:00",
        "staff_id": 1,
        "staff_name": "Anna B."
      }
    ]
  }
}
```

---

## Protected Endpoints (auth + business-scoped via path)

### POST /v1/locations/{location_id}/bookings

Headers:
- `Authorization: Bearer <access_token>` (required)
- `X-Idempotency-Key: <uuid-v4>` (required, formato UUID v4)

Request Payload (INVARIABILE):
```json
{
  "service_ids": [1, 2],
  "staff_id": 1,
  "start_time": "2024-01-15T10:00:00Z",
  "notes": "Prima visita"
}
```

Response (201):
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
    "total_price": 55.00,
    "total_duration_minutes": 75,
    "created_at": "2024-01-10T14:30:00Z",
    "items": [
      {
        "id": 1,
        "service_id": 1,
        "service_name": "Taglio Uomo",
        "staff_id": 1,
        "staff_name": "Anna B.",
        "location_id": 1,
        "start_time": "2024-01-15T10:00:00Z",
        "end_time": "2024-01-15T10:30:00Z",
        "price": 20.00,
        "duration_minutes": 30
      },
      {
        "id": 2,
        "service_id": 2,
        "service_name": "Taglio Donna",
        "staff_id": 1,
        "staff_name": "Anna B.",
        "location_id": 1,
        "start_time": "2024-01-15T10:30:00Z",
        "end_time": "2024-01-15T11:15:00Z",
        "price": 35.00,
        "duration_minutes": 45
      }
    ]
  }
}
```

Error - Slot Conflict (409):
```json
{
  "success": false,
  "error": {
    "code": "slot_conflict",
    "message": "The requested time slot is no longer available",
    "details": {
      "conflicts": [...]
    }
  }
}
```

---

### PUT /v1/locations/{location_id}/bookings/{booking_id}

Headers: `Authorization: Bearer <access_token>`

**Use Case 1: Update Status or Notes**

Request:
```json
{
  "status": "confirmed",
  "notes": "Cliente confermato via telefono"
}
```

**Use Case 2: Reschedule (Change Date/Time)**

Request:
```json
{
  "start_time": "2025-12-30T14:00:00+01:00",
  "notes": "Riprogrammazione appuntamento"
}
```

Campi opzionali (almeno uno richiesto):
- `status`: "pending" | "confirmed" | "cancelled" | "completed" | "no_show"
- `notes`: stringa
- `start_time`: ISO8601 datetime per reschedule

**Note sul Reschedule**:
- Aggiorna tutti i `booking_items` mantenendo durate e intervalli relativi
- Non permette cambio servizi o staff
- Soggetto a cancellation policy (stesso vincolo di DELETE)
- ✅ Availability check server-side: verifica conflitti staff con `FOR UPDATE`
- Transazione atomica per evitare race conditions

Response (200):
```json
{
  "success": true,
  "data": {
    "id": 42,
    "status": "confirmed",
    "notes": "Cliente confermato via telefono",
    "items": [
      {
        "id": 101,
        "start_time": "2025-12-30T14:00:00+01:00",
        "end_time": "2025-12-30T15:00:00+01:00",
        ...
      }
    ],
    ...
  }
}
```

Error - Not Found (404):
```json
{
  "success": false,
  "error": {
    "code": "not_found",
    "message": "Booking not found"
  }
}
```

Error - Unauthorized (403):
```json
{
  "success": false,
  "error": {
    "code": "unauthorized",
    "message": "You do not have permission to update this booking"
  }
}
```

Error - Cancellation Policy Violation (400):
```json
{
  "success": false,
  "error": {
    "code": "validation_error",
    "message": "Cannot modify booking within 24 hours of appointment start time",
    "details": {
      "cancellation_deadline": "2025-12-29T14:00:00+01:00"
    }
  }
}
```
  }
}
```

---

### DELETE /v1/locations/{location_id}/bookings/{booking_id}

Headers: `Authorization: Bearer <access_token>`

Cancella un booking e tutti i suoi booking_items associati.

Response (200):
```json
{
  "success": true,
  "data": {
    "message": "Booking deleted successfully"
  }
}
```

Error - Not Found (404):
```json
{
  "success": false,
  "error": {
    "code": "not_found",
    "message": "Booking not found"
  }
}
```

Error - Unauthorized (403):
```json
{
  "success": false,
  "error": {
    "code": "unauthorized",
    "message": "You do not have permission to delete this booking"
  }
}
```

---

## Appointments (Gestionale)

### GET /v1/locations/{location_id}/appointments?date=YYYY-MM-DD

Get all appointments (booking_items) for a specific location and date.

**Auth required**: Yes  
**Middleware**: auth, location_path

Query params:
- `date` (required): Date in YYYY-MM-DD format

Response (200):
```json
{
  "success": true,
  "data": {
    "appointments": [
      {
        "id": 1,
        "booking_id": 10,
        "location_id": 1,
        "staff_id": 2,
        "service_variant_id": 5,
        "start_time": "2025-12-27T10:00:00+01:00",
        "end_time": "2025-12-27T10:30:00+01:00",
        "extra_blocked_minutes": 0,
        "extra_processing_minutes": 0,
        "booking_status": "confirmed",
        "client_name": "Mario Rossi",
        "service_name": "Taglio Uomo",
        "staff_name": "Anna Bianchi",
        "created_at": "2025-12-26T15:00:00+01:00",
        "updated_at": "2025-12-26T15:00:00+01:00"
      }
    ]
  }
}
```

---

### PATCH /v1/locations/{location_id}/appointments/{id}

Reschedule or update an appointment.

**Auth required**: Yes  
**Middleware**: auth, location_path  
**Permission**: Only booking owner can update

Request:
```json
{
  "start_time": "2025-12-27T11:00:00+01:00",
  "end_time": "2025-12-27T11:30:00+01:00",
  "staff_id": 3
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "booking_id": 10,
    "start_time": "2025-12-27T11:00:00+01:00",
    "end_time": "2025-12-27T11:30:00+01:00",
    "staff_id": 3,
    "..."
  }
}
```

---

### POST /v1/locations/{location_id}/appointments/{id}/cancel

Cancel an appointment.

**Auth required**: Yes  
**Middleware**: auth, location_path  
**Permission**: Only booking owner can cancel

Response (200):
```json
{
  "success": true,
  "data": {
    "cancelled": true,
    "appointment_id": 1
  }
}
```

---

## Clients (Gestionale)

### GET /v1/clients?business_id=X&search=term

Get clients for a business.

**Auth required**: Yes

Query params:
- `business_id` (required): Business ID
- `search` (optional): Search term (name, email, phone)
- `limit` (optional): Max results (default 100)
- `offset` (optional): Pagination offset

Response (200):
```json
{
  "success": true,
  "data": {
    "clients": [
      {
        "id": 1,
        "business_id": 1,
        "user_id": 5,
        "first_name": "Mario",
        "last_name": "Rossi",
        "email": "mario@example.com",
        "phone": "+39123456789",
        "notes": null,
        "is_archived": false,
        "created_at": "2025-01-01T10:00:00+01:00",
        "updated_at": "2025-01-01T10:00:00+01:00"
      }
    ]
  }
}
```

---

### POST /v1/clients

Create a new client.

**Auth required**: Yes

Request:
```json
{
  "business_id": 1,
  "first_name": "Mario",
  "last_name": "Rossi",
  "email": "mario@example.com",
  "phone": "+39123456789",
  "notes": "Cliente VIP"
}
```

Response (201):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "business_id": 1,
    "first_name": "Mario",
    "..."
  }
}
```

---

### PUT /v1/clients/{id}

Update a client.

**Auth required**: Yes

Request:
```json
{
  "first_name": "Mario",
  "last_name": "Rossi",
  "email": "newemail@example.com",
  "phone": "+39987654321",
  "notes": "Updated notes",
  "is_archived": false
}
```

---

### DELETE /v1/clients/{id}

Archive a client (soft delete).

**Auth required**: Yes

Response (200):
```json
{
  "success": true,
  "data": {
    "deleted": true
  }
}
```

---

## Business Users (Operators) Endpoints

Endpoints per gestire gli operatori di un business (chi può accedere al gestionale).

### GET /v1/businesses/{business_id}/users

List operators for a business.

**Auth required**: Yes (owner/admin or superadmin)

Response (200):
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 1,
        "user_id": 2,
        "business_id": 1,
        "role": "owner",
        "email": "anna@example.com",
        "first_name": "Anna",
        "last_name": "Bianchi",
        "status": "active",
        "invited_at": null,
        "joined_at": "2025-01-01T10:00:00+01:00",
        "is_current_user": true
      },
      {
        "id": 2,
        "user_id": 3,
        "business_id": 1,
        "role": "staff",
        "email": "mario@example.com",
        "first_name": "Mario",
        "last_name": "Rossi",
        "status": "active",
        "invited_at": "2025-12-28T10:00:00+01:00",
        "joined_at": "2025-12-28T12:00:00+01:00",
        "is_current_user": false
      }
    ]
  }
}
```

---

### POST /v1/businesses/{business_id}/users

Add an existing user to a business.

**Auth required**: Yes (owner/admin or superadmin)

Request:
```json
{
  "user_id": 5,
  "role": "staff"
}
```

Response (201):
```json
{
  "success": true,
  "data": {
    "id": 3,
    "user_id": 5,
    "business_id": 1,
    "role": "staff"
  }
}
```

Errors:
- `already_member` (409): User già membro del business
- `forbidden` (403): Non puoi assegnare un ruolo >= al tuo

---

### PATCH /v1/businesses/{business_id}/users/{user_id}

Update operator role.

**Auth required**: Yes (owner/admin or superadmin)

Request:
```json
{
  "role": "manager"
}
```

Response (200):
```json
{
  "success": true,
  "data": {
    "id": 2,
    "user_id": 3,
    "role": "manager"
  }
}
```

---

### DELETE /v1/businesses/{business_id}/users/{user_id}

Remove operator from business.

**Auth required**: Yes (owner/admin or superadmin)

Response (200):
```json
{
  "success": true,
  "data": {
    "removed": true
  }
}
```

Errors:
- `forbidden` (403): Non puoi rimuovere owner o te stesso

---

## Business Invitations Endpoints

Endpoints per gestire inviti via email agli operatori.

### GET /v1/businesses/{business_id}/invitations

List pending invitations for a business.

**Auth required**: Yes (owner/admin or superadmin)

Response (200):
```json
{
  "success": true,
  "data": {
    "invitations": [
      {
        "id": 1,
        "email": "nuovo@example.com",
        "role": "staff",
        "expires_at": "2026-01-04T14:00:00+01:00",
        "created_at": "2025-12-28T14:00:00+01:00",
        "invited_by": {
          "first_name": "Anna",
          "last_name": "Bianchi"
        }
      }
    ]
  }
}
```

---

### POST /v1/businesses/{business_id}/invitations

Create a new invitation.

**Auth required**: Yes (owner/admin or superadmin)

Request:
```json
{
  "email": "nuovo@example.com",
  "role": "staff"
}
```

Response (201):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "nuovo@example.com",
    "role": "staff",
    "token": "abc123...",
    "expires_at": "2026-01-04T14:00:00+01:00",
    "invite_url": "https://app.example.com/invite/abc123...",
    "business": {
      "id": 1,
      "name": "Salone Bella Vita"
    }
  }
}
```

Errors:
- `validation_error` (400): Email già membro del business
- `validation_error` (400): Invito già pendente per questa email
- `forbidden` (403): Non puoi invitare con ruolo >= al tuo

---

### DELETE /v1/businesses/{business_id}/invitations/{invitation_id}

Revoke a pending invitation.

**Auth required**: Yes (owner/admin or superadmin)

Response (200):
```json
{
  "success": true,
  "data": {
    "message": "Invitation revoked",
    "id": 1
  }
}
```

---

### GET /v1/invitations/{token}

Get invitation details (public endpoint, no auth required).

Response (200):
```json
{
  "success": true,
  "data": {
    "email": "nuovo@example.com",
    "role": "staff",
    "business": {
      "id": 1,
      "name": "Salone Bella Vita",
      "slug": "salone-bella-vita"
    },
    "expires_at": "2026-01-04T14:00:00+01:00"
  }
}
```

Errors:
- `not_found` (404): Token non valido
- `validation_error` (400): Invito scaduto o già usato

---

### POST /v1/invitations/{token}/accept

Accept an invitation.

**Auth required**: Yes (email must match invitation)

Response (200):
```json
{
  "success": true,
  "data": {
    "message": "Invitation accepted",
    "business_id": 1,
    "business_name": "Salone Bella Vita",
    "role": "staff"
  }
}
```

Errors:
- `not_found` (404): Token non valido
- `validation_error` (400): Invito scaduto
- `forbidden` (403): Email non corrisponde all'invito

---

## Business Context Derivation

| Endpoint Type | location_id Source | business_id |
|---------------|-------------------|-------------|
| Auth | N/A | N/A |
| Public | Query param `?location_id=X` | DB lookup da location_id |
| POST /bookings | PATH param `/locations/{X}/...` | DB lookup da location_id |

**IMPORTANTE**: JWT contiene SOLO `user_id`. MAI `business_id` o `location_id`.

---

## Error Codes

| Code | HTTP | Descrizione |
|------|------|-------------|
| `invalid_credentials` | 401 | Email o password errati |
| `account_disabled` | 401 | Account disabilitato |
| `token_expired` | 401 | Access token scaduto |
| `token_invalid` | 401 | Token malformato o firma invalida |
| `session_revoked` | 401 | Refresh token revocato |
| `unauthorized` | 401 | Authorization header mancante |
| `missing_location` | 400 | location_id non fornito |
| `invalid_location` | 400 | Location non esiste o non attiva |
| `slot_conflict` | 409 | Slot già occupato |
| `invalid_service` | 400 | Servizio non valido |
| `invalid_staff` | 400 | Staff non disponibile |
| `invalid_time` | 400 | Orario non valido |
| `validation_error` | 400 | Errore di validazione generico |
| `not_found` | 404 | Risorsa non trovata |
| `internal_error` | 500 | Errore interno |

---

## Idempotency

Per `POST /bookings`, inviare header `X-Idempotency-Key: <uuid>`.

Se una richiesta con lo stesso `idempotency_key` viene ripetuta (stesso business):
- Se booking già creato → ritorna booking esistente (200)
- Se in corso → attende completamento

Chiave unica: `(business_id, idempotency_key)`
