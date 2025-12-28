# DB Schema MVP — agenda_core

Schema MySQL/MariaDB per la piattaforma Agenda multi-tenant.

---

## 🏗️ Architettura Multi-Tenant

### Modello di Identità

| Entità | Scope | Note |
|--------|-------|------|
| `users` | **GLOBALE** | Solo per login/auth. Nessun business_id. |
| `clients` | **PER BUSINESS** | Anagrafica locale. Ha business_id e user_id opzionale. |

Un utente può essere client di più business tramite più record `clients`.
Ogni business vede esclusivamente i propri clients.

### JWT

| Campo | Presente | Note |
|-------|----------|------|
| user_id | ✅ | Identità utente |
| business_id | ❌ | MAI nel JWT |
| location_id | ❌ | MAI nel JWT |

### Derivazione contesto business

| Campo | Origine | Quando |
|-------|---------|--------|
| `location_id` | **PATH parameter** | Sempre. Es: `/v1/locations/{location_id}/bookings` |
| `business_id` | **Lookup DB** | `SELECT business_id FROM locations WHERE id = :location_id` |

**⚠️ IMPORTANTE:** 
- Il contesto business deriva SEMPRE dal `location_id` nel PATH
- `business_id` NON è nel payload, NON è nel JWT
- Il server lo ricava dal database partendo da `location_id`

---

## 📊 Diagramma ER semplificato

```
┌─────────────┐     ┌─────────────┐
│  businesses │────<│  locations  │
└─────────────┘     └─────────────┘
       │                   │
       │                   ├──────────────────┐
       │                   ▼                  ▼
       │            ┌─────────────┐    ┌───────────────┐
       │            │    staff    │    │   resources   │
       │            └─────────────┘    └───────────────┘
       │                   │
       ▼                   │
┌────────────────┐         │
│ business_users │─────────┤ (staff_id opzionale)
└────────────────┘         │
       │                   │
       ▼                   │
┌─────────────┐            │
│    users    │            │
└─────────────┘            │
       │                   │
       ▼                   │
┌───────────────┐          │
│ auth_sessions │          │
└───────────────┘          │
                           │
┌─────────────┐            │
│  services   │            │
└─────────────┘            │
       │                   │
       ▼                   │
┌──────────────────┐       │
│ service_variants │───────┘
└──────────────────┘
       │
       ▼
┌─────────────┐     ┌───────────────┐
│  bookings   │────<│ booking_items │
└─────────────┘     └───────────────┘
       ▲
       │
┌─────────────┐
│   clients   │
└─────────────┘
```

---

## 📋 Tabelle

### 1. businesses
Tenant principale. Ogni business è completamente isolato.

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| name | VARCHAR(255) NOT NULL | |
| slug | VARCHAR(100) UNIQUE NOT NULL | Per URL pubblici |
| email | VARCHAR(255) | |
| phone | VARCHAR(50) | |
| timezone | VARCHAR(50) DEFAULT 'Europe/Rome' | |
| currency | VARCHAR(3) DEFAULT 'EUR' | |
| cancellation_hours | INT UNSIGNED DEFAULT 24 | Default policy: ore minime prima appuntamento per cancellare/modificare |
| is_active | TINYINT(1) DEFAULT 1 | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

### 2. locations
Sedi fisiche di un business.

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| business_id | INT UNSIGNED FK NOT NULL | |
| name | VARCHAR(255) NOT NULL | |
| address | VARCHAR(500) | |
| city | VARCHAR(100) | |
| postal_code | VARCHAR(20) | Aggiunto in migration 0009 |
| region | VARCHAR(100) | |
| country | VARCHAR(100) DEFAULT 'IT' | |
| phone | VARCHAR(50) | |
| email | VARCHAR(255) | |
| latitude | DECIMAL(10,8) | |
| longitude | DECIMAL(11,8) | |
| timezone | VARCHAR(50) DEFAULT 'Europe/Rome' | Aggiunto in migration 0005 |
| currency | VARCHAR(3) | Override business |
| cancellation_hours | INT UNSIGNED NULL | Override business cancellation policy. NULL = usa business default |
| is_default | TINYINT(1) DEFAULT 0 | |
| is_active | TINYINT(1) DEFAULT 1 | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

