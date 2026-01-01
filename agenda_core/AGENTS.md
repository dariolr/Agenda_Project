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

⚠️ REGOLA CRITICA DATABASE:
- **MAI** inserire, modificare o eliminare dati nel database senza richiesta esplicita dell'utente
- Le operazioni di seed/migration vanno eseguite solo se l'utente lo richiede
- In caso di dubbio, chiedere conferma prima di modificare dati in produzione

⚠️ REGOLA CRITICA DEPLOY:
- **MAI** deployare l'intero progetto con un singolo rsync
- Deployare SOLO: `public_html/`, `src/`, `vendor/`, `bin/` (se necessario)
- **MAI** deployare: `docs/`, `tests/`, `scripts/`, `migrations/`, `lib/`, `.git/`, `*.md`, `phpunit.xml`
- Usare sempre i comandi specifici documentati in DEPLOY.md sezione 12