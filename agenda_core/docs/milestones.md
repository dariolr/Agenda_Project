# Milestones — agenda_core

## Stato al 31/12/2025

| Milestone | Descrizione | Stato |
|-----------|-------------|-------|
| **M1** | Auth reale (login, refresh, logout, me) | ✅ Completato |
| **M1.1** | Register + Password Reset | ✅ Completato |
| **M1.2** | Booking Management (view, cancel, reschedule) | ✅ Completato |
| **M2** | Public browse (services, staff, availability) | ✅ Completato |
| **M3** | Booking conferma (POST /bookings + idempotency + conflict) | ✅ Completato |
| **M3.1** | Update/Delete booking | ✅ Completato |
| **M3.2** | Timezone, staff_services, location_schedules | ✅ Completato |
| **M3.3** | API Gestionali (appointments, clients CRUD) | ✅ Completato |
| **M4** | Frontend integration | ✅ Completato |
| **M4.1** | Token web hardening (cookie httpOnly) | ✅ Documentato |
| **M5** | Deploy produzione | ✅ **LIVE** |
| **M6** | Webhook infrastructure | ✅ Completato |
| **M7** | Compatibilità gestionale (agenda_backend) | ✅ Completato |
| **M7.1** | Mock elimination | ✅ Completato |
| **M8** | Test minimi | ✅ Completato |
| **M9** | Multi-user sync (adaptive polling + SSE) | ⬜ Su richiesta |
| **M10** | Notification system (Email + Webhook lifecycle) | ✅ Completato |
| **M11** | Permessi operatori gestionale (business_users) | ✅ Completato |
| **M11.1** | Sistema inviti via email (business_invitations) | ✅ Completato |
| **D1** | Deploy effettivo produzione SiteGround | ✅ **LIVE** |
| **D2** | Multi-Business Path-Based URL | ✅ **LIVE** |
| **D3** | Multi-Location Support Frontend | ✅ **LIVE** |
| **D4** | Profilo Utente e Admin Email | ✅ **LIVE** |

---

## Profilo Utente e Admin Email (D4) ✅ LIVE 31/12/2025

### Funzionalità implementate

**1. Profilo utente (`PUT /v1/me`):**
- Gli utenti possono modificare nome, cognome, email, telefono
- Validazione email unica (errore se già esistente)
- Pagina profilo in entrambi i frontend

**2. Admin email in CreateBusiness:**
- Nuovo campo `admin_email` invece di `owner_user_id`
- Se email non esiste, crea nuovo utente
- Invia email benvenuto con link reset password (24h)

**3. Trasferimento ownership in UpdateBusiness:**
- Rileva cambio `admin_email`
- Vecchio admin: ruolo da "owner" a "admin"
- Nuovo admin: creato se necessario, ruolo "owner"
- Email benvenuto al nuovo admin

**4. Reinvio invito (`POST /v1/admin/businesses/{id}/resend-invite`):**
- Genera nuovo token reset (24h)
- Invia email benvenuto
- Solo superadmin può invocare

### File modificati Backend (agenda_core)
- `src/UseCases/Auth/UpdateProfile.php` — Nuovo UseCase
- `src/UseCases/Admin/UpdateBusiness.php` — Gestione admin_email
- `src/UseCases/Admin/ResendAdminInvite.php` — Nuovo UseCase
- `src/Http/Controllers/AuthController.php` — `updateMe()` method
- `src/Http/Controllers/AdminBusinessesController.php` — `resendInvite()` action
- `src/Infrastructure/Repository/BusinessRepository.php` — `findByIdWithAdmin()`, `findAllWithSearch()` con admin_email
- `src/Http/Kernel.php` — Route PUT /v1/me e POST resend-invite

### File modificati Frontend (agenda_backend)
- `lib/features/auth/presentation/profile_screen.dart` — Nuova pagina profilo
- `lib/features/business/presentation/dialogs/edit_business_dialog.dart` — Campo admin_email
- `lib/features/business/presentation/dialogs/create_business_dialog.dart` — Campo admin_email
- `lib/features/business/presentation/business_list_screen.dart` — Menu reinvia invito
- `lib/features/business/data/business_repository.dart` — Metodo `resendAdminInvite()`
- `lib/app/router.dart` — Route /profilo

### File modificati Frontend (agenda_frontend)
- `lib/features/auth/presentation/screens/profile_screen.dart` — Nuova pagina profilo
- `lib/core/network/api_client.dart` — Metodo `put()` e `updateProfile()`
- `lib/app/router.dart` — Route /:slug/profile

---

## Multi-Location Support Frontend (D3) ✅ LIVE 30/12/2025

### Funzionalità
Se un business ha più sedi attive, l'utente può scegliere dove prenotare.
Se il business ha una sola sede, lo step "Sede" viene saltato automaticamente.

### Implementazione Backend (agenda_core)