### 3. users
Utenti GLOBALI per autenticazione. Non appartengono a nessun business.
Un utente può operare con più business diversi tramite la tabella `business_users` (operatori gestionale) o `clients` (clienti prenotazione).

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| email | VARCHAR(255) UNIQUE NOT NULL | Globale, non per business |
| password_hash | VARCHAR(255) NOT NULL | bcrypt/argon2 |
| first_name | VARCHAR(100) NOT NULL | |
| last_name | VARCHAR(100) NOT NULL | |
| phone | VARCHAR(50) | |
| email_verified_at | TIMESTAMP | |
| is_active | TINYINT(1) DEFAULT 1 | |
| is_superadmin | TINYINT(1) DEFAULT 0 | Ruolo globale: può gestire tutti i business senza record in business_users |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

**Superadmin**: Non ha record in `business_users`. Quando seleziona un business, opera come admin.

### 3a. business_users
Associazione utenti-business per operatori del gestionale (multi-tenant access control).

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| business_id | INT UNSIGNED FK NOT NULL | |
| user_id | INT UNSIGNED FK NOT NULL | |
| role | ENUM('owner','admin','manager','staff') DEFAULT 'staff' | Gerarchia permessi |
| staff_id | INT UNSIGNED FK NULL | Link opzionale a record staff |
| can_manage_bookings | TINYINT(1) DEFAULT 1 | |
| can_manage_clients | TINYINT(1) DEFAULT 1 | |
| can_manage_services | TINYINT(1) DEFAULT 0 | |
| can_manage_staff | TINYINT(1) DEFAULT 0 | |
| can_view_reports | TINYINT(1) DEFAULT 0 | |
| is_active | TINYINT(1) DEFAULT 1 | |
| invited_by | INT UNSIGNED FK NULL | User che ha invitato |
| invited_at | TIMESTAMP NULL | |
| accepted_at | TIMESTAMP NULL | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

UNIQUE (business_id, user_id)

**Ruoli e permessi default:**
| Ruolo | bookings | clients | services | staff | reports |
|-------|----------|---------|----------|-------|---------|
| owner | ✅ | ✅ | ✅ | ✅ | ✅ |
| admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| manager | ✅ | ✅ | ❌ | ❌ | ✅ |
| staff | ✅* | ✅* | ❌ | ❌ | ❌ |

*staff: solo propri appuntamenti/clienti di default

### 3b. business_invitations
Inviti via email per nuovi operatori del business.

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| business_id | INT UNSIGNED FK NOT NULL | |
| email | VARCHAR(255) NOT NULL | Email destinatario |
| role | ENUM('admin','manager','staff') DEFAULT 'staff' | Ruolo assegnato |
| token | VARCHAR(64) NOT NULL UNIQUE | Token hex 64 caratteri |
| expires_at | TIMESTAMP NOT NULL | Default: +7 giorni |
| status | ENUM('pending','accepted','expired','revoked') DEFAULT 'pending' | |
| accepted_by | INT UNSIGNED FK NULL | User che ha accettato |
| accepted_at | TIMESTAMP NULL | |
| invited_by | INT UNSIGNED FK NOT NULL | User che ha invitato |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

UNIQUE (business_id, email, status) - un solo invito pending per email

**Indexes:**
- `(token, status)` - lookup per accettazione
- `(business_id, status)` - lista inviti pendenti
- `(email, status)` - ricerca inviti per email

**Flusso invito:**
1. Owner/Admin crea invito → genera token
2. Email inviata con link `/invite/{token}`
3. Destinatario apre link, fa login/register
4. `POST /v1/invitations/{token}/accept` → crea record `business_users`

