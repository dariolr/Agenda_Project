# AGENTS.md — agenda_core (Agenda Engine / Core Backend Services)

Questo file è la fonte di verità per qualsiasi agent AI che lavori su agenda_core.
DEVE essere letto prima di scrivere codice.

Compatibilità obbligatoria:
- Agenda Frontend (Flutter – prenotazione online)
- Agenda Backend (Flutter – gestionale)

JSON snake_case.
I modelli e i campi già usati dai client NON devono essere rinominati.

Prenotazione pubblica, login obbligatorio solo per conferma.

Autenticazione:
- JWT access token breve (10–15 min)
- Refresh token lungo (30–90 gg) con rotazione
- Web: refresh in cookie httpOnly
- Mobile: refresh in secure storage

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

File .env:
- `.env` → configurazione REALE (non committato, in .gitignore)
- `.env.example` → TEMPLATE con placeholder (committato)
- I due file DEVONO avere le STESSE variabili, sempre allineati
- Quando si aggiunge una variabile a `.env.example`, aggiungerla anche a `.env`
- `.env.example` usa valori placeholder, `.env` usa valori reali

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

### Comandi Deploy CORRETTI

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
- [ ] Ho incrementato `?v=YYYYMMDD-N` in `web/index.html`?

---

Deploy Produzione (28/12/2025):
- API: https://api.romeolab.it
- Frontend: https://prenota.romeolab.it
- Gestionale: https://gestionale.romeolab.it
- Hosting: SiteGround condiviso
- CORS: `CORS_ALLOWED_ORIGINS=https://prenota.romeolab.it,https://gestionale.romeolab.it,http://localhost:8080`
- SSH: porta 18765, chiave ed25519

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

⚠️ VERSIONE CACHE BUSTING (01/01/2026):

**Prima di ogni deploy Flutter (frontend o backend)**, incrementare la versione in `web/index.html`:
```html
<script src="flutter_bootstrap.js?v=YYYYMMDD-N" async></script>
```
- Formato: `?v=YYYYMMDD-N` dove N è un contatore giornaliero
- Esempio: `?v=20260101-1`, `?v=20260101-2`, ecc.
- Questo forza il browser a ricaricare il JavaScript aggiornato

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