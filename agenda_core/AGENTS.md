# AGENTS.md — agenda_core (Agenda Engine / Core Backend Services)

Questo file è la fonte di verità per qualsiasi agent AI che lavori su agenda_core.
DEVE essere letto prima di scrivere codice.

Compatibilità obbligatoria:
- Agenda Frontend (Flutter – prenotazione online)
- Agenda Backend (Flutter – gestionale)

⚠️ **TERMINOLOGIA OBBLIGATORIA:**
- Il termine **"frontend"** si riferisce SOLO al progetto `agenda_frontend` (prenotazioni clienti)
- Il termine **"backend"** si riferisce SOLO al progetto `agenda_backend` (gestionale operatori)
- Il termine **"core"** o **"API"** si riferisce al progetto `agenda_core` (backend PHP)
- NON usare "frontend" per indicare genericamente interfacce utente

⚠️ **SCHEMA DATABASE - TERMINOLOGIA:**
- **NON esiste** una tabella `appointments` nel database
- La tabella principale è `bookings` che contiene le prenotazioni
- Ogni booking può avere più righe in `booking_items` (i singoli servizi prenotati)
- Nel codice Flutter, il modello `Appointment` rappresenta un `booking_item` (singolo servizio), NON un booking completo

JSON snake_case.
I modelli e i campi già usati dai client NON devono essere rinominati.

Prenotazione pubblica, login obbligatorio solo per conferma.

Autenticazione:
- JWT access token breve (10–15 min)
- Refresh token lungo (30–90 gg) con rotazione
- Web: refresh in cookie httpOnly
- Mobile: refresh in secure storage

**Due tipi di autenticazione separati:**
1. **Operatore (users table)**: `POST /v1/auth/login` → token con `role: operator`
2. **Customer (clients table)**: `POST /v1/customer/{business_id}/auth/login` → token con `role: customer`

I token non sono intercambiabili:
- Customer token non può accedere a endpoint gestionale
- Operator token non può accedere a endpoint customer

Architettura obbligatoria:
- Http layer (routing, middleware)
- Use cases (CreateBooking, ComputeAvailability…)
- Domain (regole pure)
- Infrastructure (DB, log, provider)

Endpoint minimi:
- POST /v1/auth/login
- POST /v1/auth/refresh
- POST /v1/auth/logout
- GET  /v1/me
- PUT  /v1/me (aggiorna profilo)
- POST /v1/me/change-password (cambio password utente autenticato)
- GET  /v1/auth/verify-reset-token/{token} (verifica token reset)
- POST /v1/auth/reset-password (reset password con token)
- GET  /v1/services
- GET  /v1/staff
- GET  /v1/availability
- POST /v1/bookings (protetto, idempotente)
- POST /v1/admin/businesses/{id}/resend-invite (superadmin)

**Customer Auth Endpoints (self-service booking):**
- POST /v1/customer/{business_id}/auth/login
- POST /v1/customer/{business_id}/auth/register
- POST /v1/customer/{business_id}/auth/refresh
- POST /v1/customer/{business_id}/auth/logout
- POST /v1/customer/{business_id}/auth/forgot-password (richiede email reset)
- POST /v1/customer/auth/reset-password (reset con token)
- GET  /v1/customer/me (customer_auth)
- PUT  /v1/customer/me (customer_auth, aggiorna profilo)
- POST /v1/customer/me/change-password (customer_auth, cambio password)
- POST /v1/customer/{business_id}/bookings (customer_auth, idempotent)
- GET  /v1/customer/bookings (customer_auth)

Booking payload (VINCOLANTE):
- service_ids
- staff_id?
- start_time (ISO8601)
- notes?

Se uno slot è occupato:
- HTTP 409
- error.code = slot_conflict

Test (PHPUnit):
- 98 test, 195 asserzioni
- Eseguire: `./vendor/bin/phpunit --testdox`
- Classi repository sono `final` → NO mock, test logica pura
- JWT_SECRET richiesto in setUp()

Notifiche Email (M10):
- Provider configurabile via `.env`: MAIL_PROVIDER=smtp|brevo|mailgun
- Coda asincrona: notifiche NON bloccano booking flow
- Worker cron: `bin/notification-worker.php` (ogni minuto)
- Reminder cron: `bin/queue-reminders.php` (ogni ora)
- Template: bookingConfirmed, bookingCancelled, bookingReminder, bookingRescheduled
- **Test mode**: `NOTIFICATION_TEST_MODE=true` → email inviate a `nome.cognome@romeolab.it`

**Configurazione Sender Email (12/01/2026):**
- `MAIL_FROM_ADDRESS` deve essere un mittente **verificato su Brevo**
- Email business NON verificata → usare sender globale con reply-to al business
- Worker usa sender per canale (se presente), altrimenti `MAIL_FROM_ADDRESS`
- Variabili per canale (opzionali, mittenti verificati):
  - `MAIL_FROM_ADDRESS_BOOKING_CONFIRMED`
  - `MAIL_FROM_ADDRESS_BOOKING_REMINDER`
  - `MAIL_FROM_ADDRESS_BOOKING_CANCELLED`
  - `MAIL_FROM_ADDRESS_BOOKING_RESCHEDULED`
- `notification_queue.failed_at` viene azzerato quando la notifica va in `sent` (markSent) per evitare residui da retry riusciti.

**Template Variables (12/01/2026):**
| Template | Variabili obbligatorie |
|----------|------------------------|
| `bookingConfirmed` | client_name, business_name, location_name, location_address, location_city, location_phone, date, time, services, total_price, cancel_deadline, manage_url |
| `bookingReminder` | client_name, business_name, location_name, location_address, location_phone, date, time, services, manage_url |
| `bookingCancelled` | client_name, business_name, location_address, location_city, date, time, services, booking_url |
| `bookingRescheduled` | client_name, business_name, old_date, old_time, date, time, location_name, location_address, services, manage_url |

**Allegato Calendario ICS (05/02/2026):**
I template `bookingConfirmed`, `bookingReminder` e `bookingRescheduled` includono un file `.ics` come allegato per aggiungere l'appuntamento al calendario.

**Caratteristiche:**
- File ICS allegato direttamente all'email (compatibile con tutti i client email)
- Nome file: `appuntamento.ics`
- Compatibile con: Apple Calendar, Google Calendar, Outlook, altri client iCal
- Se `end_time` mancante, l'allegato non viene generato (graceful degradation)

**File PHP:**
- `src/Infrastructure/Notifications/CalendarICSGenerator.php` - generatore ICS
- Metodo principale: `generateIcs()` - genera contenuto file ICS

**Requisiti dati booking:**
Per generare l'allegato ICS, il booking deve includere `end_time`.

**Template Email - Stile e Localizzazione (15/01/2026):**

| Elemento | Valore |
|----------|--------|
| **Colore principale** | `#2196F3` (blu accent, come frontend) |
| **Background body** | `#f5f5f5` |
| **Background container** | `#ffffff` |
| **Background box dati** | `#f8f9fa` con `border-radius: 8px` |

**Ordine campi nel box dati (uniforme per tutti i template):**
1. Location (sede) - `{{location_block_html}}`
2. Data/Ora
3. Cosa (servizi)
4. Totale (solo in bookingConfirmed)

**Localizzazione IT/EN:**
| Campo | Italiano | English |
|-------|----------|---------|
| Label servizi | **Cosa** | **What** |
| Footer | Il team di {{business_name}} | The {{business_name}} Team |

**Validazione orario (15/01/2026):**
Le email NON vengono inviate se l'orario di inizio appuntamento è già passato (timezone della location):
- `QueueBookingConfirmation` - skip se start_time < now
- `QueueBookingCancellation` - skip se start_time < now
- `QueueBookingRescheduled` - skip se new_start_time < now
- `QueueBookingReminder` - skip se start_time < now

**URL "Gestisci Prenotazione":**
Il pulsante nelle email punta a: `https://prenota.romeolab.it/{business_slug}/my-bookings`

Cron Jobs (02/01/2026):
| Job | Comando | Intervallo | Scopo |
|-----|---------|------------|-------|
| notification-worker | `php bin/notification-worker.php` | `* * * * *` | Invia email dalla coda |
| queue-reminders | `php bin/queue-reminders.php` | `0 * * * *` | Accoda reminder appuntamenti |
| cleanup-sessions | `php bin/cleanup-sessions.php` | `0 3 1 * *` | Pulisce sessioni e log vecchi |
| compute-popular-services | `php bin/compute-popular-services.php` | `0 4 * * 0` | Calcola top 5 servizi più prenotati |