**Nuovo endpoint pubblico:**
```
GET /v1/businesses/{business_id}/locations/public
```

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "business_id": 1,
      "name": "Sede Centrale",
      "address": "Via Roma 1",
      "city": "Milano",
      "phone": "+39 02 1234567",
      "timezone": "Europe/Rome",
      "is_default": true
    }
  ]
}
```

**File modificati:**
- `src/Http/Kernel.php` - Aggiunta route pubblica
- `src/Http/Controllers/LocationsController.php` - Aggiunto `indexPublic()` method

### Implementazione Frontend (agenda_frontend)

**Nuovi file:**
- `lib/core/models/location.dart` - Modello Location
- `lib/features/booking/providers/locations_provider.dart` - Provider per locations
- `lib/features/booking/presentation/screens/location_step.dart` - UI step selezione sede

**Provider chiave:**
- `locationsProvider` — Carica lista sedi dal backend
- `selectedLocationProvider` — NotifierProvider per selezione utente
- `hasMultipleLocationsProvider` — Bool, determina se mostrare step Sede
- `effectiveLocationProvider` — Location effettiva (scelta o default)
- `effectiveLocationIdProvider` — Int ID per chiamate API

**Booking flow modificato:**
```dart
enum BookingStep { location, services, staff, dateTime, summary }
// location step mostrato solo se hasMultipleLocations == true
```

### Note tecniche
- `LocationsController.indexPublic()` usa `$request->getAttribute('business_id')` (NON `getRouteParam()`)
- Le route pubbliche non hanno middleware auth, quindi `getRouteParam()` non funziona
- L'endpoint ritorna solo sedi con `is_active = 1`

---

## Multi-Business Path-Based (D2) ✅ LIVE 29/12/2025

### Problema risolto
L'URL originale usava `SubdomainResolver.getBusinessSlug()` che leggeva `Uri.base.pathSegments` - 
valore **statico** al caricamento della pagina JavaScript. Quando go_router cambiava il path,
`Uri.base` non si aggiornava, causando loop infiniti o loading bloccato.

### Soluzione implementata
1. **Nuovo provider**: `routeSlugProvider` (StateProvider) aggiornato dinamicamente dal router
2. **Router refactored**: Estrae `:slug` dal path e aggiorna `routeSlugProvider` nel redirect
3. **business_provider.dart**: Ora legge slug da `routeSlugProvider` invece di `SubdomainResolver`

### Struttura URL
```
/                      → Landing page (business non specificato)
/:slug                 → Redirect a /:slug/booking
/:slug/booking         → Schermata prenotazione
/:slug/login           → Login
/:slug/register        → Registrazione
/:slug/my-bookings     → Le mie prenotazioni
/reset-password/:token → Reset password (globale, no slug)
```

### Path riservati (non slug)
`reset-password`, `login`, `register`, `booking`, `my-bookings`, `change-password`, `privacy`, `terms`

### File modificati
- `lib/app/providers/route_slug_provider.dart` (NUOVO)
- `lib/app/router.dart` (REFACTORED)
- `lib/features/booking/providers/business_provider.dart` (MODIFIED)

### Test comportamento
| URL | Comportamento |
|-----|---------------|
| `https://prenota.romeolab.it/` | Landing: "Business non specificato" |
| `https://prenota.romeolab.it/salone-mario` | Redirect a `/salone-mario/booking` |
| `https://prenota.romeolab.it/salone-mario/booking` | Carica business da API |
| `https://prenota.romeolab.it/slug-inesistente` | API 404 → mostra "Business non trovato" |

---

## Deploy Produzione (D1) ✅ LIVE 28/12/2025

### URL Produzione
- **API**: https://api.romeolab.it
- **Frontend Prenotazioni**: https://prenota.romeolab.it
- **Gestionale**: https://gestionale.romeolab.it (da deployare)

### Infrastruttura SiteGround
- **Hosting**: SiteGround condiviso
- **PHP**: 8.2
- **MySQL**: MariaDB (pannello SiteGround)
- **SSH**: Porta 18765, chiave ed25519

### CORS Configurato
```
CORS_ALLOWED_ORIGINS=https://prenota.romeolab.it,https://gestionale.romeolab.it,http://localhost:8080
```

### Fix Implementati
1. **Loop infinito API** - Convertito `FutureProvider` a `StateNotifier` con flag `_hasFetched`
2. **CORS duplicate headers** - Rimosso da `.htaccess`, gestito solo in PHP
3. **Auth state rebuild** - Usato `ref.watch(authProvider.select(...))` per evitare rebuild

### Comandi Deploy
```bash
# API (agenda_core)
rsync -avz --delete --exclude='.env' --exclude='logs/' \
  agenda_core/ siteground:www/api.romeolab.it/

# Frontend (agenda_frontend)
flutter build web --release --dart-define=API_BASE_URL=https://api.romeolab.it
rsync -avz --delete build/web/ siteground:www/prenota.romeolab.it/public_html/
```

---

## Dettaglio

### M1 - Auth reale ✅
- `POST /v1/auth/login` - Ritorna access_token + refresh_token
- `POST /v1/auth/refresh` - Rotazione token, revoca su riuso
- `POST /v1/auth/logout` - Invalida sessione
- `GET /v1/me` - Profilo utente + client memberships

### M1.1 - Register + Password Management ✅
- `POST /v1/auth/register` - Registrazione nuovo utente con validazione password
- **Password Reset Flow**:
  - `POST /v1/auth/forgot-password` - Step 1: richiesta reset (email enumeration protected)
  - `POST /v1/auth/reset-password` - Step 2: conferma reset con token da email
  - Token validity: 1 ora, SHA-256 hashed, monouso
  - Reset invalida tutte le sessioni utente (force re-login)
- **Change Password**:
  - `POST /v1/me/change-password` - Cambio password per utente autenticato
  - Validazione: current password corretta, new password diversa, policy enforcement
