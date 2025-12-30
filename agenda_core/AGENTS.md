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
- GET  /v1/services
- GET  /v1/staff
- GET  /v1/availability
- POST /v1/bookings (protetto, idempotente)

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
- Hosting: SiteGround condiviso
- CORS: `CORS_ALLOWED_ORIGINS=https://prenota.romeolab.it,https://gestionale.romeolab.it,http://localhost:8080`
- SSH: porta 18765, chiave ed25519

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

⚠️ REGOLA CRITICA DATABASE:
- **MAI** inserire, modificare o eliminare dati nel database senza richiesta esplicita dell'utente
- Le operazioni di seed/migration vanno eseguite solo se l'utente lo richiede
- In caso di dubbio, chiedere conferma prima di modificare dati in produzione