Formato comando cron SiteGround:
```
cd /home/u1251-kkefwq4fumer/www/api.romeolab.it && php bin/[worker].php >> logs/[worker].log 2>&1
```

File .env:
- `.env` → configurazione REALE (non committato, in .gitignore)
- `.env.example` → TEMPLATE con placeholder (committato)
- I due file DEVONO avere le STESSE variabili, sempre allineati
- Quando si aggiunge una variabile a `.env.example`, aggiungerla anche a `.env`
- `.env.example` usa valori placeholder, `.env` usa valori reali

Cleanup Worker (02/01/2026):
- File: `bin/cleanup-sessions.php`
- Elimina sessioni scadute/revocate da >30 giorni (`auth_sessions`, `client_sessions`)
- Elimina token reset usati/scaduti (`password_reset_token_users`, `password_reset_token_clients`)
- Tronca log >10MB mantenendo ultime 1000 righe
- Elimina file `.log.*` più vecchi di 30 giorni
- Eseguire: primo del mese alle 03:00 (`0 3 1 * *`)

---

## 🔑 BACKUP CREDENZIALI PRODUZIONE (02/01/2026)

### Posizione backup
- **iCloud Drive**: `Backup_Credenziali_Agenda/`
- **Password Manager**: voce "Agenda RomeoLab - Produzione"

### File di backup
| File | Contenuto |
|------|-----------|
| `BACKUP_ENV_PRODUZIONE_YYYYMMDD.txt` | Intero `.env` produzione |
| `BACKUP_SSH_KEY_SITEGROUND_YYYYMMDD` | Chiave privata SSH |
| `BACKUP_SSH_KEY_SITEGROUND_YYYYMMDD.pub` | Chiave pubblica SSH |

### ⚠️ QUANDO AGGIORNARE I BACKUP

Aggiornare backup su iCloud + Password Manager quando si modifica:
- `JWT_SECRET` → tutti gli utenti devono riloggarsi
- `DB_PASSWORD` → credenziali database
- `BREVO_API_KEY` → chiave API email
- Chiave SSH SiteGround

### Comando per rigenerare backup

```bash
# Backup .env produzione
ssh siteground "cat www/api.romeolab.it/.env" > ~/Library/Mobile\ Documents/com~apple~CloudDocs/Backup_Credenziali_Agenda/BACKUP_ENV_PRODUZIONE_$(date +%Y%m%d).txt

# Backup chiave SSH (se cambiata)
cp ~/.ssh/siteground_ed25519 ~/Library/Mobile\ Documents/com~apple~CloudDocs/Backup_Credenziali_Agenda/BACKUP_SSH_KEY_SITEGROUND_$(date +%Y%m%d)
cp ~/.ssh/siteground_ed25519.pub ~/Library/Mobile\ Documents/com~apple~CloudDocs/Backup_Credenziali_Agenda/BACKUP_SSH_KEY_SITEGROUND_$(date +%Y%m%d).pub
```

### Credenziali da tenere nel Password Manager
- DB: host, database, username, password
- JWT_SECRET (intero)
- BREVO_API_KEY (intero)
- SSH: user (`u1251-kkefwq4fumer`), porta (`18765`)

---

## 🚨 REGOLE DEPLOY CRITICHE — LEGGERE PRIMA DI OGNI DEPLOY

### Mapping ESATTO Progetto → URL → Cartella SiteGround

**PRODUZIONE:**

| Progetto | Descrizione | URL Produzione | Cartella SiteGround |
|----------|-------------|----------------|---------------------|
| **agenda_core** | API PHP Backend | api.romeolab.it | `www/api.romeolab.it/` |
| **agenda_frontend** | Prenotazioni CLIENTI | **prenota**.romeolab.it | `www/prenota.romeolab.it/public_html/` |
| **agenda_backend** | Gestionale OPERATORI | **gestionale**.romeolab.it | `www/gestionale.romeolab.it/public_html/` |

### ⚠️ ERRORI COMUNI DA EVITARE

❌ **MAI** deployare `agenda_backend` su `prenota.romeolab.it`  
❌ **MAI** deployare `agenda_frontend` su `gestionale.romeolab.it`  
❌ **MAI** confondere i due progetti Flutter

### Come distinguere i progetti Flutter:

| Caratteristica | agenda_frontend (PRENOTA) | agenda_backend (GESTIONALE) |
|----------------|---------------------------|-----------------------------|
| **Scopo** | Clienti prenotano online | Operatori gestiscono agenda |
| **Route principale** | `/:slug/booking` | `/agenda` |
| **Features** | `booking/` | `agenda/`, `clients/`, `staff/` |
| **Ha drag & drop** | ❌ No | ✅ Sì |
| **Ha StatefulShellRoute** | ❌ No | ✅ Sì |
| **Usa routeSlugProvider** | ✅ Sì | ❌ No |

### Comandi Deploy PRODUZIONE

```bash
# 1️⃣ FRONTEND PRENOTAZIONI (agenda_frontend → prenota.romeolab.it)
cd /path/to/agenda_frontend
flutter build web --release --dart-define=API_BASE_URL=https://api.romeolab.it
rsync -avz --delete build/web/ siteground:www/prenota.romeolab.it/public_html/

# 2️⃣ GESTIONALE (agenda_backend → gestionale.romeolab.it)  
cd /path/to/agenda_backend
flutter build web --release --dart-define=API_BASE_URL=https://api.romeolab.it
rsync -avz --delete build/web/ siteground:www/gestionale.romeolab.it/public_html/

# 3️⃣ API (agenda_core → api.romeolab.it)
rsync -avz public/ siteground:www/api.romeolab.it/public_html/
rsync -avz --delete src/ siteground:www/api.romeolab.it/src/
rsync -avz --delete vendor/ siteground:www/api.romeolab.it/vendor/
```

### Checklist PRE-DEPLOY

- [ ] Sono nella cartella CORRETTA del progetto?
- [ ] Il nome cartella corrisponde al progetto giusto?
- [ ] L'URL di destinazione è quello CORRETTO?
- [ ] Ho incrementato `window.appVersion` in `web/index.html`? (vedi formato sotto)

---

Deploy Produzione (28/12/2025):
- API: https://api.romeolab.it
- Frontend: https://prenota.romeolab.it
- Gestionale: https://gestionale.romeolab.it
- Hosting: SiteGround condiviso
- CORS: `CORS_ALLOWED_ORIGINS=https://prenota.romeolab.it,https://gestionale.romeolab.it,http://localhost:8080`

**SSH Accesso Configurato (10/01/2026):**
- Host alias: `siteground`
- HostName: `ssh.romeolab.it`
- User: `u1251-kkefwq4fumer`
- Port: `18765`
- IdentityFile: `~/.ssh/siteground_ed25519`
- Configurazione in `~/.ssh/config`

⚠️ DEPLOY agenda_core — SOLO QUESTE CARTELLE:
- `public_html/` → entry point (index.php, .htaccess)
- `src/` → codice sorgente PHP
- `vendor/` → dipendenze Composer
- `bin/` → worker notifiche (opzionale, se cron attivo)

MAI deployare: `docs/`, `tests/`, `scripts/`, `migrations/`, `lib/`, `.git/`, `*.md`, `phpunit.xml`, `composer.json`

Comando deploy corretto:
```bash
rsync -avz public/ siteground:www/api.romeolab.it/public_html/
rsync -avz --delete src/ siteground:www/api.romeolab.it/src/
rsync -avz --delete vendor/ siteground:www/api.romeolab.it/vendor/
```

⚠️ VERSIONE CACHE BUSTING (01/02/2026):

**Formato versione Flutter:** `YYYYMMDD-N.P`
```
YYYYMMDD-N.P
│        │ │
│        │ └── P = Numero progressivo deploy PRODUZIONE (incrementa AUTOMATICAMENTE con deploy.sh)
│        └──── N = Contatore giornaliero modifiche (incrementa automaticamente)
└───────────── Data (anno, mese, giorno)
```

**Esempio:** `20260201-1.10` = prima modifica del 01/02/2026, decimo deploy in produzione

**Gli script `deploy.sh` incrementano P automaticamente:**
- `deploy.sh` → incrementa P (+1 ad ogni deploy produzione)