- **Frontend (agenda_frontend)**:
  - `/reset-password/:token` - Screen per conferma reset con deep link da email
  - `/change-password` - Screen per cambio password (utenti loggati)
  - Localizzazioni complete IT/EN per tutti i flussi

### M2 - Public browse ✅
- `GET /v1/services?location_id=1` - 9 servizi raggruppati per categoria
- `GET /v1/staff?location_id=1` - 3 staff prenotabili online
- `GET /v1/availability?location_id=1&date=YYYY-MM-DD&service_ids=1,2` - ~105 slot/giorno

### M3 - Booking conferma ✅
- `POST /v1/locations/{id}/bookings` - Creazione booking
- Header `X-Idempotency-Key` - UUID v4 obbligatorio
- Conflict detection - HTTP 409 + `slot_conflict`
- Auto-create client da user
- Multi-service con durata sequenziale

### M3.1 - Update/Delete booking ✅
- `PUT /v1/locations/{id}/bookings/{id}` - Aggiorna status/notes
- `DELETE /v1/locations/{id}/bookings/{id}` - Cancella booking
- Validazione permessi: solo user che ha creato la booking può modificare/cancellare
- Status validi: 'pending', 'confirmed', 'cancelled', 'completed', 'no_show'

### M3.2 - Infrastructure enhancements ✅
- **Timezone location**: Campo `timezone` in tabella `locations` (default 'Europe/Rome')
- **Staff services restrictions**: Tabella `staff_services` per definire quali servizi ogni staff può erogare
- **L3.3 - API Gestionali ✅
- **Appointments API**: 
  - `GET /v1/locations/{id}/appointments?date=YYYY-MM-DD` - Lista appuntamenti con join
  - `PATCH /v1/locations/{id}/appointments/{id}` - Reschedule
  - `POST /v1/locations/{id}/appointments/{id}/cancel` - Cancellazione
- **Clients API**:
  - `GET /v1/clients?business_id=X&search=term` - Lista con search
  - `POST /v1/clients` - Creazione
  - `PUT /v1/clients/{id}` - Aggiornamento
  - `DELETE /v1/clients/{id}` - Soft delete (is_archived)
- Permission model: solo owner può modificare appointments/bookings

### M4 - Frontend integration ✅
- Network layer: `ApiClient` con Dio + auto token refresh
- Token storage: `flutter_secure_storage` (mobile) / memory (web MVP)
- Auth flow: login, logout, session restore
- Booking flow: services, staff, availability, confirm booking
- Tutti i mock rimossi da agenda_frontend

### M4.1 - Token web hardening ✅
- **Documentazione completa**: TOKEN_STORAGE_WEB.md
- Access token in memoria (cancellato a reload)
- Refresh token in httpOnly cookie (immune XSS)
- Cookie secure, sameSite=Strict
- Refresh automatico su reload app
- Auto-refresh interceptor per 401
- CORS configurato con credentials

### M5 - Deploy produzione ✅
- **Documentazione completa**: DEPLOY.md
- Nginx config con SSL e security headers
- PHP-FPM tuning
- Database setup con utente dedicato
- Environment config (.env.example)
- Backup script
- Monitoring e health check
- Let's Encrypt integration

### M6 - Webhook infrastructure ✅
- Migration 0008: `webhook_endpoints` + `webhook_deliveries`
- Schema eventi standard (booking.*, client.*, appointment.*)
- Retry logic preparato (attempt_count, next_retry_at)
- Payload firmabile con HMAC-SHA256
- NON attivo nei flussi (milestone futura)

### M7 - Compatibilità gestionale (agenda_backend) ✅
- **Business/Locations API**:
  - `GET /v1/businesses` - Lista businesses
  - `GET /v1/businesses/{id}` - Dettaglio business
  - `GET /v1/businesses/{id}/locations` - Locations per business
  - `GET /v1/locations/{id}` - Dettaglio location
- **Integration agenda_backend**:
  - ApiClient esteso con `getBusinesses()` e `getLocations()`
  - BusinessRepository e LocationsRepository creati
  - Provider refactored per usare API reali
  - Tutti i TODO risolti e documentati

### M7.1 - Mock elimination ✅
- **Eliminazione completa mock data**:
  - business_providers.dart: da Provider mock a FutureProvider con API
  - location_providers.dart: da Notifier con mock a Notifier con async API loading
  - appointment_providers.dart: TODO rimossi, aggiunti commenti su limitazioni API
  - Test files: 12 TODO convertiti in documentazione strategia test
- **Pattern adottati**:
  - Repository pattern per tutte le feature
  - FutureProvider per dati read-only
  - Notifier con async init per state mutabile
  - Nessun fallback a mock in produzione

### M8 - Test minimi ✅
- **Test suite completa**: 98 test, 195 asserzioni
- **AuthUseCaseTest**: Password hashing, validazione email, JWT, refresh token, sessioni
- **BookingUseCaseTest**: Validazione booking, calcolo durata, conflict detection, idempotency
- **AvailabilityTest**: Slot generation, working hours, multi-staff, timezone, buffer time
- **BookingTest**: Slot overlap, validazione date, working hours logic
- **ExceptionsTest**: Auth e Booking exceptions
- **IdempotencyTest**: UUID v4 validation
- **RequestTest/ResponseTest**: HTTP layer
- **RouterTest**: Routing e middleware
- **File test creati**:
  - `tests/AuthUseCaseTest.php` - 18 test auth logic
  - `tests/BookingUseCaseTest.php` - 18 test booking logic
  - `tests/AvailabilityTest.php` - 16 test availability computation