### 4. auth_sessions
Sessioni di autenticazione con refresh token (hash, mai in chiaro).

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| user_id | INT UNSIGNED FK NOT NULL | |
| refresh_token_hash | VARCHAR(255) NOT NULL | SHA-256 del token |
| user_agent | VARCHAR(500) | Per identificare device |
| ip_address | VARCHAR(45) | IPv4 o IPv6 |
| expires_at | TIMESTAMP NOT NULL | Scadenza refresh token |
| last_used_at | TIMESTAMP | Ultimo utilizzo (per rotation) |
| revoked_at | TIMESTAMP | Se revocato manualmente |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |

**Rotation pattern:**
1. Al refresh, si crea una nuova sessione con nuovo `refresh_token_hash`
2. La vecchia sessione viene marcata con `revoked_at = NOW()`
3. Se un token revocato viene riutilizzato → si revocano TUTTE le sessioni utente (possibile furto)

### 5. service_categories
Categorie di servizi per organizzazione.

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| business_id | INT UNSIGNED FK NOT NULL | |
| name | VARCHAR(255) NOT NULL | |
| description | TEXT | |
| sort_order | INT DEFAULT 0 | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

### 6. services
Servizi offerti dal business.

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| business_id | INT UNSIGNED FK NOT NULL | |
| category_id | INT UNSIGNED FK NOT NULL | |
| name | VARCHAR(255) NOT NULL | |
| description | TEXT | |
| sort_order | INT DEFAULT 0 | |
| is_active | TINYINT(1) DEFAULT 1 | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

### 7. service_variants
Varianti di servizio per location (durata, prezzo, disponibilità online).

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| service_id | INT UNSIGNED FK NOT NULL | |
| location_id | INT UNSIGNED FK NOT NULL | |
| duration_minutes | INT UNSIGNED NOT NULL | |
| processing_time | INT UNSIGNED | Minuti post-lavorazione |
| blocked_time | INT UNSIGNED | Minuti bloccati |
| price | DECIMAL(10,2) NOT NULL DEFAULT 0 | |
| currency | VARCHAR(3) | Override location |
| color_hex | VARCHAR(7) | Es. #FF5733 |
| is_bookable_online | TINYINT(1) DEFAULT 1 | |
| is_free | TINYINT(1) DEFAULT 0 | |
| is_price_starting_from | TINYINT(1) DEFAULT 0 | "da €X" |
| is_active | TINYINT(1) DEFAULT 1 | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

UNIQUE (service_id, location_id)

### 8. staff
Operatori/dipendenti del business.

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| business_id | INT UNSIGNED FK NOT NULL | |
| name | VARCHAR(100) NOT NULL | |
| surname | VARCHAR(100) DEFAULT '' | |
| color_hex | VARCHAR(7) DEFAULT '#FFD700' | |
| avatar_url | VARCHAR(500) | |
| sort_order | INT DEFAULT 0 | |
| is_default | TINYINT(1) DEFAULT 0 | |
| is_bookable_online | TINYINT(1) DEFAULT 1 | |
| is_active | TINYINT(1) DEFAULT 1 | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

### 9. staff_locations
Relazione N:M staff ↔ locations.

| Colonna | Tipo | Note |
|---------|------|------|
| staff_id | INT UNSIGNED FK NOT NULL | PK part |
| location_id | INT UNSIGNED FK NOT NULL | PK part |

PRIMARY KEY (staff_id, location_id)

### 9a. staff_services
Restrizioni servizi per staff (quali servizi ogni staff può erogare).

| Colonna | Tipo | Note |
|---------|------|------|
| staff_id | INT UNSIGNED FK NOT NULL | PK part |
| service_id | INT UNSIGNED FK NOT NULL | PK part |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |

PRIMARY KEY (staff_id, service_id)

**Logica**: Se la tabella è vuota per uno staff, può erogare tutti i servizi (permissivo di default). Se esistono record, validare che lo staff possa erogare TUTTI i servizi richiesti.