**File coinvolti:**
- `web/index.html` → definizione `window.appVersion`
- `web/app_version.txt` → versione plain text per VersionChecker

⚠️ **REGOLA:** Il numero **P** incrementa SOLO per deploy PRODUZIONE.

⚠️ STRUTTURA PROGETTO vs DEPLOY SITEGROUND (31/12/2025):

Nel progetto locale:
- `index.php` e `.htaccess` sono in `public/`
- I path usano `__DIR__ . '/../vendor/autoload.php'` (vendor nella parent)

Su SiteGround (deploy):
- La document root è SEMPRE `public_html` (obbligatorio)
- `public/` viene mappata come `public_html/` con rsync
- I path sono già corretti, nessuna modifica necessaria

Deploy:
```bash
rsync -avz public/ siteground:www/api.romeolab.it/public_html/
```

Vedi DEPLOY.md sezione 12 per comandi completi.

CORS e Cache Headers (30/12/2025):
- Variabile env: `CORS_ALLOWED_ORIGINS` (NON `CORS_ORIGIN`)
- Response.php aggiunge: `Vary: Origin` per proxy caching corretto
- Response.php aggiunge: `Cache-Control: no-store, no-cache, must-revalidate`
- SiteGround proxy può cachare risposte → header Vary evita CORS errors
- Se CORS fallisce dopo deploy: purgare cache da SiteGround Site Tools

Multi-Business Path-Based (29/12/2025):
- Struttura URL: `/{slug}/booking`, `/{slug}/login`, ecc.
- SiteGround shared hosting: NO wildcard DNS, NO subdomain routing
- Router Flutter estrae slug dal path e aggiorna `routeSlugProvider`
- Landing page (`/`) mostra "Business non specificato"
- Slug inesistente → mostra "Business non trovato" (404 API gestito gracefully)
- Reset password globale: `/reset-password/:token` (senza business context)

Superadmin Business Management (30/12/2025):
- Endpoint CRUD: GET/POST/PUT/DELETE `/v1/admin/businesses`
- PUT `/v1/admin/businesses/{id}` per modifica business
- UseCase `CreateBusiness` con transazione atomica (rollback su errore)
- UseCase `UpdateBusiness` per aggiornamento campi
- Frontend: `BusinessListScreen`, dialogs create/edit
- Flow: superadmin → /businesses → seleziona/crea/modifica → /agenda
- Pulsante "Cambia" in navigation per tornare alla lista business
- **MAI usare StateProvider** → sempre Notifier + NotifierProvider

Multi-Location Support (30/12/2025):
- Endpoint pubblico: `GET /v1/businesses/{business_id}/locations/public`
- Ritorna locations attive con campi limitati (id, name, address, city, phone, timezone, is_default)
- Controller: `LocationsController::indexPublic()` usa `$request->getAttribute('business_id')`
- **NON** usare `getRouteParam()` per route pubbliche senza middleware auth
- Frontend: step "Sede" nel booking flow se business ha >1 location

Profilo Utente e Admin Email (31/12/2025):
- `PUT /v1/me` → aggiorna profilo utente (first_name, last_name, email, phone)
- UseCase `UpdateProfile` in `src/UseCases/Auth/UpdateProfile.php`
- Validazione email unica (errore se già esistente)
- CreateBusiness: `admin_email` è OPZIONALE (business può essere creato senza owner)
- UpdateBusiness: può aggiungere admin a business senza owner, o trasferire ownership
- `POST /v1/admin/businesses/{id}/resend-invite` → reinvia email benvenuto admin
- UseCase `ResendAdminInvite` genera nuovo token reset (24h) e invia email
- Template email: `businessAdminWelcome` con link reset password
- BusinessRepository: `findByIdWithAdmin()` e `findAllWithSearch()` includono admin_email
- **GET /v1/admin/businesses** ritorna `admin_email` per ogni business (fix 01/01/2026)

Email Benvenuto Admin (01/01/2026):
- Template `businessAdminWelcome` temporaneamente senza URL prenotazioni
- URL prenotazioni commentato in HTML, rimosso da versione text
- Da riattivare quando frontend booking pronto per il business
- File: `src/Infrastructure/Notifications/EmailTemplateRenderer.php`

Cambio Password e Verifica Token (01/01/2026):
- `GET /v1/auth/verify-reset-token/{token}` → verifica validità token PRIMA di mostrare form
- UseCase `VerifyResetToken` controlla token non usato e non scaduto
- Errori: `invalid_reset_token` (400) o `reset_token_expired` (400)
- `POST /v1/me/change-password` → cambio password utente autenticato
- Payload: `{"current_password": "...", "new_password": "..."}`
- Validazione: password attuale corretta, nuova password rispetta policy (8+ char, maiuscole, minuscole, numeri)
- Errore password errata: `invalid_credentials` (401)

Gestionale UI/UX (01/01/2026):
- **User Menu**: Icona profilo (index 4) nella navigation apre popup menu
- Menu contiene: header nome/email, Cambia password, Cambia Business (superadmin), Esci
- Superadmin: stesso menu sia in `/businesses` che dopo selezione business
- **Login error persistence**: Errore gestito in stato locale widget, non dal provider globale
- **Router rebuild**: Provider derivato `_routerAuthStateProvider` evita rebuild su cambio errorMessage

Logout e Session Expired (01/01/2026):
- `logout(silent: true)` → NON fa chiamata API (per sessione già scaduta)
- `SessionExpiredListener` usa `silent: true` per evitare loop infinito
- Flow: sessione scaduta → logout silenzioso → redirect a login

Categorie Servizi (01/01/2026):
- **NO dati hardcoded** in `ServiceCategoriesNotifier`
- Categorie caricate dall'API insieme ai servizi (`GET /v1/services`)
- `ServicesApi.fetchServicesWithCategories()` estrae categorie dalla risposta
- `ServicesNotifier` popola `serviceCategoriesProvider` con dati API

Services e Categories CRUD (02/01/2026):
- **Endpoint Services:**
  - `POST /v1/locations/{location_id}/services` → crea servizio (auth required)
  - `PUT /v1/services/{id}` → aggiorna servizio (auth required, `location_id` nel body)
  - `DELETE /v1/services/{id}` → soft delete servizio (auth required)
- **Endpoint Categories:**
  - `GET /v1/businesses/{business_id}/categories` → lista categorie
  - `POST /v1/businesses/{business_id}/categories` → crea categoria
  - `PUT /v1/categories/{id}` → aggiorna categoria
  - `DELETE /v1/categories/{id}` → elimina categoria (servizi diventano senza categoria)
- **File PHP:**
  - `src/Infrastructure/Repositories/ServiceRepository.php` → CRUD methods
  - `src/Http/Controllers/ServicesController.php` → endpoint handlers
  - `src/Http/Kernel.php` → route registration
- **File Flutter (agenda_backend):**
  - `lib/core/network/api_client.dart` → metodi HTTP CRUD
  - `lib/features/services/data/services_api.dart` → metodi API
  - `lib/features/services/providers/services_provider.dart` → `*Api` methods
  - `lib/features/services/providers/service_categories_provider.dart` → `*Api` methods
- **Metodi deprecati:** `add()`, `updateService()`, `delete()`, `duplicate()` locali
- **Usare:** `createServiceApi()`, `updateServiceApi()`, `deleteServiceApi()`, `duplicateServiceApi()`

---

## 🗄️ API Gestionale - Entità Persistite (01/01/2026)

### Staff Services (Servizi abilitati per Staff)
Relazione N:M tra staff e servizi che può erogare.

**Gestione tramite endpoint Staff esistenti:**
- `GET /v1/businesses/{business_id}/staff` - ritorna `service_ids` per ogni staff
- `POST /v1/businesses/{business_id}/staff` - accetta `service_ids` nel body
- `PUT /v1/staff/{id}` - accetta `service_ids` nel body

**Tabella:** `staff_services`
- `staff_id`, `service_id` (chiave primaria composta)

**File PHP:**
- `src/Infrastructure/Repositories/StaffRepository.php` → `getServiceIds()`, `setServices()`
- `src/Http/Controllers/StaffController.php` → gestione `service_ids` in store/update

