# Agenda Core API Server

Server API REST PHP per la piattaforma Agenda. Gestisce autenticazione, servizi, staff, disponibilità e prenotazioni.

## Requisiti

- PHP 8.2+
- MySQL 8.0+ o MariaDB 10.6+
- Composer

## Setup

### 1. Installare dipendenze

```bash
composer install
```

### 2. Configurare ambiente

```bash
cp .env.example .env
# Modificare .env con le credenziali del database
```

### 3. Creare database e applicare migrazioni

```bash
mysql -u root -p -e "CREATE DATABASE agenda_core CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Schema completo (unico file)
mysql -u root -p agenda_core < migrations/FULL_DATABASE_SCHEMA.sql

# Opzionale: dati di test
mysql -u root -p agenda_core < migrations/seed_data.sql
```

### 4. Avviare server di sviluppo

```bash
composer serve
# oppure
php -S localhost:8080 -t public
```

## Test

```bash
# Tutti i test con output dettagliato
./vendor/bin/phpunit --testdox

# Solo categoria specifica
./vendor/bin/phpunit --filter AuthUseCaseTest
./vendor/bin/phpunit --filter BookingUseCaseTest
./vendor/bin/phpunit --filter AvailabilityTest
```

**Risultati attesi**: 98 test, 195 asserzioni, 100% pass

## Endpoints

### Auth (pubblici)

| Metodo | Path | Descrizione |
|--------|------|-------------|
| POST | `/v1/auth/login` | Login con email/password |
| POST | `/v1/auth/register` | Registrazione nuovo utente |
| POST | `/v1/auth/refresh` | Rinnova access token |
| POST | `/v1/auth/logout` | Logout (revoca refresh token) |
| POST | `/v1/auth/forgot-password` | Richiedi reset password |
| POST | `/v1/auth/reset-password` | Conferma reset password |

### Auth (protetti)

| Metodo | Path | Descrizione |
|--------|------|-------------|
| GET | `/v1/me` | Profilo utente corrente |

### Pubblici (con location context)

| Metodo | Path | Descrizione |
|--------|------|-------------|
| GET | `/v1/services?location_id=X` | Lista servizi |
| GET | `/v1/staff?location_id=X` | Lista staff |
| GET | `/v1/availability?location_id=X&date=YYYY-MM-DD&service_ids=1,2` | Slot disponibili |
| GET | `/v1/businesses/{business_id}/locations/public` | Lista sedi attive (30/12/2025) |

### Gestionale - Clients (protetti)

| Metodo | Path | Descrizione |
|--------|------|-------------|
| GET | `/v1/clients?business_id=X` | Lista clienti |
| GET | `/v1/clients/{id}` | Dettaglio cliente |
| POST | `/v1/clients` | Crea cliente |
| PUT | `/v1/clients/{id}` | Aggiorna cliente |
| DELETE | `/v1/clients/{id}` | Archivia cliente |

### Gestionale - Appointments (protetti)

| Metodo | Path | Descrizione |
|--------|------|-------------|
| GET | `/v1/locations/{location_id}/appointments?date=YYYY-MM-DD` | Lista appuntamenti per data |
| GET | `/v1/locations/{location_id}/appointments/{id}` | Dettaglio appuntamento |
| PATCH | `/v1/locations/{location_id}/appointments/{id}` | Reschedule appuntamento |
| POST | `/v1/locations/{location_id}/appointments/{id}/cancel` | Cancella appuntamento |

### Protetti (con auth + location)

| Metodo | Path | Descrizione |
|--------|------|-------------|
| GET | `/v1/locations/{location_id}/bookings` | Lista prenotazioni |
| GET | `/v1/locations/{location_id}/bookings/{id}` | Dettaglio prenotazione |
| POST | `/v1/locations/{location_id}/bookings` | Crea prenotazione |
| PUT | `/v1/locations/{location_id}/bookings/{id}` | Aggiorna prenotazione |
| DELETE | `/v1/locations/{location_id}/bookings/{id}` | Cancella prenotazione |

## Autenticazione

- **Access Token**: JWT, 15 minuti TTL, in header `Authorization: Bearer <token>`
- **Refresh Token**: 64 hex chars, 90 giorni TTL, in cookie `httpOnly` o body

### Login Request

```json
POST /v1/auth/login
{
  "email": "mario.rossi@example.com",
  "password": "password123"
}
```

### Login Response

```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "abc123...",
    "expires_in": 900,
    "user": {
      "id": 1,
      "email": "mario.rossi@example.com",
      "first_name": "Mario",
      "last_name": "Rossi"
    }
  }
}
```

## Booking Payload (VINCOLANTE)

```json
POST /v1/locations/1/bookings
Headers:
  Authorization: Bearer <access_token>
  X-Idempotency-Key: <uuid>

{
  "service_ids": [1, 2],
  "staff_id": 1,
  "start_time": "2024-01-15T10:00:00Z",
  "notes": "Prima visita"
}
```

## Errori

### Formato errore standard

```json
{
  "success": false,
  "error": {
    "code": "error_code",
    "message": "Human readable message",
    "details": {}
  }
}
```

### Codici errore comuni

| Code | HTTP Status | Descrizione |
|------|-------------|-------------|
| `invalid_credentials` | 401 | Email/password errati |
| `token_expired` | 401 | Access token scaduto |
| `unauthorized` | 401 | Token mancante o invalido |
| `slot_conflict` | 409 | Slot già occupato |
| `invalid_service` | 400 | Servizio non trovato o non attivo |
| `invalid_staff` | 400 | Staff non disponibile per i servizi |
| `validation_error` | 400 | Errore di validazione input |

## Architettura

```
src/
├── Domain/
│   └── Exceptions/          # Business exceptions
├── Http/
│   ├── Controllers/         # Request handlers
│   ├── Middleware/          # Auth, Location, Idempotency
│   ├── Kernel.php           # Main application kernel
│   ├── Request.php          # Request wrapper
│   ├── Response.php         # JSON response builder
│   └── Router.php           # Minimal regex router
├── Infrastructure/
│   ├── Database/            # PDO connection
│   ├── Logger/              # File logger
│   ├── Repositories/        # Data access layer
│   └── Security/            # JWT, Password hashing
└── UseCases/
    ├── Auth/                # Login, Refresh, Logout, GetMe
    └── Booking/             # CreateBooking, ComputeAvailability
```

## Licenza

Proprietary