### M11 - Permessi operatori gestionale ✅
- **Modello Enterprise**: Superadmin globale crea businesses, non self-registration
- **Migration 0013**: Tabella `business_users` con ruoli e permessi
- **Gerarchia ruoli**: owner > admin > manager > staff
- **API Backend (agenda_core)**:
  - `GET /v1/admin/businesses` - Lista businesses (superadmin only)
  - `POST /v1/admin/businesses` - Crea business (superadmin only)
  - `GET /v1/businesses/{id}/users` - Lista operatori
  - `POST /v1/businesses/{id}/users` - Aggiungi operatore esistente
  - `PATCH /v1/businesses/{id}/users/{user_id}` - Modifica ruolo
  - `DELETE /v1/businesses/{id}/users/{user_id}` - Rimuovi operatore
- **File implementati**:
  - `BusinessUserRepository.php` - CRUD operatori con soft delete/reinvite
  - `BusinessUsersController.php` - API endpoints
  - `AdminBusinessesController.php` - API superadmin

### M11.1 - Sistema inviti via email ✅
- **Migration 0014**: Tabella `business_invitations` con token 64 caratteri
- **Flusso invito**:
  1. Owner/Admin crea invito con email + ruolo
  2. Genera token univoco, scadenza 7 giorni
  3. Utente riceve link, fa login/register
  4. `POST /v1/invitations/{token}/accept` associa utente a business
- **API Backend (agenda_core)**:
  - `GET /v1/businesses/{id}/invitations` - Lista inviti pendenti
  - `POST /v1/businesses/{id}/invitations` - Crea invito
  - `DELETE /v1/businesses/{id}/invitations/{id}` - Revoca invito
  - `GET /v1/invitations/{token}` - Dettagli invito (pubblico)
  - `POST /v1/invitations/{token}/accept` - Accetta invito (auth)
- **Frontend (agenda_backend)**:
  - Modelli: `BusinessUser`, `BusinessInvitation`
  - Repository: `BusinessUsersRepository`
  - Provider: `businessUsersProvider(businessId)` Riverpod 3.x
  - UI: `OperatorsScreen`, `InviteOperatorDialog`, `RoleSelectionDialog`
  - Localizzazioni: chiavi `operators*` in IT/EN

### M9 - Multi-user sync (adaptive polling + SSE) ⬜ Su richiesta

**Contesto**: Supportare centinaia di operatori simultanei con sessioni brevi (2-5 min) per gestione appuntamenti, mantenendo sincronizzazione dati senza overhead eccessivo su hosting condiviso.

**Pattern d'uso identificato**:
- Alta frequenza: appointments (modifiche continue + booking online random)
- Bassa frequenza: services, staff, locations (modifiche rare, 1-2 volte/mese)
- Mix business: da singolo staff (no conflitti) a team 10+ persone
- Sessioni brevi: 2-5 minuti medi, non collaborazione real-time lunga

**Requisiti**:
- ✅ Supportare 300-500 operatori su hosting condiviso
- ✅ Latency booking online < 2 secondi
- ✅ Carico server < 10 req/sec medio
- ✅ Adaptive: intervalli polling basati su staff count
- ✅ Zero overhead per business singolo operatore

---

#### Sprint 1: Adaptive Polling Foundation

**Backend (agenda_core)**:
Nessuna modifica richiesta, API esistenti sufficienti.

**Frontend (agenda_backend)**:

1. **PollingConfigProvider** [NUOVO]
   ```dart
   // lib/core/providers/polling_config_provider.dart
   @riverpod
   PollingConfig pollingConfig(Ref ref) {
     final business = ref.watch(currentBusinessProvider);
     final staffCount = ref.watch(staffProvider).length;
     
     return PollingConfig(
       appointments: _getAppointmentsInterval(staffCount),
       // Services/Staff/Locations: NO polling (load on demand)
     );
   }
   
   Duration _getAppointmentsInterval(int staffCount) {
     if (staffCount == 1) return Duration(seconds: 120);  // No conflitti
     if (staffCount <= 5) return Duration(seconds: 60);   // Team piccolo
     return Duration(seconds: 30);                         // Team grande
   }
   ```

2. **AppointmentsNotifier con Polling** [MODIFICARE]
   ```dart
   // lib/features/agenda/providers/appointment_providers.dart
   class AppointmentsNotifier extends AsyncNotifier<List<Appointment>> {
     Timer? _pollTimer;
     
     @override
     Future<List<Appointment>> build() async {
       final data = await _fetchAppointments();
       _startAdaptivePolling();
       ref.onDispose(() => _pollTimer?.cancel());
       return data;
     }
     
     void _startAdaptivePolling() {
       final config = ref.read(pollingConfigProvider);
       final interval = config.appointments;
       
       _pollTimer = Timer.periodic(interval, (_) async {
         // Protezione: skip se drag/resize attivo
         if (_isUserInteracting()) return;
         
         await _refreshSilently();
       });
     }
     
     bool _isUserInteracting() {
       final isDragging = ref.read(dragSessionProvider) != null;
       final isResizing = ref.read(isResizingProvider);
       return isDragging || isResizing;
     }
     
     Future<void> _refreshSilently() async {
       try {
         final newData = await _fetchAppointments();
         state = AsyncData(newData);
       } catch (e) {
         // Log error, non mostrare all'utente
       }
     }
   }
   ```