**File Flutter:**
- `lib/core/models/staff.dart` → campo `serviceIds`
- `lib/features/services/providers/services_provider.dart` → `eligibleServicesForStaffProvider` legge da Staff
- `lib/features/staff/presentation/dialogs/staff_dialog.dart` → salvataggio via API

### Staff Availability Exceptions
Eccezioni ai turni base dello staff (ferie, malattia, straordinari).

**Endpoint:**
- `GET /v1/staff/{id}/availability-exceptions` - lista eccezioni per staff
- `POST /v1/staff/{id}/availability-exceptions` - crea eccezione
- `PUT /v1/staff/availability-exceptions/{id}` - modifica eccezione
- `DELETE /v1/staff/availability-exceptions/{id}` - elimina eccezione

**Tabella:** `staff_availability_exceptions`
- `id`, `staff_id`, `date`, `start_time`, `end_time`, `is_available`, `note`

**File PHP:**
- `src/Infrastructure/Repositories/StaffAvailabilityExceptionRepository.php`
- `src/Http/Controllers/StaffAvailabilityExceptionController.php`

### Resources (Risorse)
Risorse fisiche assegnabili ai servizi (es. cabine, lettini).

**Endpoint:**
- `GET /v1/locations/{id}/resources` - lista risorse per sede
- `POST /v1/locations/{id}/resources` - crea risorsa
- `PUT /v1/resources/{id}` - modifica risorsa
- `DELETE /v1/resources/{id}` - soft delete risorsa

**Tabelle:**
- `resources` - id, location_id, name, description, is_active, deleted_at
- `service_variant_resource_requirements` - variante_servizio ↔ risorsa (M:N)

**File PHP:**
- `src/Infrastructure/Repositories/ResourceRepository.php`
- `src/Http/Controllers/ResourcesController.php`

### Time Blocks (Blocchi Non Disponibilità)
Periodi di non disponibilità per uno o più staff (riunioni, pause, ferie).

**Endpoint:**
- `GET /v1/locations/{id}/time-blocks` - lista blocchi per sede (con filtro date)
- `POST /v1/locations/{id}/time-blocks` - crea blocco
- `PUT /v1/time-blocks/{id}` - modifica blocco
- `DELETE /v1/time-blocks/{id}` - elimina blocco

**Tabelle:**
- `time_blocks` - id, business_id, location_id, start_time, end_time, reason, is_all_day
- `time_block_staff` - blocco ↔ staff (M:N)

**File PHP:**
- `src/Infrastructure/Repositories/TimeBlockRepository.php`
- `src/Http/Controllers/TimeBlocksController.php`

### Location Closures (Chiusure Sedi) (03/02/2026)
Periodi di chiusura per una o più sedi (festività, ferie, manutenzione).

**Relazione N:M:** Una chiusura può applicarsi a più location tramite tabella pivot.

**Endpoint:**
- `GET /v1/businesses/{business_id}/closures` - lista chiusure per business
- `POST /v1/businesses/{business_id}/closures` - crea chiusura
- `PUT /v1/closures/{id}` - modifica chiusura
- `DELETE /v1/closures/{id}` - elimina chiusura

**Tabelle:**
- `closures` - id, business_id, start_date, end_date, reason, created_at, updated_at
- `closure_locations` - closure_id, location_id (tabella pivot N:M)

**File PHP:**
- `src/Infrastructure/Repositories/LocationClosureRepository.php`
- `src/Http/Controllers/LocationClosuresController.php`

**Metodi Repository:**
- `findByBusinessId(int $businessId)` - tutte le chiusure del business
- `findByLocationId(int $locationId)` - chiusure per una location specifica
- `isDateClosed(int $locationId, string $date)` - verifica se una data è chiusa
- `create(array $data)` - crea chiusura con locationIds
- `update(int $id, array $data)` - aggiorna chiusura e locationIds
- `delete(int $id)` - elimina chiusura (cascade su pivot)

**Integrazione ComputeAvailability:**
- `ComputeAvailability::execute()` verifica chiusure all'inizio (linee 116-120)
- Se `isDateClosed()` ritorna true, restituisce array vuoto (nessuno slot disponibile)

---

## 🔄 Refresh e Polling Dati (01/01/2026)

### Refresh all'entrata nelle sezioni
Ogni sezione del gestionale ricarica i dati dal DB quando l'utente vi accede.

| Sezione | Provider ricaricati |
|---------|--------------------|
| Agenda | staff, locations, servizi, clienti |
| Clienti | clienti |
| Team | staff, locations, servizi |
| Servizi | servizi, staff |

### Polling automatico in Agenda
Gli appuntamenti vengono ricaricati automaticamente:
- **Debug**: ogni 10 secondi
- **Produzione**: ogni 5 minuti

Questo permette di vedere nuove prenotazioni fatte online o da altri dispositivi.

### Filtro Location Attive
Il provider `LocationsNotifier` filtra automaticamente le location non attive (`is_active = 0`).
Questo impatta filtri agenda, sezione team e dialog staff.

---

⚠️ REGOLA CRITICA DATABASE:
- **MAI** inserire, modificare o eliminare dati nel database senza richiesta esplicita dell'utente
- Le operazioni di seed/migration vanno eseguite solo se l'utente lo richiede
- In caso di dubbio, chiedere conferma prima di modificare dati in produzione

⚠️ REGOLA DEPLOY PRODUZIONE:
- **MAI** eseguire deploy in PRODUZIONE (`api.romeolab.it`) senza richiesta esplicita dell'utente
- Usare i comandi rsync documentati in DEPLOY.md sezione 12

⚠️ REGOLA CRITICA DEPLOY:
- **MAI** deployare l'intero progetto con un singolo rsync
- Deployare SOLO: `public_html/`, `src/`, `vendor/`, `bin/` (se necessario)
- **MAI** deployare: `docs/`, `tests/`, `scripts/`, `migrations/`, `lib/`, `.git/`, `*.md`, `phpunit.xml`
- Usare sempre i comandi specifici documentati in DEPLOY.md sezione 12

---

## 💰 Prezzo "A partire da" (01/01/2026)

### Schema Database
`service_variants.is_price_starting_from` (TINYINT, default 0)

### Backend PHP
Tutti gli endpoint che ritornano service_variants includono il campo:
- `ServiceRepository::findById()` → include `is_price_starting_from AS is_price_from`
- `ServiceRepository::findByLocationId()` → include `is_price_starting_from AS is_price_from`
- `ServiceRepository::findByIds()` → include `is_price_starting_from AS is_price_from`
- `ServicesController::index()` → ritorna `is_price_starting_from` nella response JSON

### Gestionale Flutter
- `Service.isPriceStartingFrom` (bool) → campo flat dal service
- `ServiceVariant.isPriceStartingFrom` (bool) → campo dal variant
- `ServiceItem` widget usa `service.isPriceStartingFrom` per visualizzare "a partire da €X"
- Chiave localizzazione: `priceStartingFromPrefix` = "a partire da"

### Frontend Prenotazioni
Se necessario, seguire stessa logica del gestionale.

---

## 🔧 Repository Method Names (01/01/2026)

### IMPORTANTE
Il metodo per ottenere PDO connection è:
```php
$this->db->getPdo()  // ✅ CORRETTO
$this->db->pdo()     // ❌ ERRORE - metodo non esistente
```

### Fix Applicati
- `TimeBlockRepository` → tutti i `pdo()` sostituiti con `getPdo()`

### Verifica
Prima di usare un repository, verificare che usi `getPdo()` e non `pdo()`.

---

## 🔐 Sicurezza API - Autorizzazione Business (02/01/2026)

### Pattern Autorizzazione
Tutti i controller che gestiscono dati business-specific implementano il metodo `hasBusinessAccess()`:

```php
private function hasBusinessAccess(Request $request, int $businessId): bool
{
    $userId = $request->getAttribute('user_id');
    if ($userId === null) return false;
    
    // Superadmin ha accesso a tutti i business
    if ($this->userRepo->isSuperadmin($userId)) return true;
    
    // Utente normale: verifica entry in business_users
    return $this->businessUserRepo->hasAccess($userId, $businessId, false);
}
```

### Controller Protetti