### 9b. location_schedules
Orari di apertura per location per giorno della settimana.

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| location_id | INT UNSIGNED FK NOT NULL | |
| day_of_week | TINYINT UNSIGNED NOT NULL | 0=Sunday, 1=Monday, ..., 6=Saturday |
| open_time | TIME NOT NULL | Orario apertura (es. 09:00:00) |
| close_time | TIME NOT NULL | Orario chiusura (es. 18:00:00) |
| is_closed | TINYINT(1) DEFAULT 0 | Giorno chiuso |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

UNIQUE (location_id, day_of_week)

CHECK (day_of_week BETWEEN 0 AND 6)
CHECK (open_time < close_time OR is_closed = 1)

**Fallback**: Se non configurato, default 9:00-18:00 Lun-Ven.

### 10. clients
Clienti gestiti dal business (anagrafica gestionale).

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| business_id | INT UNSIGNED FK NOT NULL | |
| user_id | INT UNSIGNED FK | Link a user se registrato online |
| first_name | VARCHAR(100) | |
| last_name | VARCHAR(100) | |
| email | VARCHAR(255) | |
| phone | VARCHAR(50) | |
| gender | VARCHAR(20) | |
| birth_date | DATE | |
| city | VARCHAR(100) | |
| notes | TEXT | |
| loyalty_points | INT DEFAULT 0 | |
| last_visit | TIMESTAMP | |
| is_archived | TINYINT(1) DEFAULT 0 | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

INDEX (business_id, email)
INDEX (business_id, phone)

### 11. bookings
Prenotazioni (contenitore di uno o più servizi).

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| business_id | INT UNSIGNED FK NOT NULL | |
| location_id | INT UNSIGNED FK NOT NULL | |
| client_id | INT UNSIGNED FK | |
| user_id | INT UNSIGNED FK | User che ha prenotato online |
| customer_name | VARCHAR(255) | Fallback se no client |
| notes | TEXT | |
| status | ENUM('pending','confirmed','completed','cancelled','no_show') DEFAULT 'confirmed' | |
| source | ENUM('online','manual','import') DEFAULT 'manual' | |
| idempotency_key | VARCHAR(64) | Per idempotenza POST |
| idempotency_expires_at | TIMESTAMP | TTL per cleanup |

UNIQUE (business_id, idempotency_key) — scoped per tenant, evita collisioni globali
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

INDEX (business_id, location_id, created_at)
INDEX (client_id)
INDEX (user_id)

### 12. booking_items
Singoli appuntamenti/servizi dentro una booking (multi-servizio).

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| booking_id | INT UNSIGNED FK NOT NULL | |
| location_id | INT UNSIGNED FK NOT NULL | Denormalizzato per query availability |
| service_id | INT UNSIGNED FK NOT NULL | |
| service_variant_id | INT UNSIGNED FK NOT NULL | |
| staff_id | INT UNSIGNED FK NOT NULL | |
| start_time | TIMESTAMP NOT NULL | UTC |
| end_time | TIMESTAMP NOT NULL | UTC |
| price | DECIMAL(10,2) | Prezzo applicato |
| extra_blocked_minutes | INT UNSIGNED DEFAULT 0 | |
| extra_processing_minutes | INT UNSIGNED DEFAULT 0 | |
| service_name_snapshot | VARCHAR(255) | Denormalizzato |
| client_name_snapshot | VARCHAR(255) | Denormalizzato |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

INDEX (staff_id, start_time, end_time)
INDEX (location_id, start_time, end_time) — per availability senza JOIN

### 13. resources (opzionale MVP+)
Risorse fisiche (es. cabine, attrezzature).

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| location_id | INT UNSIGNED FK NOT NULL | |
| name | VARCHAR(255) NOT NULL | |
| quantity | INT UNSIGNED DEFAULT 1 | |
| type | VARCHAR(100) | |
| note | TEXT | |
| is_active | TINYINT(1) DEFAULT 1 | |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP ON UPDATE | |

---

## 🔐 Idempotenza per POST /bookings

### Strategia
1. Client genera un `Idempotency-Key` (UUID v4) e lo include nell'header
2. Server verifica se esiste già una booking con quella key:
   - **Esiste**: ritorna la booking esistente (HTTP 200, non 201)
   - **Non esiste**: crea la booking e salva la key