3. **Services/Staff/Locations: Load on Demand** [CONFERMARE]
   - NO polling automatico
   - Refresh solo dopo CREATE/UPDATE/DELETE
   - Pull-to-refresh manuale disponibile

**Testing**:
- Simulare 2-3 browser contemporanei
- Verificare adaptive intervals (1, 3, 10 staff)
- Testare protezione drag & drop (no refresh durante drag)
- Load test: 50 operatori simulati

**Deliverable**:
- Appointments sincronizzati tra operatori
- Carico server: 5-7 req/sec con 250 operatori
- Funziona su SiteGround shared hosting

**Metriche successo**:
- Conflitti appuntamenti: < 1/settimana (target)
- CPU server medio: < 8%
- Latency API P95: < 150ms

---

#### Sprint 2: SSE Real-Time per Booking Online

**Obiettivo**: Notificare operatori in < 2 secondi quando arriva booking online.

**Backend (agenda_core)**:

1. **EventStream Controller** [NUOVO]
   ```php
   // src/Http/Controllers/EventStreamController.php
   class EventStreamController {
     public function stream(Request $request): Response {
       $locationId = $request->query('location_id');
       
       // Validazione auth
       $this->requireAuth($request);
       
       // Setup SSE headers
       header('Content-Type: text/event-stream');
       header('Cache-Control: no-cache');
       header('Connection: keep-alive');
       
       // Keep-alive heartbeat
       while (true) {
         echo "event: heartbeat\n";
         echo "data: {\"timestamp\": \"" . date('c') . "\"}\n\n";
         flush();
         
         // Check for events ogni 5s
         $events = $this->eventStore->getPendingEvents($locationId);
         foreach ($events as $event) {
           echo "event: {$event->type}\n";
           echo "data: " . json_encode($event->data) . "\n\n";
           flush();
           $this->eventStore->markAsSent($event->id);
         }
         
         sleep(5);
       }
     }
   }
   ```

2. **EventStore Redis/MySQL** [NUOVO]
   ```sql
   CREATE TABLE event_stream (
     id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
     location_id INT UNSIGNED NOT NULL,
     event_type VARCHAR(100) NOT NULL,
     payload JSON NOT NULL,
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     sent_at TIMESTAMP NULL,
     INDEX idx_location_pending (location_id, sent_at)
   );
   ```

3. **Dispatch in CreateBooking** [MODIFICARE]
   ```php
   // src/UseCases/CreateBooking.php
   public function execute(CreateBookingRequest $request): Booking {
     $booking = $this->repository->create($request);
     
     // Nuovo: Dispatch SSE event
     $this->eventStore->push([
       'location_id' => $booking->location_id,
       'event_type' => 'booking.created',
       'payload' => [
         'booking_id' => $booking->id,
         'start_time' => $booking->start_time,
         'client_name' => $booking->client->full_name,
       ],
     ]);
     
     return $booking;
   }
   ```

**Frontend (agenda_backend)**:

1. **EventSource Service** [NUOVO]
   ```dart
   // lib/core/services/event_stream_service.dart
   class EventStreamService {
     EventSource? _eventSource;
     final StreamController<ServerEvent> _controller = StreamController.broadcast();
     
     Stream<ServerEvent> listen(int locationId, String accessToken) {
       _eventSource?.close();
       
       _eventSource = EventSource(
         '${ApiConfig.baseUrl}/events?location_id=$locationId',
         headers: {'Authorization': 'Bearer $accessToken'},
       );
       
       _eventSource!.addEventListener('booking.created', (event) {
         _controller.add(BookingCreatedEvent.fromJson(event.data));
       });
       
       return _controller.stream;
     }
     
     void dispose() {
       _eventSource?.close();
       _controller.close();
     }
   }
   ```

2. **AppointmentsNotifier Integration** [MODIFICARE]
   ```dart
   @override
   Future<List<Appointment>> build() async {
     final data = await _fetchAppointments();
     _startAdaptivePolling();
     _listenToSSE(); // NUOVO
     return data;
   }
   
   void _listenToSSE() {
     final locationId = ref.read(currentLocationProvider).id;
     
     ref.listen(eventStreamProvider(locationId), (prev, next) {
       if (next case AsyncData(value: final event)) {
         if (event is BookingCreatedEvent) {
           // Refresh immediato + notifica
           _refreshSilently();
           _showNotification('Nuova prenotazione online ricevuta!');
         }
       }
     });
   }
   ```

**Testing**:
- Simulare booking online da agenda_frontend
- Verificare notifica < 2s in agenda_backend
- Testare reconnection su disconnect
- Load test: 100 connessioni SSE simultanee

**Deliverable**:
- Latency booking online → notifica: < 2 secondi
- Overhead SSE: < 1% CPU (heartbeat leggero)
- Funziona con 300+ operatori

**Metriche successo**:
- Latency P95 notifica: < 2s
- Connessioni SSE concorrenti: 300+ senza problemi
- Reconnection automatica su network issues

---

#### Sprint 3: UX Polish & Manual Refresh