| Controller | Endpoint Protetti | Note |
|------------|-------------------|------|
| **ClientsController** | GET/POST/PUT/DELETE `/v1/clients` | Verifica business_id |
| **ServicesController** | POST/PUT/DELETE services e categories | Verifica ownership |
| **BusinessController** | GET `/v1/businesses`, GET `/v1/businesses/{id}` | Solo business accessibili |
| **LocationsController** | GET `/v1/businesses/{id}/locations`, GET `/v1/locations/{id}` | Verifica accesso |
| **AppointmentsController** | GET/PATCH/POST cancel | Owner booking O operatore business |
| **BookingsController** | GET index/show | Verifica business_id |

### Security Best Practice
- `show/update/delete` ritornano **404** (non 403) per non rivelare esistenza risorse
- Operatori con accesso al business possono gestire TUTTI gli appuntamenti
- Utenti normali possono gestire solo i PROPRI booking

### Controller già protetti (pre-esistenti)
- `StaffController` → verifica `hasAccess()`
- `TimeBlocksController` → verifica `hasAccess()`
- `ResourcesController` → verifica `hasAccess()`
- `BusinessUsersController` → verifica `checkManageAccess()`
- `AdminBusinessesController` → verifica `is_superadmin`

### Dipendenze Controller
Tutti i controller protetti richiedono:
- `BusinessUserRepository` - per verificare accesso
- `UserRepository` - per verificare superadmin

Aggiornare `Kernel.php` quando si aggiungono dipendenze ai controller.

### Nuovi Metodi Repository (02/01/2026)
- `BusinessRepository::findByUserId(int $userId)` - business accessibili all'utente
- `ServiceRepository::findServiceById(int $serviceId)` - trova servizio senza location

---

## 📊 Import Dati da Fresha (02/01/2026)

### Istruzioni Migrazione
File in `migrations/fromfresha/`:
- `migra_servizi.md` - import servizi e categorie
- `migra_staff.md` - import staff
- `import_clients.sql` - import clienti (216 record)

### Regola Critica
**NON creare associazioni tra tabelle** (es. `staff_services`) durante import.
Le associazioni devono essere configurate manualmente dall'operatore nel gestionale.

### Match Automatico Clienti
Quando un utente prenota online e nel DB esiste già un client con stessa email/telefono:
- `ClientRepository::findUnlinkedByEmailOrPhone()` cerca client senza `user_id`
- `ClientRepository::linkUserToClient()` associa `user_id` al client esistente
- Priorità: email > telefono

---

## 🔐 Separazione Autenticazione Operator/Customer (02/01/2026)

### Architettura a Due Sistemi Auth

Il sistema usa **due tabelle separate** per l'autenticazione:

| Sistema | Tabella | Endpoint Base | JWT Role | Scopo |
|---------|---------|---------------|----------|-------|
| **Operator** | `users` | `/v1/auth/` | `role: operator` | Gestionale (agenda_backend) |
| **Customer** | `clients` | `/v1/customer/{business_id}/auth/` | `role: customer` | Prenotazioni online (agenda_frontend) |

### ⚠️ REGOLA CRITICA
- I token **NON sono intercambiabili**
- Un token `role: customer` **NON può** accedere a endpoint gestionale (`/v1/me`, `/v1/businesses`, ecc.)
- Un token `role: operator` **NON può** accedere a endpoint customer (`/v1/customer/bookings`)

### Schema Database Customer Auth

```sql
-- Nuovi campi su clients
ALTER TABLE clients ADD password_hash VARCHAR(255) NULL;
ALTER TABLE clients ADD email_verified_at TIMESTAMP NULL;

-- Sessioni customer (refresh token)
CREATE TABLE client_sessions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    client_id INT NOT NULL,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
);

-- Reset password customer
CREATE TABLE password_reset_token_clients (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    client_id INT NOT NULL,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
);
```

### Endpoint Customer Auth

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/v1/customer/{business_id}/auth/register` | Registrazione nuovo cliente |
| POST | `/v1/customer/{business_id}/auth/login` | Login cliente |
| POST | `/v1/customer/{business_id}/auth/refresh` | Rinnovo access token |
| POST | `/v1/customer/{business_id}/auth/logout` | Logout (revoca refresh token) |
| POST | `/v1/customer/{business_id}/auth/forgot-password` | Richiede email reset password |
| POST | `/v1/customer/auth/reset-password` | Reset password con token |
| GET | `/v1/customer/me` | Profilo cliente autenticato |
| POST | `/v1/customer/{business_id}/bookings` | Crea prenotazione (customer) |
| GET | `/v1/customer/bookings` | Lista prenotazioni del cliente |

### JWT Token Structure

**Operator Token:**
```json
{
  "sub": 6,              // user_id
  "role": "operator",
  "exp": 1735830000,
  "iat": 1735829100
}
```

**Customer Token:**
```json
{
  "sub": 42,             // client_id
  "role": "customer",
  "business_id": 1,
  "exp": 1735830000,
  "iat": 1735829100
}
```

### File PHP Creati

| File | Descrizione |
|------|-------------|
| `src/Infrastructure/Repositories/ClientAuthRepository.php` | CRUD client auth, sessioni, password reset |
| `src/Http/Controllers/CustomerAuthController.php` | Endpoint auth customer |
| `src/Http/Middleware/CustomerAuthMiddleware.php` | Valida JWT con `role: customer` |
| `src/UseCases/CustomerAuth/LoginCustomer.php` | UseCase login |
| `src/UseCases/CustomerAuth/RegisterCustomer.php` | UseCase registrazione |
| `src/UseCases/CustomerAuth/RefreshCustomerToken.php` | UseCase refresh token |
| `src/UseCases/CustomerAuth/LogoutCustomer.php` | UseCase logout |
| `src/UseCases/CustomerAuth/GetCustomerMe.php` | UseCase profilo |
| `src/UseCases/CustomerAuth/UpdateCustomerProfile.php` | UseCase aggiorna profilo cliente |
| `src/UseCases/CustomerAuth/ChangeCustomerPassword.php` | UseCase cambio password cliente |

### File PHP Modificati

| File | Modifiche |
|------|-----------|
| `src/Infrastructure/Auth/JwtService.php` | Aggiunto `generateCustomerAccessToken()` con `role: customer` |
| `src/Http/Middleware/AuthMiddleware.php` | Verifica `role: operator` (backwards compatible) |
| `src/Http/Kernel.php` | Route customer auth, middleware `customer_auth` |
| `src/Http/Controllers/BookingsController.php` | `storeCustomer()`, `myCustomerBookings()` |
| `src/UseCases/Booking/CreateBooking.php` | `executeForCustomer()` per booking da customer |
| `src/Domain/Booking/BookingException.php` | Aggiunto `invalidClient()` error |
| `src/Infrastructure/Repositories/BookingRepository.php` | Rimosso metodo duplicato `findByClientId()` |

### Migrazione Database

**File:** `migrations/0020_separate_customer_auth.sql`

**⚠️ PRIMA di eseguire la migrazione:**
1. Fare backup del database
2. Verificare che non ci siano utenti "puri clienti" da migrare (se non ce ne sono, la query INSERT non farà nulla)

**Eseguire migrazione (se necessario):**
```bash
# Copia file su server
rsync -avz migrations/0020_separate_customer_auth.sql siteground:www/api.romeolab.it/migrations/

# Esegui migrazione
ssh siteground "cd www/api.romeolab.it && mysql -u \$DB_USERNAME -p\$DB_PASSWORD \$DB_DATABASE < migrations/0020_separate_customer_auth.sql"
```

### Middleware Registration (Kernel.php)

```php
// Middleware customer auth
$customerAuthMiddleware = new CustomerAuthMiddleware($jwtService);

// Route customer auth (pubbliche)
$router->post('/v1/customer/{business_id}/auth/register', ...);
$router->post('/v1/customer/{business_id}/auth/login', ...);
$router->post('/v1/customer/{business_id}/auth/refresh', ...);
$router->post('/v1/customer/{business_id}/auth/logout', ...);
$router->post('/v1/customer/{business_id}/auth/forgot-password', ...);
$router->post('/v1/customer/auth/reset-password', ...);