3. Le key scadono dopo 24h (cleanup via cron o TTL index)

### Colonne dedicate in `bookings`
```sql
idempotency_key VARCHAR(64) UNIQUE,
idempotency_expires_at TIMESTAMP
```

### Alternativa: tabella separata
Se si preferisce non "sporcare" la tabella bookings:
```sql
CREATE TABLE idempotency_keys (
  key_hash VARCHAR(64) PRIMARY KEY,
  resource_type VARCHAR(50) NOT NULL,
  resource_id INT UNSIGNED NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Scelta MVP:** Colonne dedicate in `bookings` (più semplice, meno join).

---

## 🔐 Password Reset Tokens

Tabella per gestire il flusso di password reset in modo sicuro.

### password_reset_tokens

| Colonna | Tipo | Note |
|---------|------|------|
| id | INT UNSIGNED PK AUTO_INCREMENT | |
| user_id | INT UNSIGNED NOT NULL | FK → users.id |
| token_hash | VARCHAR(64) NOT NULL | SHA-256 del token inviato via email |
| expires_at | TIMESTAMP NOT NULL | Validità 1 ora dalla creazione |
| used_at | TIMESTAMP NULL | NULL = non ancora usato |
| created_at | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | |

**Indici**:
```sql
INDEX idx_token_hash (token_hash)
INDEX idx_user_id (user_id)
INDEX idx_expires_at (expires_at)  -- Per cleanup automatico
```

**Foreign Keys**:
```sql
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
```

**Security**:
- Token plain-text inviato via email, mai salvato nel DB
- Solo SHA-256 hash salvato per lookup
- Token monouso: `used_at IS NULL` per validità
- Scadenza 1 ora per ridurre finestra attacco
- Cleanup automatico via cron o TTL index

**Flusso**:
1. `POST /auth/forgot-password` → genera token random (32 bytes), hash SHA-256, salva, invia email
2. User click link email → `POST /auth/reset-password` con token plain-text
3. Server calcola SHA-256(token), cerca in DB con `used_at IS NULL AND expires_at > NOW()`
4. Se valido: update password, marca `used_at = NOW()`, invalida sessioni

**Migration**: Inclusa in `FULL_DATABASE_SCHEMA.sql`

---

## 🕐 Gestione fusi orari

- **DB**: Tutti i `TIMESTAMP` sono in **UTC**
- **API**: Tutti gli orari in **ISO8601** con timezone (`2025-01-15T10:00:00+01:00`)
- **Conversione**: Il server converte da/verso UTC usando `businesses.timezone`

---

## 📈 Indici raccomandati

```sql
-- Query frequenti agenda
CREATE INDEX idx_booking_items_staff_time 
  ON booking_items(staff_id, start_time, end_time);

-- Disponibilità
CREATE INDEX idx_booking_items_location_time 
  ON booking_items(location_id, start_time, end_time);

-- Multi-tenant
CREATE INDEX idx_bookings_business_location 
  ON bookings(business_id, location_id);

-- Sessioni attive
CREATE INDEX idx_auth_sessions_user_expires 
  ON auth_sessions(user_id, expires_at, revoked_at);

-- Cleanup idempotency
CREATE INDEX idx_bookings_idempotency_expires 
  ON bookings(idempotency_expires_at);
```

---

## 🔄 Compatibilità con i client

### Frontend (BookingRequest → bookings + booking_items)
```
service_ids → booking_items.service_id (uno per ogni)
staff_id → booking_items.staff_id (se null, assegnato dal server)
start_time → booking_items.start_time (calcolato in sequenza)
notes → bookings.notes
```

### Backend (Appointment → booking_items)
La tabella `booking_items` corrisponde al modello `Appointment` del gestionale:
- `booking_id` = relazione con booking
- `service_id`, `service_variant_id`, `staff_id` = riferimenti
- `start_time`, `end_time` = slot temporale
- `extra_*_minutes` = tempi extra
- `*_snapshot` = valori denormalizzati per storico