**Obiettivo**: Dare controllo all'utente su sincronizzazione + indicatori stato.

1. **Pull-to-Refresh** [AGGIUNGERE]
   ```dart
   // Tutte le schermate lista (agenda, clients, services, staff)
   RefreshIndicator(
     onRefresh: () => ref.refresh(dataProvider.future),
     child: ListView(...),
   )
   ```

2. **Refresh Button in AppBar** [AGGIUNGERE]
   ```dart
   AppBar(
     actions: [
       IconButton(
         icon: Icon(Icons.refresh),
         onPressed: () => ref.invalidate(appointmentsProvider),
       ),
     ],
   )
   ```

3. **Timestamp Ultimo Aggiornamento** [NUOVO]
   ```dart
   class LastUpdateIndicator extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final lastUpdate = ref.watch(lastAppointmentUpdateProvider);
       return Text(
         'Aggiornato ${_formatTimeAgo(lastUpdate)}',
         style: Theme.of(context).textTheme.bodySmall,
       );
     }
   }
   ```

4. **Sync Status Badge** [NUOVO - opzionale]
   ```dart
   // AppBar indicator
   class SyncStatusBadge extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final isSyncing = ref.watch(isSyncingProvider);
       final hasError = ref.watch(syncErrorProvider) != null;
       
       return Icon(
         hasError ? Icons.sync_problem : 
         isSyncing ? Icons.sync : Icons.check_circle,
         color: hasError ? Colors.red : 
                isSyncing ? Colors.orange : Colors.green,
         size: 16,
       );
     }
   }
   ```

5. **Settings: Disable Auto-Sync** [NUOVO - opzionale]
   ```dart
   // lib/features/settings/presentation/sync_settings_screen.dart
   SwitchListTile(
     title: Text('Sincronizzazione automatica'),
     subtitle: Text('Aggiorna appuntamenti in background'),
     value: ref.watch(autoSyncEnabledProvider),
     onChanged: (value) {
       ref.read(autoSyncEnabledProvider.notifier).state = value;
       if (!value) {
         // Stop polling
         ref.read(appointmentsProvider.notifier).stopPolling();
       }
     },
   )
   ```

**Testing**:
- UX flow: pull-to-refresh su tutte le schermate
- Indicatori timestamp corretti
- Settings disabilita/abilita sync

**Deliverable**:
- UI polish completo
- Controllo utente su sync
- Trasparenza stato sincronizzazione

---

#### Architettura Finale

**Data Sync Strategy**:
| Tipo Data | Strategia | Intervallo | Trigger |
|-----------|-----------|------------|---------|
| Appointments | Adaptive Polling | 30-120s | Auto + SSE + Manual |
| Services | Load on Demand | - | Manual refresh |
| Staff | Load on Demand | - | Manual refresh |
| Locations | Load on Demand | - | Manual refresh |
| Booking Online | SSE Push | Real-time | Server event |

**Adaptive Intervals Logic**:
- 1 staff → 120s (no conflitti possibili)
- 2-5 staff → 60s (team piccolo)
- 6+ staff → 30s (team grande)
- Pause polling durante drag/resize attivo

**Performance Target**:
- Request/sec medio: 5-7 (250 operatori)
- Request/sec picco: 20-25 (100 operatori login simultaneo)
- CPU server: < 10% su shared hosting
- Supporto: 300-500 operatori su SiteGround shared (€10/mese)

---

#### Costi & Timeline

**Sviluppo**:
- Sprint 1 (Adaptive Polling): 2 giorni × €400 = €800
- Sprint 2 (SSE): 3 giorni × €400 = €1,200
- Sprint 3 (UX Polish): 1 giorno × €400 = €400
- **Totale one-time**: €2,400

**Operativi** (annuale, 250 operatori):
- Hosting: €120/anno (shared sufficiente)
- Bandwidth: trascurabile (< 1 GB/giorno)
---

#### Decision Point: Quando Implementare

**Implementa Sprint 1 se**:
- ✅ Più di 5 business con 3+ staff
- ✅ Frequenti modifiche appuntamenti (20+/giorno per business)
- ✅ Segnalazioni conflitti da operatori (2+/settimana)

**Implementa Sprint 2 se**:
- ✅ Sprint 1 implementato e funzionante
- ✅ Booking online attivo e usato frequentemente (10+/giorno)
- ✅ Latency notifica > 1 minuto non accettabile

**Implementa Sprint 3 se**:
- ✅ Sprint 1 e/o 2 implementati
- ✅ Feedback utenti su trasparenza sync
- ✅ Richiesta controllo manuale polling

**NON implementare se**:
- ❌ Tutti business con singolo staff
- ❌ Modifiche rare (< 5/giorno)
- ❌ Nessuna segnalazione conflitti

---

#### Metriche di Successo

**KPI Post-Implementazione**:
| Metrica | Baseline | Target Sprint 1 | Target Sprint 2 |
|---------|----------|-----------------|-----------------|
| Conflitti/settimana | 3-5 | < 1 | < 1 |
| Latency booking online | N/A | 30-120s | < 2s |
| Ricariche manuali/giorno | 20-30 | < 10 | < 5 |
| Server CPU avg | 1% | 3-5% | 5-8% |
| Operatori supportati | 50 | 300 | 500 |