// Route customer protette
$router->group(['middleware' => [$customerAuthMiddleware]], function ($router) {
    $router->get('/v1/customer/me', ...);
    $router->post('/v1/customer/{business_id}/bookings', ...);
    $router->get('/v1/customer/bookings', ...);
});
```

### Migrazione Dati (ATTENZIONE)

La migrazione `0020_separate_customer_auth.sql`:
- Copia dati da `users` a `clients` solo per utenti **NON** in `business_users`
- Gli operatori/admin rimangono **solo** in `users`
- I clienti puri vengono copiati in `clients` con `password_hash`

```sql
-- Solo utenti NON operatori/admin
INSERT INTO clients (business_id, email, password_hash, first_name, last_name, phone, ...)
SELECT bu2.business_id, u.email, u.password_hash, u.first_name, u.last_name, u.phone, ...
FROM users u
JOIN bookings b ON b.user_id = u.id
JOIN appointments a ON a.booking_id = b.id
JOIN staff s ON s.id = a.staff_id
JOIN locations l ON l.id = s.location_id
JOIN business_users bu2 ON bu2.business_id = l.business_id AND bu2.is_owner = 1
WHERE u.password_hash IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM business_users bu WHERE bu.user_id = u.id)
GROUP BY u.id, bu2.business_id;
```

### Compatibilità Backward

L'`AuthMiddleware` per operatori è **backward compatible**:
- Token senza campo `role` → accettato (legacy)
- Token con `role: operator` → accettato
- Token con `role: customer` → rifiutato (401)

### ✅ Integrazione Flutter Frontend (03/01/2026)

L'integrazione customer auth è **COMPLETATA** in `agenda_frontend`:

| Componente | Stato | Note |
|------------|-------|------|
| `api_config.dart` | ✅ | Endpoint customer auth |
| `api_client.dart` | ✅ | Metodi `customerLogin()`, `customerRegister()`, `customerLogout()`, `getCustomerMe()` |
| `token_storage_*.dart` | ✅ | Salvataggio `businessId` per refresh token |
| `auth_repository.dart` | ✅ | Usa endpoint customer con `businessId` |
| `auth_provider.dart` | ✅ | `login()`, `logout()`, `register()` richiedono `businessId` |
| `login_screen.dart` | ✅ | Passa `businessId` da `currentBusinessIdProvider` |
| `register_screen.dart` | ✅ | Passa `businessId` da `currentBusinessIdProvider` |

**Flow completo:**
```
1. Cliente accede a: prenota.romeolab.it/romeolab/login
2. Router estrae slug "romeolab" → routeSlugProvider
3. currentBusinessProvider carica business da API → id: 1
4. Login chiama: POST /v1/customer/1/auth/login
5. Token JWT con role: "customer" salvato in memoria
6. businessId salvato in localStorage/secureStorage per refresh
```

---

## 📅 ComputeAvailability e Slot Opportunistici (12/01/2026)

### Parametro `keepStaffInfo`

`ComputeAvailability::execute()` accetta un parametro opzionale `keepStaffInfo`:
- **false (default)**: Ritorna slot aggregati con `staff_id: null` per uso pubblico
- **true**: Ritorna slot con `staff_id` reale, per uso interno (es. `CreateBooking`)

### Slot Opportunistici

Gli slot opportunistici sono orari non-standard che diventano disponibili grazie a prenotazioni esistenti:

**Forward (slot che iniziano alla fine di booking esistenti):**
```
Planning: 09:00-12:00 (slot ogni 30min)
Booking esistente: 09:15-09:45
→ Slot opportunistico: 09:45 (non standard, ma disponibile)
```

**Backward (slot che finiscono all'inizio di booking esistenti):**
```
Planning: 09:00-12:00 (slot ogni 30min)
Servizio richiesto: 30min
Booking esistente: 10:15-10:45
→ Slot opportunistico: 09:45 (finisce esattamente quando inizia il booking)
```

### Selezione Staff per "Qualsiasi Operatore"

Quando `staff_id` è null (qualsiasi operatore), `CreateBooking` usa `ComputeAvailability` con `keepStaffInfo=true` per trovare uno staff realmente disponibile:

```php
// CreateBooking.php
if ($staffId === null) {
    $availability = $this->computeAvailability->execute(
        locationId: $locationId,
        serviceIds: $serviceIds,
        date: $startTime->format('Y-m-d'),
        staffId: null,
        keepStaffInfo: true  // Mantiene info staff per assegnazione
    );
    // Trova slot corrispondente e usa il suo staff_id
}
```

### File Modificati

| File | Modifica |
|------|----------|
| `ComputeAvailability.php` | Parametro `keepStaffInfo`, slot opportunistici forward e backward |
| `CreateBooking.php` | Usa `ComputeAvailability` per trovare staff disponibile |
| `QueueBookingReminder.php` | Supporto `client_id`, costruzione `manage_url` |
| `queue-reminders.php` | Riscritto per usare `QueueBookingReminder::queueUpcomingReminders()` |

---

## � Prenotazioni Ricorrenti (23/01/2026)

### Schema Database

**Tabella `booking_recurrence_rules`:**
```sql
CREATE TABLE booking_recurrence_rules (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    frequency ENUM('daily', 'weekly', 'biweekly', 'monthly') NOT NULL,
    interval_value INT UNSIGNED NOT NULL DEFAULT 1,
    day_of_week TINYINT UNSIGNED NULL,      -- 0=domenica, 6=sabato
    day_of_month TINYINT UNSIGNED NULL,     -- 1-31
    start_date DATE NOT NULL,
    end_date DATE NULL,                      -- NULL = infinito
    occurrences INT UNSIGNED NULL,           -- NULL = infinito
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES businesses(id),
    FOREIGN KEY (location_id) REFERENCES locations(id)
);
```

**Colonne aggiunte a `bookings`:**
```sql
ALTER TABLE bookings ADD recurrence_rule_id INT UNSIGNED NULL;
ALTER TABLE bookings ADD recurrence_index INT UNSIGNED NULL;
ALTER TABLE bookings ADD is_recurrence_parent TINYINT(1) DEFAULT 0;
ALTER TABLE bookings ADD has_conflict TINYINT(1) DEFAULT 0;
```

### Endpoint API (Solo Gestionale)

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/v1/locations/{location_id}/bookings/recurring/preview` | Anteprima date con conflitti |
| POST | `/v1/locations/{location_id}/bookings/recurring` | Crea serie ricorrente |
| GET | `/v1/bookings/recurring/{recurrence_rule_id}` | Ottieni serie completa |
| PATCH | `/v1/bookings/recurring/{recurrence_rule_id}` | Modifica serie |
| DELETE | `/v1/bookings/recurring/{recurrence_rule_id}` | Cancella serie |

### Preview Ricorrenza (24/01/2026)

Prima di creare la serie, il client può richiedere un'anteprima delle date con indicazione dei conflitti:

```json
POST /v1/locations/{location_id}/bookings/recurring/preview
{
  "service_variant_id": 1,
  "staff_id": 3,
  "start_time": "10:00",
  "frequency": "weekly",
  "interval": 1,
  "day_of_week": 1,
  "start_date": "2026-02-01",
  "end_date": "2026-06-30"
}
```

**Response:**
```json
{
  "dates": [
    {"date": "2026-02-01", "has_conflict": false},
    {"date": "2026-02-08", "has_conflict": true},
    ...
  ],
  "total_count": 22,
  "conflict_count": 3
}
```

**File PHP:**
- `src/UseCases/Booking/PreviewRecurringBooking.php` - genera date e verifica conflitti
- `src/Http/Controllers/BookingsController.php` - metodo `previewRecurring()`

### Payload Creazione Serie Ricorrente

```json
POST /v1/locations/{location_id}/bookings/recurring
{
  "client_id": 42,
  "service_variant_id": 1,
  "staff_id": 3,
  "start_time": "10:00",
  "notes": "Appuntamento settimanale",
  "frequency": "weekly",
  "interval": 1,
  "day_of_week": 1,
  "start_date": "2026-02-01",
  "end_date": "2026-06-30",
  "occurrences": null,
  "skip_conflicts": true
}
```

### Query Params per Modifica/Cancellazione

| Parametro | Valori | Descrizione |
|-----------|--------|-------------|
| `scope` | `single`, `this_and_future`, `all` | Quali booking modificare |
| `from_index` | int | Indice di partenza (per `this_and_future`) |

**Esempi:**
```
DELETE /v1/bookings/recurring/5?scope=single&from_index=3
DELETE /v1/bookings/recurring/5?scope=this_and_future&from_index=3
DELETE /v1/bookings/recurring/5?scope=all
```

### Campi Ritornati negli Appointments

Tutti gli endpoint che ritornano appointments ora includono:

```json
{
  "id": 123,
  "booking_id": 456,
  "recurrence_rule_id": 5,
  "recurrence_index": 3,
  "recurrence_total": 12
}
```

- `recurrence_rule_id`: ID della regola di ricorrenza (null se non ricorrente)
- `recurrence_index`: Posizione nella serie (1-based)
- `recurrence_total`: Numero totale di booking attivi nella serie

### File PHP Coinvolti

| File | Responsabilità |
|------|----------------|
| `src/Domain/Booking/RecurrenceRule.php` | Modello dominio |
| `src/Infrastructure/Repositories/RecurrenceRuleRepository.php` | CRUD regole |
| `src/Infrastructure/Repositories/BookingRepository.php` | Query con campi recurrence |
| `src/UseCases/Booking/PreviewRecurringBooking.php` | Anteprima date con conflitti |
| `src/UseCases/Booking/CreateRecurringBooking.php` | Creazione serie |
| `src/UseCases/Booking/ModifyRecurringSeries.php` | Modifica/cancella serie |
| `src/Http/Controllers/BookingsController.php` | Endpoint recurring |
| `src/Http/Controllers/AppointmentsController.php` | formatAppointment con recurrence |

### Gestione Conflitti

- `skip_conflicts: true` → crea booking senza conflitti, salta date con conflitto
- `skip_conflicts: false` → fallisce se almeno una data ha conflitto
- Booking con conflitto: `has_conflict = 1` (visibile in UI)

---

## �📋 Booking Audit System (18/01/2026)

### Tabelle Audit

| Tabella | Scopo |
|---------|-------|
| `booking_replacements` | Relazione tra booking originale e sostitutivo |
| `booking_events` | Audit trail immutabile per tutti gli eventi booking |

### Event Types Registrati

| Event Type | Trigger | Actor Type | Use Case/Controller |
|------------|---------|------------|---------------------|
| `booking_created` | Creazione nuova prenotazione | `staff` o `customer` | `CreateBooking.php` |
| `booking_replaced` | Prenotazione originale sostituita | `staff` o `customer` | `ReplaceBooking.php` |
| `booking_created_by_replace` | Nuova prenotazione da replace | `staff` o `customer` | `ReplaceBooking.php` |
| `appointment_updated` | Modifica singolo appuntamento (orario/staff/prezzo) | `staff` | `AppointmentsController.php` |
| `booking_item_added` | Aggiunta servizio a booking esistente | `staff` | `AppointmentsController.php` |
| `booking_item_deleted` | Rimozione servizio da booking | `staff` | `AppointmentsController.php` |
| `booking_cancelled` | Cancellazione completa booking | `staff` o `customer` | `DeleteBooking.php`, `AppointmentsController.php` |
| `booking_updated` | Modifica cliente/note/status booking | `staff` o `customer` | `UpdateBooking.php` |

### Payload Evento `booking_created`

```json
{
  "booking_id": 123,
  "status": "confirmed",
  "location_id": 1,
  "client_id": 42,
  "notes": "Prima visita",
  "source": "online",
  "items": [
    {
      "service_id": 1,
      "staff_id": 3,
      "start_time": "2026-01-20 10:00:00",
      "end_time": "2026-01-20 10:30:00",
      "price": 25.00
    }
  ],
  "total_price": 25.00,
  "first_start_time": "2026-01-20 10:00:00",
  "last_end_time": "2026-01-20 10:30:00"
}
```

### Payload Evento `appointment_updated`

```json
{
  "appointment_id": 456,
  "before": {
    "id": 456,
    "staff_id": 3,
    "start_time": "2026-01-20 10:00:00",
    "end_time": "2026-01-20 10:30:00",
    "price": 25.00
  },
  "after": {
    "id": 456,
    "staff_id": 4,
    "start_time": "2026-01-20 11:00:00",
    "end_time": "2026-01-20 11:30:00",
    "price": 25.00
  },
  "changed_fields": ["staff_id", "start_time", "end_time"]
}
```

### Payload Evento `booking_updated`

```json
{
  "booking_id": 123,
  "before": {
    "id": 123,
    "client_id": 42,
    "customer_name": "Mario Rossi",
    "status": "confirmed",
    "notes": null
  },
  "after": {
    "id": 123,
    "client_id": 43,
    "customer_name": "Luigi Verdi",
    "status": "confirmed",
    "notes": "Cambio cliente"
  },
  "changed_fields": ["client_id", "customer_name", "notes"]
}
```

### Payload Evento `booking_cancelled`

```json
{
  "booking_id": 123,
  "business_id": 1,
  "location_id": 1,
  "client_id": 42,
  "status": "confirmed",
  "notes": "Prima visita",
  "source": "online",
  "items": [
    {
      "id": 456,
      "service_id": 1,
      "staff_id": 3,
      "start_time": "2026-01-20 10:00:00",
      "end_time": "2026-01-20 10:30:00",
      "price": 25.00
    }
  ],
  "total_price": 25.00,
  "first_start_time": "2026-01-20 10:00:00",
  "last_end_time": "2026-01-20 10:30:00"
}
```

### File PHP Coinvolti

| File | Responsabilità |
|------|----------------|
| `BookingAuditRepository.php` | CRUD per `booking_replacements` e `booking_events` |
| `CreateBooking.php` | Registra `booking_created` dopo ogni creazione |
| `ReplaceBooking.php` | Registra `booking_replaced` e `booking_created_by_replace` |
| `UpdateBooking.php` | Registra `booking_updated` per modifiche cliente/note/status |
| `DeleteBooking.php` | Registra `booking_cancelled` prima della cancellazione |
| `AppointmentsController.php` | Registra `appointment_updated`, `booking_item_added`, `booking_item_deleted`, `booking_cancelled` |

### Regole Audit

- Gli eventi sono **immutabili**: nessun UPDATE/DELETE applicativo
- `correlation_id` (UUID) collega eventi correlati (es. replace genera 2 eventi con stesso correlation_id)
- Gli errori di audit **non bloccano** l'operazione principale (logged e ignorati)
- Actor types: `customer`, `staff`, `system`

---

## 📊 Servizi Popolari per Staff (26/01/2026)

### Scopo
Analizza i servizi più prenotati negli ultimi 90 giorni e memorizza i top 5 per ogni staff.
Il gestionale mostra questi servizi in una sezione dedicata nel picker servizi, specifici per lo staff selezionato.

### Numero di Servizi Popolari Mostrati
Il numero è **proporzionale ai servizi abilitati** per lo staff:
- 1 servizio popolare ogni 7 servizi abilitati
- Massimo 5 servizi popolari
- Se meno di 7 servizi abilitati → 0 popolari (sezione nascosta)

| Servizi abilitati | Popolari mostrati |
|-------------------|-------------------|
| 0-6 | 0 |
| 7-13 | 1 |
| 14-20 | 2 |
| 21-27 | 3 |
| 28-34 | 4 |
| 35+ | 5 |

### Tabella Database
```sql
CREATE TABLE popular_services (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    staff_id INT UNSIGNED NOT NULL,
    service_id INT UNSIGNED NOT NULL,
    `rank` TINYINT UNSIGNED NOT NULL,  -- 1-5
    booking_count INT UNSIGNED NOT NULL,
    computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (staff_id, `rank`),
    UNIQUE KEY (staff_id, service_id),
    FOREIGN KEY (staff_id) REFERENCES staff(id) ON DELETE CASCADE
);
```

### Endpoint API
`GET /v1/staff/{staff_id}/services/popular`

**Response:**
```json
{
  "popular_services": [
    {
      "rank": 1,
      "booking_count": 45,
      "service_id": 5,
      "service_name": "Taglio uomo",
      "category_id": 2,
      "category_name": "Capelli",
      "price": 18.00,
      "duration_minutes": 30,
      "color": "#4CAF50"
    }
  ],
  "enabled_services_count": 32,
  "show_popular_section": true
}
```

### Cron Worker
- **File:** `bin/compute-popular-services.php`
- **Schedule:** `0 4 * * 0` (domenica alle 4:00)
- **Opzioni:** `--verbose`, `--staff=ID`, `--help`

**Configurazione SiteGround:**
```
0 4 * * 0 cd /home/u1251-kkefwq4fumer/www/api.romeolab.it && php bin/compute-popular-services.php >> logs/popular-services.log 2>&1
```