**Alerting**:
- ⚠️ Polling lag > 60s per 3 cicli → Network issues
- 🔴 Error rate polling > 10% → Backend problems
- 🔴 SSE disconnections > 5/ora → Infrastructure issues
- 🔴 Memory leak > 50MB in 1h → Code issue

---

#### Scalabilità Futura

| Operatori | Soluzione | Hosting | Note |
|-----------|-----------|---------|------|
| 1-300 | Sprint 1 | Shared hosting | Sufficiente |
| 301-500 | Sprint 1+2 | Shared hosting | Con SSE |
| 501-1000 | Sprint 1+2 + ETags | Cloud hosting | + Conditional requests |
| 1000+ | WebSocket full | Cloud scalabile | Real-time bi-direzionale |

**Upgrade Path**: Quando superi 500 operatori, considera migrazione a Cloud hosting e implementazione full WebSocket invece di polling + SSE.

---

### M10 - Notification System (Email + Webhook lifecycle) ✅ Completato

**Contesto**: Sistema completo di notifiche email per il ciclo di vita degli appuntamenti, con architettura multi-provider e coda asincrona.

#### Architettura Multi-Provider

**Pattern Strategy** per cambio provider via `.env`:
```ini
MAIL_PROVIDER=brevo  # smtp | brevo | mailgun
```

**Provider implementati**:
1. **SmtpProvider**: SMTP generico (SiteGround, Gmail, qualsiasi server SMTP)
2. **BrevoProvider**: Brevo API (300 email/giorno gratis) + fallback SMTP
3. **MailgunProvider**: Mailgun REST API con supporto region EU/US

#### Gerarchia Email Sender (priorità)

| Priorità | Fonte | Esempio |
|----------|-------|---------|
| **1° (alta)** | `locations.email` | `sede.roma@salonemario.it` |
| **2°** | `businesses.email` | `info@salonemario.it` |
| **3° (fallback)** | `.env MAIL_FROM_*` | `noreply@romeolab.it` |

**Logica implementata nel worker**:
```php
$fromEmail = $variables['sender_email'] 
    ?? $variables['location_email'] 
    ?? $variables['business_email'] 
    ?? null;  // null = usa .env fallback
```

#### File Backend (agenda_core)

```
src/Infrastructure/Notifications/
├── EmailProviderInterface.php    # Contratto comune
├── SmtpProvider.php              # SMTP generico
├── BrevoProvider.php             # Brevo API
├── MailgunProvider.php           # Mailgun API
├── EmailService.php              # Factory con caching
├── EmailTemplateRenderer.php     # Template HTML responsive
└── NotificationRepository.php    # CRUD coda notifiche

src/UseCases/Notifications/
├── QueueBookingConfirmation.php  # Conferma prenotazione
├── QueueBookingCancellation.php  # Cancellazione
└── QueueBookingReminder.php      # Reminder 24h prima

bin/
├── notification-worker.php       # Processa coda (cron ogni minuto)
├── queue-reminders.php           # Accoda reminder (cron ogni ora)
├── run-worker.sh                 # Wrapper portabile
└── run-reminders.sh              # Wrapper portabile

migrations/
└── FULL_DATABASE_SCHEMA.sql      # Include notification_queue, notification_templates, notification_settings
```

#### Template Email

4 template HTML responsive con versione plaintext:
1. `bookingConfirmed` - Conferma prenotazione
2. `bookingCancelled` - Cancellazione
3. `bookingReminder` - Reminder 24h
4. `bookingRescheduled` - Modifica data/ora

#### Integrazione Use Case

- **CreateBooking.php**: Accoda conferma + reminder (non bloccante)
- **DeleteBooking.php**: Accoda cancellazione (non bloccante)

#### Frontend (agenda_backend)

- **Campo email location**: Aggiunto al dialog modifica sede
- **Localizzazioni**: `teamLocationEmailLabel`, `teamLocationEmailHint` (IT/EN)

#### Cron Setup Produzione

```bash
# Wrapper script (portabili - non dipendono da path PHP)
* * * * * /path/to/agenda_core/bin/run-worker.sh
0 * * * * /path/to/agenda_core/bin/run-reminders.sh
```

#### Configurazione .env

```ini
MAIL_PROVIDER=brevo
BREVO_API_KEY=xkeysib-xxxxx
BREVO_SMTP_KEY=xsmtpsib-xxxxx
MAIL_FROM_ADDRESS=noreply@tuodominio.it
MAIL_FROM_NAME="Agenda"
```

#### Raccomandazione

Per hosting condiviso (SiteGround): **Brevo** (300 email/giorno gratuiti)
- Verificare dominio su Brevo per sender dinamico
- Ogni location/business può avere email personalizzata

---

### M11 - Permessi operatori gestionale ⬜ Proposta pronta

**Obiettivo**: Implementare sistema di autenticazione e autorizzazione per operatori del gestionale (agenda_backend), permettendo assegnazione utenti a business con ruoli e permessi.

**Problema attuale**:
- Gli operatori non hanno login nel gestionale
- Il business è hardcoded (`currentBusinessId = 1`)
- Tutti vedono tutti i business (no multi-tenant security)

**Soluzione**: Tabella `business_users` che collega `users` a `businesses`.

---

#### Sprint 1: Database & API Base

**Backend (agenda_core)**:

1. **Migration** ✅ CREATA
   - Inclusa in: `migrations/FULL_DATABASE_SCHEMA.sql`
   - Tabella `business_users` con ruoli (owner/admin/manager/staff)
   - Permessi granulari (can_manage_bookings, can_manage_clients, etc.)
   - Link opzionale a `staff_id`

2. **Repository** [DA CREARE]
   ```php
   // src/Infrastructure/Repositories/BusinessUserRepository.php
   class BusinessUserRepository {
       public function findByUserId(int $userId): array;
       public function findByBusinessId(int $businessId): array;
       public function hasAccess(int $userId, int $businessId): bool;
       public function getRole(int $userId, int $businessId): ?string;
       public function create(array $data): int;
       public function update(int $id, array $data): void;
       public function delete(int $id): void;
   }
   ```

3. **Use Cases** [DA CREARE]
   ```php
   // GetUserBusinesses - Lista business dove user ha accesso
   // InviteUserToBusiness - Invita nuovo operatore
   // UpdateBusinessUser - Modifica ruolo/permessi
   // RemoveBusinessUser - Rimuovi accesso
   ```

4. **Controller** [DA CREARE]
   ```php
   // src/Http/Controllers/BusinessUsersController.php
   // GET /v1/me/businesses
   // POST /v1/businesses/{id}/users
   // PUT /v1/businesses/{id}/users/{userId}
   // DELETE /v1/businesses/{id}/users/{userId}
   ```

5. **Middleware** [DA CREARE]
   ```php
   // BusinessAccessMiddleware - Valida accesso al business
   // Applicato a tutte le route /v1/businesses/{id}/*
   ```

**Deliverable Sprint 1**:
- API `/v1/me/businesses` funzionante
- Middleware validazione accesso
- Test unitari repository

---

#### Sprint 2: Frontend Auth

**Frontend (agenda_backend)**:

1. **Auth Feature** [DA CREARE]
   ```
   lib/features/auth/
   ├── data/
   │   └── auth_repository.dart
   ├── domain/
   │   └── auth_state.dart
   ├── providers/
   │   └── auth_provider.dart
   └── presentation/
       └── login_screen.dart
   ```

2. **Modifiche Provider** [DA MODIFICARE]
   ```dart
   // business_providers.dart
   // Cambiare da GET /v1/businesses a GET /v1/me/businesses
   final userBusinessesProvider = FutureProvider<List<Business>>((ref) async {
     final repository = ref.watch(authRepositoryProvider);
     return repository.getMyBusinesses();
   });
   ```

3. **Route Guard** [DA CREARE]
   ```dart
   // router.dart - Aggiungere redirect
   redirect: (context, state) {
     final isLoggedIn = ref.read(authProvider).isAuthenticated;
     if (!isLoggedIn && !state.matchedLocation.startsWith('/login')) {
       return '/login';
     }
     return null;
   }
   ```

4. **Business Selection** [DA MODIFICARE]
   - Mostrare dialog selezione business dopo login
   - Salvare `currentBusinessId` in local storage
   - Visualizzare business corrente in app bar

**Deliverable Sprint 2**:
- Login/logout funzionante
- Selezione business post-login
- Persistenza sessione

---

#### Sprint 3: Gestione Team

**Backend (agenda_core)**:

1. **Invite Flow**
   - `POST /v1/businesses/{id}/users` con email destinatario
   - Invio email invito (se M10 completato, altrimenti skip)
   - Token invito con scadenza 7 giorni
   - `POST /v1/invitations/{token}/accept` per accettare

2. **Team Management UI** (agenda_backend)
   - Screen lista operatori business
   - Form modifica ruolo/permessi
   - Azione rimuovi accesso
   - Azione re-invita

**Deliverable Sprint 3**:
- Invito nuovi operatori
- Gestione ruoli esistenti

---

#### Sprint 4: Permessi Granulari

**Backend**:

1. **Permission Check Middleware**
   ```php
   // Esempio: solo manager+ può gestire clienti
   if (!$this->hasPermission($userId, $businessId, 'can_manage_clients')) {
       throw AuthException::forbidden('Cannot manage clients');
   }
   ```

2. **Staff-Only View**
   - Se `role = 'staff'` e `staff_id` impostato
   - Filtrare appointments per `staff_id`
   - Nascondere altri calendari

**Frontend**:

1. **UI Conditional Rendering**
   ```dart
   if (userPermissions.canManageStaff) {
     // Mostra sezione gestione team
   }
   ```

2. **Menu Condizionale**
   - Nascondere voci menu non autorizzate
   - Disabilitare azioni non permesse

**Deliverable Sprint 4**:
- Permessi granulari funzionanti
- UI adattiva ai permessi
- Test E2E flusso completo

---

#### Metriche Successo

| Metrica | Target | Misurazione |
|---------|--------|-------------|
| Login success rate | > 99% | auth_sessions created |
| Business selection time | < 2s | UX test |
| Permission check latency | < 10ms | API profiling |
| Unauthorized access attempts | 0 | Security logs |

---

## Note Aggiuntive

### Decisioni architetturali
Vedere [decisions.md](./decisions.md) per dettaglio su:
- Mock elimination strategy
- Test strategy (backend-heavy)
- Provider loading patterns
- Business context derivation
- **Decision 21**: Sistema permessi operatori

### API Documentation
Vedere [api_contract_v1.md](./api_contract_v1.md) per contratto completo API.