### File PHP
| File | Responsabilità |
|------|----------------|
| `src/Infrastructure/Repositories/PopularServiceRepository.php` | CRUD, calcolo per staff, conteggio servizi abilitati |
| `src/Http/Controllers/ServicesController.php` | Metodo `popular()` con logica proporzionale |
| `bin/compute-popular-services.php` | Worker cron |
| `migrations/0031_popular_services.sql` | Schema iniziale (location) |
| `migrations/0032_popular_services_by_staff.sql` | Migrazione a staff |

---

## 🔄 Servizi Duplicati in Prenotazione (26/01/2026)

### Comportamento
Una prenotazione può contenere lo stesso servizio più volte (es. 2x "Taglio uomo").

### Metodi Aggiornati in ServiceRepository
- `findByIds()` - Restituisce servizi nell'ordine richiesto, inclusi duplicati
- `getTotalDuration()` - Calcola durata totale considerando duplicati
- `getTotalPrice()` - Calcola prezzo totale considerando duplicati
- `allBelongToBusiness()` - Verifica solo ID unici (duplicati permessi)

---

## ⏰ Smart Time Slots - Fasce Orarie Intelligenti (27/01/2026)

### Scopo
Permette di configurare come vengono mostrati gli orari disponibili ai clienti che prenotano online, ottimizzando la gestione del tempo evitando "buchi" troppo piccoli.

### Colonne Database (tabella `locations`)
```sql
slot_interval_minutes INT UNSIGNED DEFAULT 15  -- Intervallo tra slot mostrati
slot_display_mode ENUM('all', 'min_gap') DEFAULT 'all'  -- Modalità visualizzazione
min_gap_minutes INT UNSIGNED DEFAULT 30  -- Gap minimo accettabile
```

### Modalità Visualizzazione

| Modalità | Descrizione | Comportamento |
|----------|-------------|---------------|
| `all` | Massima disponibilità | Mostra tutti gli slot disponibili |
| `min_gap` | Riduci spazi vuoti | Nasconde slot che creerebbero gap < min_gap_minutes |

### Come Funziona `min_gap`
Quando `slot_display_mode = 'min_gap'`:
1. Per ogni slot disponibile, calcola la distanza dagli appuntamenti esistenti
2. Se la distanza è > 0 ma < `min_gap_minutes`, lo slot viene nascosto
3. Slot adiacenti (gap = 0) sono sempre mostrati

**Esempio:**
- `min_gap_minutes = 30`
- Appuntamento esistente: 10:00-10:45
- Slot 11:00 crea gap di 15 min → **nascosto**
- Slot 11:15 crea gap di 30 min → **mostrato**

### API

**GET `/v1/availability`** (endpoint pubblico per frontend booking)
- Ora applica automaticamente il filtro `min_gap` se configurato
- Parametro interno `isPublic=true` attiva il filtraggio

**PUT `/v1/locations/{id}`** (endpoint gestionale)
- Nuovi campi nel body:
  - `slot_interval_minutes` (5-60)
  - `slot_display_mode` ('all' | 'min_gap')
  - `min_gap_minutes` (0-120)

### File PHP Modificati

| File | Modifiche |
|------|-----------|
| `migrations/0033_location_slot_settings.sql` | ALTER TABLE locations per nuove colonne |
| `LocationRepository.php` | Query findById e update con nuovi campi |
| `ComputeAvailability.php` | Logica filtro `min_gap`, metodo `applyMinGapFilter()` |
| `BookingRepository.php` | Metodo `getOccupiedSlotsForLocation()` |
| `AvailabilityController.php` | Passa `isPublic=true` |
| `LocationsController.php` | Gestione nuovi campi in `update()` e `formatLocation()` |

### File Flutter Modificati (agenda_backend)

| File | Modifiche |
|------|-----------|
| `lib/core/models/location.dart` | Nuovi campi nel model |
| `lib/core/network/api_client.dart` | Nuovi parametri in `updateLocation()` |
| `lib/features/business/data/locations_repository.dart` | Passaggio nuovi parametri |
| `lib/features/agenda/providers/location_providers.dart` | Metodo `updateLocation()` con nuovi parametri |
| `lib/features/staff/presentation/dialogs/location_dialog.dart` | UI per configurazione smart slots |
| `lib/core/l10n/intl_it.arb`, `intl_en.arb` | Chiavi localizzazione |

### Localizzazioni Aggiunte
- `teamLocationSmartSlotSection` - "Fasce orarie intelligenti"
- `teamLocationSlotIntervalLabel` - "Intervallo tra gli orari"
- `teamLocationSlotDisplayModeLabel` - "Modalità visualizzazione"
- `teamLocationSlotDisplayModeAll` - "Massima disponibilità"
- `teamLocationSlotDisplayModeMinGap` - "Riduci spazi vuoti"
- `teamLocationMinGapLabel` - "Gap minimo accettabile"
- `teamLocationMinutes` - "{count} minuti"

---

## 📊 Work Hours Report API (02/02/2026)

### Endpoint
`GET /v1/reports/work-hours`

### Autenticazione
Richiede `auth` middleware. Accessibile a admin/owner del business.

### Parametri Query
| Parametro | Tipo | Required | Descrizione |
|-----------|------|----------|-------------|
| `business_id` | int | ✅ | ID del business |
| `start_date` | string | ✅ | Data inizio (Y-m-d) |
| `end_date` | string | ✅ | Data fine (Y-m-d) |
| `location_ids[]` | int[] | ❌ | Filtra per sedi |
| `staff_ids[]` | int[] | ❌ | Filtra per staff |

### Response
```json
{
  "summary": {
    "total_scheduled_minutes": 2400,
    "total_worked_minutes": 1800,
    "total_blocked_minutes": 120,
    "total_exception_off_minutes": 480,
    "total_available_minutes": 2280,
    "overall_utilization_percentage": 78.9
  },
  "by_staff": [
    {
      "staff_id": 1,
      "staff_name": "Mario Rossi",
      "staff_color": "#4CAF50",
      "scheduled_minutes": 800,
      "worked_minutes": 600,
      "blocked_minutes": 60,
      "exception_off_minutes": 0,
      "available_minutes": 740,
      "utilization_percentage": 81.1
    }
  ],
  "filters": {
    "start_date": "2026-02-01",
    "end_date": "2026-02-28",
    "location_ids": [],
    "staff_ids": []
  }
}
```

### Calcolo Metriche

| Metrica | Fonte | Descrizione | Label UI |
|---------|-------|-------------|----------|
| `scheduled_minutes` | `staff_planning_week_template` | Minuti pianificati da planning settimanale | Pianificate |
| `worked_minutes` | `booking_items` | Minuti da prenotazioni confirmed/completed | Prenotate |
| `blocked_minutes` | `time_blocks` | Minuti bloccati (riunioni, pause) | Blocchi |
| `exception_off_minutes` | `staff_availability_exceptions` | Minuti assenza (ferie, malattia) con type='unavailable' | Assenze |
| `available_minutes` | calculated | `scheduled_minutes - blocked_minutes` | Effettive |
| `utilization_percentage` | calculated | `worked_minutes / available_minutes × 100` | Occupazione |

### File PHP
- `src/Http/Controllers/ReportsController.php` → metodo `workHours()`
- `src/Http/Controllers/ReportsController.php` → metodo privato `buildWorkHoursReport()`

---


SOURCE OF TRUTH: ../../STAFF_PLANNING_MODEL.md

Agisci come senior backend engineer.

Obiettivo:
Integrare nel progetto agenda_core il modello di staff planning temporale già implementato in agenda_backend.

Vincoli:
- Segui ESATTAMENTE STAFF_PLANNING_MODEL.md.
- Non introdurre nuove regole.
- Non modificare il modello dati deciso.
- Non riscrivere logica di business già implementata nel backend.
- Esporre solo API e query necessarie.
- Non toccare agenda_backend né agenda_frontend.

Attività obbligatorie:
1) Esporre via API le entità staff_planning e staff_planning_week_template.
2) Esporre endpoint per:
   - lettura planning per staff
   - lettura planning valido per una data
   - lettura disponibilità staff per una data
3) Gestire valid_to = null come “mai”.
4) Rispettare intervalli temporali chiusi-chiusi.
5) Se più planning risultano validi per una data, restituire errore di consistenza.
6) Non aggiungere fallback automatici.

Output richiesto:
- Codice PHP/API aggiornato.
- Eventuali query SQL di lettura necessarie.
- Nessuna spiegazione testuale.
