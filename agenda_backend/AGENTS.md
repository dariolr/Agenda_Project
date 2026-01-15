# Agenda Backend (Gestionale Operatori) — AI Agent Instructions

## 🚨 IDENTIFICAZIONE PROGETTO

| Campo | Valore |
|-------|--------|
| **Nome progetto** | agenda_backend |
| **Scopo** | Gestionale per OPERATORI/STAFF |
| **URL produzione** | **gestionale**.romeolab.it |
| **URL staging** | **gestionale-staging**.romeolab.it |
| **Cartella SiteGround PROD** | `www/gestionale.romeolab.it/public_html/` |
| **Cartella SiteGround STAGING** | `www/gestionale-staging.romeolab.it/public_html/` |
| **NON confondere con** | agenda_frontend (prenota.romeolab.it) |

### ⚠️ DEPLOY PRODUZIONE

```bash
# QUESTO PROGETTO VA SU gestionale.romeolab.it
cd agenda_backend
flutter build web --release --dart-define=API_BASE_URL=https://api.romeolab.it
rsync -avz --delete build/web/ siteground:www/gestionale.romeolab.it/public_html/
```

### ⚠️ DEPLOY STAGING

```bash
# STAGING: gestionale-staging.romeolab.it
cd agenda_backend
flutter build web --release --dart-define=API_BASE_URL=https://api-staging.romeolab.it
rsync -avz --delete build/web/ siteground:www/gestionale-staging.romeolab.it/public_html/
```

❌ **MAI** deployare su `prenota.romeolab.it` — quello è per agenda_frontend!

---

## ⚠️ TERMINOLOGIA OBBLIGATORIA

- Il termine **"frontend"** si riferisce SOLO al progetto `agenda_frontend` (prenotazioni clienti)
- Il termine **"backend"** si riferisce SOLO al progetto `agenda_backend` (gestionale operatori)
- Il termine **"core"** o **"API"** si riferisce al progetto `agenda_core` (backend PHP)
- NON usare "frontend" per indicare genericamente interfacce utente

---

Piattaforma **Agenda elettronica multi-staff** in Flutter (web primary, mobile/desktop).
L'agente deve produrre **file completi** e **non rompere le funzionalità esistenti**.

---

## 🛠️ Comandi essenziali

```bash
# Localizzazione (dopo modifiche ai file .arb)
dart run intl_utils:generate

# Code generation (dopo modifiche a provider con @riverpod)
dart run build_runner build --delete-conflicting-outputs

# Segnala problemi nel codice
flutter analyze

# Build web
flutter build web --release --no-tree-shake-icons

# Test
flutter test
```

---

## 📁 Architettura del progetto

```
lib/
├── app/                    # Router, theme, scaffold, providers globali
│   ├── router.dart         # go_router con StatefulShellRoute.indexedStack
│   └── providers/          # formFactorProvider (breakpoint responsive)
├── core/
│   ├── l10n/               # intl_*.arb (IT/EN), l10_extension.dart
│   ├── models/             # Appointment, Booking, Staff, Service...
│   └── widgets/            # Widget riutilizzabili
└── features/
    ├── agenda/             # FEATURE PRINCIPALE
    │   ├── domain/config/  # LayoutConfig, AgendaTheme
    │   ├── providers/      # Drag, resize, scroll, booking, appointments
    │   └── presentation/   # screens/day_view/, widgets/, dialogs/
    ├── clients/            # data/ → repository pattern (mock API)
    ├── services/
    ├── staff/
    └── business/
```

**Pattern per feature:** `domain/` → `data/` → `providers/` → `presentation/`

---

## 🔧 Stack tecnologico

| Tecnologia | Versione | Note |
|------------|----------|------|
| Flutter | 3.35+ | SDK 3.10+ |
| Riverpod | 3.x | `flutter_riverpod`, `riverpod_annotation` |
| go_router | 16.x | `StatefulShellRoute.indexedStack` |
| intl | 0.20+ | `flutter_intl` per generazione |

---

## ⚡ Provider critici (NON modificare senza ragione)

### Drag & Drop
- `draggedAppointmentIdProvider` — ID dell'appointment trascinato
- `draggedBaseRangeProvider` — Range temporale originale
- `pendingDropProvider` — Target drop in attesa
- `dragSessionProvider` — Gestione sessione drag

### Resize
- `resizingProvider` / `ResizingNotifier` — Stato resize attivo
- `isResizingProvider` — Blocca scroll durante resize

### Scroll sincronizzato
- `agendaScrollProvider` — `AgendaScrollState` con controller condivisi
- Sincronizzazione: HourColumn ↔ Timeline (verticale), MultiStaff (orizzontale)

### Booking
- `bookingsProvider` / `BookingsNotifier` — `ensureBooking()`, `deleteBooking()`, `removeIfEmpty()`
- `appointmentsProvider` — Lista appuntamenti

---

## 📍 Route fisse (indici StatefulShellRoute)

| Index | Path | Screen |
|-------|------|--------|
| 0 | `/agenda` | AgendaScreen |
| 1 | `/clienti` | ClientsScreen |
| 2 | `/servizi` | ServicesScreen |
| 3 | `/staff` | StaffWeekOverviewScreen |

⚠️ NON modificare gli indici delle branch.

---

## 🎨 Pattern UI/UX

### Responsive
```dart
final formFactor = ref.watch(formFactorProvider);
// AppFormFactor.mobile / .tablet / .desktop
```
- **Desktop**: dialog/popup
- **Mobile**: bottom sheet (`AppBottomSheet`)

### Feedback utente (10/01/2026)
**NESSUNA SnackBar** in tutta l'applicazione. Usare sempre `FeedbackDialog`:
```dart
import '/core/widgets/feedback_dialog.dart';

// Successo
await FeedbackDialog.showSuccess(
  context,
  title: 'Operazione completata',
  message: 'Dettaglio del successo',
);

// Errore
await FeedbackDialog.showError(
  context,
  title: context.l10n.errorTitle,
  message: 'Dettaglio dell\'errore',
);
```

### Localizzazione
```dart
import '/core/l10n/l10_extension.dart';
Text(context.l10n.nomeChiave)
```
Aggiungere chiavi in `lib/core/l10n/intl_it.arb` e `intl_en.arb`.

### Stile
- Estetica sobria: **no ripple/splash invasivi**
- `const` constructor dove possibile
- Estrarre widget privati da `build()` lunghi

### Pulsanti Async con Loading State (11/01/2026)
Per prevenire doppi click durante operazioni asincrone, usare i pulsanti async:

```dart
import '/core/widgets/app_buttons.dart';

// Pulsante primario con loading
AppAsyncFilledButton(
  onPressed: _isSaving ? null : _onSave,
  isLoading: _isSaving,
  child: Text(l10n.actionSave),
)

// Pulsante eliminazione con loading
AppAsyncDangerButton(
  onPressed: _isSaving ? null : _onDelete,
  disabled: _isSaving,
  child: Text(l10n.actionDelete),
)

// Pulsante outlined con loading
AppAsyncOutlinedButton(
  onPressed: _isSaving ? null : _onAction,
  isLoading: _isSaving,
  child: Text(l10n.actionConfirm),
)
```

**Pattern obbligatorio nei dialog/form:**
```dart
bool _isSaving = false;

Future<void> _onSave() async {
  // validazione...
  
  setState(() => _isSaving = true);
  try {
    await operazioneAsync();
    if (mounted) Navigator.of(context).pop();
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}
```

**Dialog già implementati con loading state:**
- `client_edit_dialog.dart` - Clienti
- `category_dialog.dart` - Categorie servizi
- `service_dialog.dart` - Servizi
- `appointment_dialog.dart` - Appuntamenti
- `booking_dialog.dart` - Prenotazioni
- `add_block_dialog.dart` - Blocchi non disponibilità

---

## ✅ Checklist prima di modificare

1. [ ] La modifica rompe drag & drop?
2. [ ] La modifica rompe resize appuntamenti?
3. [ ] La modifica altera scroll controller condivisi?
4. [ ] Tutti i testi usano `context.l10n`?
5. [ ] I provider usano `ref.watch()` per UI, `ref.read()` per azioni?
6. [ ] I mock API hanno firma async (`Future<T>`)?

---

## 🚫 L'agente NON deve

- **Eseguire deploy** (build + rsync) dei progetti Flutter senza richiesta esplicita dell'utente
- **Avviare l'applicazione** (`flutter run`) senza richiesta esplicita dell'utente
- Aggiungere dipendenze non richieste
- Modificare indici route o `router.dart` senza richiesta esplicita
- Produrre snippet parziali invece di file completi
- Usare `ref.watch()` in loop pesanti o callback
- Introdurre animazioni/effetti non richiesti
- **Usare `StateProvider`** — usare sempre `Notifier` + `NotifierProvider` per stato mutabile
- **Inserire/modificare/eliminare dati nel database** senza richiesta esplicita dell'utente

---

## ⚠️ Provider: regole obbligatorie (30/12/2025)

**MAI usare `StateProvider`**. Usare sempre `Notifier` con `NotifierProvider`:

```dart
// ❌ VIETATO
final myProvider = StateProvider<int>((ref) => 0);

// ✅ CORRETTO
class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void increment() => state++;
  void set(int value) => state = value;
}
final myProvider = NotifierProvider<MyNotifier, int>(MyNotifier.new);
```

Motivazioni:
- `StateProvider` è deprecato in Riverpod 3.x
- `Notifier` offre migliore testabilità e controllo
- Metodi espliciti rendono il codice più leggibile

---

## 🏢 Superadmin Business Flow (30/12/2025)

Il superadmin (`users.is_superadmin = 1`) ha un flow diverso dall'utente normale:

```
Login → is_superadmin?
  ├─ YES → /businesses (lista business)
  │        ├─ Crea nuovo business (FAB)
  │        ├─ Modifica business (icona edit su card)
  │        └─ Seleziona business → /agenda
  │            └─ "Cambia" in navigation (index 4) → /businesses
  └─ NO  → /agenda (flow normale)
```

### Provider chiave
- `superadminSelectedBusinessProvider` — NotifierProvider<int?> per tracciare selezione
- `businessesRefreshProvider` — NotifierProvider<int> per forzare refresh lista

### File business feature
```
features/business/
├── data/
│   └── business_repository.dart      # getAll, getAllAdmin, create, update, resendInvite
├── providers/
│   └── business_providers.dart       # businessRepositoryProvider
└── presentation/
    ├── business_list_screen.dart     # Lista + provider selezione + reinvia invito
    └── dialogs/
        ├── create_business_dialog.dart  # Con campo admin_email
        ├── edit_business_dialog.dart    # Con campo admin_email
        └── sync_to_staging_dialog.dart  # Sync bidirezionale Prod ↔ Staging
```

### 🔄 Sync Business Prod ↔ Staging (15/01/2026)

Il superadmin può sincronizzare un business tra produzione e staging in entrambe le direzioni.

**Accesso:** Menu azioni business → "Copia su Staging"

**Direzioni disponibili:**
- **Produzione → Staging**: copia TUTTI i dati (incluse sessioni e notifiche)
- **Staging → Produzione**: copia dati SENZA sessioni auth e notification queue

**Comportamento `skip_sessions_and_notifications`:**
| Direzione | Flag | Tabelle escluse |
|-----------|------|-----------------|
| Prod → Staging | `false` | Nessuna |
| Staging → Prod | `true` | `notification_queue`, `auth_sessions`, `client_sessions` |

**File Flutter:**
- `lib/features/business/presentation/dialogs/sync_to_staging_dialog.dart` - UI con selezione direzione
- `lib/core/network/api_client.dart` - metodi `exportBusinessFromProduction()`, `exportBusinessFromStaging()`, `pushBusinessToProduction()`, `pushBusinessToStaging()`, `importBusiness()`
- `lib/core/network/api_config.dart` - `productionApiUrl`, `stagingApiUrl`

**Metodi API Client:**
```dart
// Export da altro ambiente
exportBusinessFromProduction(businessId)  // quando siamo su staging
exportBusinessFromStaging(businessId)      // quando siamo su produzione

// Import su altro ambiente
pushBusinessToProduction(exportData, {skipSessionsAndNotifications: true})
pushBusinessToStaging(exportData)

// Import locale
importBusiness(exportData, {skipSessionsAndNotifications: false})
```

### ⚠️ Provider invalidation su cambio business (01/01/2026)

Quando il superadmin esce da un business (tornando a `/businesses`), **TUTTI** i provider contenenti dati o stato legato al business **devono** essere invalidati.

**Metodo responsabile:** `SuperadminSelectedBusinessNotifier._invalidateBusinessProviders()` in [business_list_screen.dart](lib/features/business/presentation/business_list_screen.dart)

**Provider attualmente invalidati (25 totali):**

| Categoria | Provider |
|-----------|----------|
| **Staff** | `allStaffProvider` |
| **Locations** | `locationsProvider`, `currentLocationProvider` |
| **Services** | `servicesProvider`, `serviceCategoriesProvider`, `serviceStaffEligibilityProvider` |
| **Clients** | `clientsProvider` |
| **Appointments** | `appointmentsProvider` |
| **Bookings** | `bookingsProvider` |
| **Resources** | `resourcesProvider` |
| **Time Blocks** | `timeBlocksProvider` |
| **Availability** | `availabilityExceptionsProvider` |
| **UI State** | `selectedStaffIdsProvider`, `staffFilterModeProvider`, `selectedAppointmentProvider` |
| **Drag & Drop** | `dragSessionProvider`, `draggedAppointmentIdProvider`, `draggedBaseRangeProvider`, `tempDragTimeProvider`, `resizingProvider`, `pendingDropProvider` |
| **Business Context** | `currentBusinessIdProvider` |
| **Layout/Date** | `layoutConfigProvider`, `agendaDateProvider`, `agendaScrollProvider` |

**REGOLA CRITICA:**
Quando si crea un **nuovo provider** che contiene:
- Dati caricati da API che dipendono da `business_id`
- ID di entità business-specific (staff, location, appointment, service, client, ecc.)
- Stato UI che referenzia entità del business

→ **Il provider DEVE essere aggiunto** a `_invalidateBusinessProviders()`.

**Esempio - nuovo provider da aggiungere:**
```dart
void _invalidateBusinessProviders() {
  // ... provider esistenti ...
  
  // Nuovo provider
  ref.invalidate(mioNuovoProviderProvider);
}
```

---

## 👤 Profilo Utente (31/12/2025)

Gli utenti possono modificare il proprio profilo dalla voce "Profilo" nel menu utente.

### Route
- `/profilo` → `ProfileScreen`

### Campi modificabili
- Nome (`first_name`)
- Cognome (`last_name`)
- Email (attenzione: cambia credenziali login)
- Telefono (`phone`)

### File
- `features/auth/presentation/profile_screen.dart`
- `features/auth/providers/auth_provider.dart` → `updateProfile()`
- `core/network/api_client.dart` → `updateProfile()`

---

## 🔐 Cambio Password (01/01/2026)

Tutti gli utenti autenticati (incluso superadmin) possono cambiare la propria password.

### Route
- `/change-password` → `ChangePasswordScreen`

### Accesso
- Menu utente (avatar) → "Cambia password"

### Validazione
- Password attuale richiesta
- Nuova password: 8+ caratteri, maiuscole, minuscole, numeri
- Nuova password deve essere diversa dalla attuale

### File
- `features/auth/presentation/change_password_screen.dart`
- `features/auth/providers/auth_provider.dart` → `changePassword()`
- `core/network/api_client.dart` → `changePassword()`

---

## 🔗 Reset Password con Verifica Token (01/01/2026)

La schermata di reset password verifica il token PRIMA di mostrare il form.

### Flow
1. Utente clicca link da email
2. App mostra "Verifica link in corso..."
3. Se token invalido/scaduto → dialog bloccante → redirect a login
4. Se token valido → mostra form reset password

### Route
- `/reset-password/:token` → `ResetPasswordScreen`

### Endpoint API
- `GET /v1/auth/verify-reset-token/{token}` → verifica validità token

### File
- `features/auth/presentation/reset_password_screen.dart`

---

## 🔑 Autofill e Salvataggio Credenziali (03/01/2026)

Per far funzionare correttamente l'autofill su Safari e il salvataggio credenziali su tutti i browser, il form di login deve:

### Requisiti
1. **`AutofillGroup`** — wrappa il Form per raggruppare i campi
2. **`autofillHints`** — specifica il tipo di campo
3. **`TextInput.finishAutofillContext()`** — segnala login completato

### Implementazione
```dart
import 'package:flutter/services.dart';

// Nel widget build()
AutofillGroup(
  child: Form(
    key: _formKey,
    child: Column(
      children: [
        TextFormField(
          controller: _emailController,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          // ...
        ),
        TextFormField(
          controller: _passwordController,
          autofillHints: const [AutofillHints.password],
          // ...
        ),
      ],
    ),
  ),
),

// Dopo login success
if (success) {
  TextInput.finishAutofillContext(); // Triggera "Vuoi salvare le credenziali?"
  context.go('/agenda');
}
```

### File modificati
- `lib/features/auth/presentation/login_screen.dart`

---

## 🌐 Flutter Web URL Strategy (01/01/2026)

Il gestionale usa `usePathUrlStrategy()` per URL path-based (senza `#`).

```dart
// main.dart
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // PRIMA di runApp!
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## ✉️ Admin Email e Inviti (31/12/2025)

### Creazione Business
- `admin_email` è **opzionale** nel dialog di creazione
- Se omesso, il business viene creato senza owner
- L'admin può essere assegnato in seguito tramite "Modifica"
- Se l'email non esiste, viene creato un nuovo utente
- Viene inviata email di benvenuto con link reset password (24h)

### Modifica Business
- Se si aggiunge `admin_email` a un business senza owner, viene assegnato come owner
- Se si cambia `admin_email`, la ownership viene trasferita
- Il vecchio admin diventa "admin", il nuovo diventa "owner"
- Nuova email di benvenuto al nuovo admin

### Reinvia Invito
- Pulsante nel menu azioni della card business
- Genera nuovo token reset (24h) e invia email
- Utile se l'admin non ha impostato la password in tempo

---

## 📚 File di riferimento

| Concetto | File chiave |
|----------|-------------|
| Layout config | `features/agenda/domain/config/layout_config.dart` |
| Scroll sync | `features/agenda/providers/agenda_scroll_provider.dart` |
| Drag session | `features/agenda/providers/drag_session_provider.dart` |
| Resize | `features/agenda/providers/resizing_provider.dart` |
| Booking | `features/agenda/providers/bookings_provider.dart` |
| Repository pattern | `features/clients/data/clients_repository.dart` |
| Form factor | `app/providers/form_factor_provider.dart` |
| Pulsanti (sync/async) | `core/widgets/app_buttons.dart` |
| Profilo utente | `features/auth/presentation/profile_screen.dart` |
| Cambio password | `features/auth/presentation/change_password_screen.dart` |
| Reset password | `features/auth/presentation/reset_password_screen.dart` |
| Business admin | `features/business/presentation/dialogs/edit_business_dialog.dart` |
| User menu | `app/widgets/user_menu_button.dart` |
| Router auth | `app/router_provider.dart` |
| Services API | `features/services/data/services_api.dart` |
| Time Blocks | `features/agenda/providers/time_blocks_provider.dart` |
| Resources | `features/agenda/providers/resource_providers.dart` |
| Availability Exceptions | `features/staff/providers/availability_exceptions_provider.dart` |
| API Client | `core/network/api_client.dart` |

---

## 🔒 Login Error Persistence (01/01/2026)

### Problema risolto
Il messaggio "Credenziali non valide" scompariva perché il router faceva rebuild su ogni cambio dello stato auth.

### Soluzione
- Provider derivato `_routerAuthStateProvider` che cambia SOLO quando `isAuthenticated` o `isSuperadmin` cambiano
- `LoginScreen` gestisce errore in stato locale (`_errorMessage`) con `setState()`
- File: `lib/app/router_provider.dart`

---

## 🔄 Logout Silenzioso (01/01/2026)

### Problema risolto
Chiamate infinite a `/v1/auth/logout` quando sessione scaduta.

### Soluzione
- `logout({bool silent = false})` - se `silent=true`, non fa chiamata API
- `SessionExpiredListener` usa `logout(silent: true)`
- File: `lib/features/auth/providers/auth_provider.dart`

---

## 📦 Categorie Servizi dall'API (01/01/2026)

### Problema risolto
La sezione Servizi mostrava categorie hardcoded anche con DB vuoto.

### Soluzione
- Rimossi seed data da `ServiceCategoriesNotifier`
- `ServicesApi.fetchServicesWithCategories()` estrae categorie dalla risposta API
- `ServicesNotifier.build()` popola `serviceCategoriesProvider` con dati API
- File: `lib/features/services/providers/service_categories_provider.dart`

---

## �️ Services e Categories CRUD via API (02/01/2026)

### Problema risolto
CRUD di servizi e categorie funzionavano solo in memoria locale, i dati venivano persi al refresh.

### Soluzione
Implementati endpoint API completi per CRUD + aggiornato Flutter per chiamarli.

### Endpoint API
| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/v1/locations/{location_id}/services` | Crea servizio |
| PUT | `/v1/services/{id}` | Aggiorna servizio |
| DELETE | `/v1/services/{id}` | Elimina servizio (soft delete) |
| GET | `/v1/businesses/{business_id}/categories` | Lista categorie |
| POST | `/v1/businesses/{business_id}/categories` | Crea categoria |
| PUT | `/v1/categories/{id}` | Aggiorna categoria |
| DELETE | `/v1/categories/{id}` | Elimina categoria |

### Metodi Provider (USARE QUESTI)
```dart
// ServicesNotifier
await notifier.createServiceApi(name: 'Taglio', durationMinutes: 30, ...);
await notifier.updateServiceApi(serviceId: 1, name: 'Taglio uomo', ...);
await notifier.deleteServiceApi(serviceId);
await notifier.duplicateServiceApi(originalService);

// ServiceCategoriesNotifier
await notifier.createCategoryApi(name: 'Capelli');
await notifier.updateCategoryApi(categoryId: 1, name: 'Capelli uomo');
await notifier.deleteCategoryApi(categoryId);
```

### Metodi DEPRECATI (NON usare)
I seguenti metodi aggiornano solo lo stato locale:
- `add()`, `updateService()`, `delete()`, `duplicate()` su ServicesNotifier
- `addCategory()`, `updateCategory()`, `deleteCategory()` su ServiceCategoriesNotifier

### File
- `lib/features/services/providers/services_provider.dart`
- `lib/features/services/providers/service_categories_provider.dart`
- `lib/features/services/data/services_api.dart`
- `lib/core/network/api_client.dart`

---

## �👤 User Menu (01/01/2026)

### Accesso
- Icona profilo nella navigation bar (index 4)
- Click apre popup menu

### Voci menu
- Header: nome e email utente (+ badge Superadmin se applicabile)
- Cambia password
- Cambia Business (solo superadmin)
- Esci

### File
- `lib/app/widgets/user_menu_button.dart` - widget riutilizzabile
- `lib/app/scaffold_with_navigation.dart` - integrazione navigation
- `lib/features/business/presentation/business_list_screen.dart` - menu per superadmin

---

## 📅 Aggiungi Eccezione nel Menu Shift (01/01/2026)

### Problema risolto
Il bottone "+" per aggiungere eccezioni occupava spazio nella griglia settimanale staff.

### Soluzione
- Rimosso bottone "+" standalone dalla colonna giorni
- Aggiunta voce "Aggiungi eccezione" nel menu contestuale dei turni
- Disponibile sia cliccando su turni base che su eccezioni esistenti
- Aggiornato `_countSegmentsForDay` per non contare +1 per il chip rimosso

### File
- `lib/features/staff/presentation/staff_week_overview_screen.dart`

---

## 🗄️ API Gestionale - Provider con Persistenza (01/01/2026)

Tutti i seguenti provider sono stati convertiti da mock a chiamate API reali.

### Staff Services (Servizi abilitati per Staff)
Relazione N:M tra staff e servizi che può erogare.

**Gestione tramite endpoint Staff esistenti:**
- `GET /v1/businesses/{business_id}/staff` - ritorna `service_ids` per ogni staff
- `POST /v1/businesses/{business_id}/staff` - accetta `service_ids` nel body
- `PUT /v1/staff/{id}` - accetta `service_ids` nel body

**File Flutter:**
- `lib/core/models/staff.dart` → campo `serviceIds`
- `lib/features/services/providers/services_provider.dart` → `eligibleServicesForStaffProvider` legge da Staff.serviceIds
- `lib/features/staff/presentation/dialogs/staff_dialog.dart` → salvataggio via API

### Staff Availability Exceptions (Eccezioni Turni)
Eccezioni ai turni base dello staff (ferie, malattia, straordinari).

**Provider:** `availabilityExceptionsProvider` (AsyncNotifier)
- Carica eccezioni da API per staff selezionato
- Metodi: `addException()`, `updateException()`, `deleteException()`

**File Flutter:**
- `lib/features/staff/providers/availability_exceptions_provider.dart`
- `lib/features/staff/data/api_availability_exceptions_repository.dart`
- `lib/core/network/api_client.dart` → metodi `getStaffAvailabilityExceptions`, `createStaffAvailabilityException`, etc.

### Resources (Risorse)
Risorse fisiche assegnabili ai servizi (es. cabine, lettini).

**Provider:** `resourcesProvider` (AsyncNotifier)
- Carica risorse da API per location corrente
- Metodi: `addResource()`, `updateResource()`, `deleteResource()`

**Provider derivato:** `locationResourcesProvider` - filtra per location

**File Flutter:**
- `lib/features/agenda/providers/resource_providers.dart`
- `lib/core/network/api_client.dart` → metodi `getResources`, `createResource`, `updateResource`, `deleteResource`

### Time Blocks (Blocchi Non Disponibilità)
Periodi di non disponibilità per uno o più staff.

**Provider:** `timeBlocksProvider` (AsyncNotifier)
- Carica blocchi da API per location corrente
- Metodi: `addBlock()`, `updateBlock()`, `deleteBlock()`, `moveBlock()`, `updateBlockStaff()`

**Provider derivati:**
- `timeBlocksForCurrentLocationProvider` - blocchi per location e data corrente
- `timeBlocksForStaffProvider(staffId)` - blocchi per staff specifico

**File Flutter:**
- `lib/features/agenda/providers/time_blocks_provider.dart`
- `lib/features/agenda/presentation/dialogs/add_block_dialog.dart`
- `lib/core/network/api_client.dart` → metodi `getTimeBlocks`, `createTimeBlock`, `updateTimeBlock`, `deleteTimeBlock`

### Mock Rimossi (01/01/2026)
I seguenti mock sono stati rimossi perché non più utilizzati:
- `MockAvailabilityExceptionsRepository` - rimosso da `availability_exceptions_repository.dart`
- `weeklyStaffAvailabilityMockProvider` - rimosso da `staff_week_overview_screen.dart`
- `ServiceStaffEligibilityNotifier` mock data - ora legge da `allStaffProvider` e `staff.serviceIds`

---

## 🔄 Refresh e Polling Dati (01/01/2026)

### Refresh all'entrata nelle sezioni
Ogni sezione ricarica i dati dal DB quando l'utente vi accede (`initState`).

| Sezione | Provider ricaricati |
|---------|--------------------|
| **Agenda** | `allStaffProvider`, `locationsProvider`, `servicesProvider`, `clientsProvider` |
| **Clienti** | `clientsProvider` |
| **Team** | `allStaffProvider`, `locationsProvider`, `servicesProvider` |
| **Servizi** | `servicesProvider`, `allStaffProvider` |

### Polling automatico in Agenda
Gli appuntamenti vengono ricaricati automaticamente con `ref.invalidate(appointmentsProvider)`:
- **Debug** (`kDebugMode`): ogni **10 secondi**
- **Produzione**: ogni **5 minuti**

Il timer parte in `initState` e si cancella in `dispose`.

### File
- `lib/features/agenda/presentation/agenda_screen.dart`
- `lib/features/clients/presentation/clients_screen.dart`
- `lib/features/staff/presentation/team_screen.dart`
- `lib/features/services/presentation/services_screen.dart`

---

## 🏢 Filtro Location Attive (01/01/2026)

Il provider `LocationsNotifier._loadLocations()` filtra automaticamente le location non attive:
```dart
state = locations.where((l) => l.isActive).toList();
```

Questo impatta:
- Filtri location nell'agenda
- Sezione Team (lista sedi)
- Dialog staff (assegnazione sedi)

### File
- `lib/features/agenda/providers/location_providers.dart`

---

## 🔐 Autenticazione Operator (02/01/2026)

### ⚠️ IMPORTANTE: Il gestionale usa SOLO autenticazione Operator

Il gestionale (agenda_backend) usa **esclusivamente** endpoint di autenticazione per operatori:
- `/v1/auth/login`
- `/v1/auth/refresh`
- `/v1/auth/logout`
- `/v1/me`

**NON** usare endpoint `/v1/customer/` nel gestionale — quelli sono riservati ai clienti che prenotano online (agenda_frontend).

### JWT Token Operator

```json
{
  "sub": 6,              // user_id (dalla tabella users)
  "role": "operator",    // identifica tipo token
  "exp": 1735830000,
  "iat": 1735829100
}
```

### Tabella Database
Gli operatori (staff, admin, owner, superadmin) sono nella tabella `users`.
I permessi sono gestiti dalla tabella `business_users`:
- `is_owner = 1` → Owner del business
- `can_manage_users = 1` → Può gestire staff
- `is_superadmin = 1` (su users) → Accesso a tutti i business

### File di Riferimento
| Concetto | File |
|----------|------|
| Auth provider | `lib/features/auth/providers/auth_provider.dart` |
| Login screen | `lib/features/auth/presentation/login_screen.dart` |
| API client | `lib/core/network/api_client.dart` |
| Session listener | `lib/app/session_expired_listener.dart` |



SOURCE OF TRUTH: STAFF_PLANNING_MODEL.md
OBBLIGO: genera anche le migrazioni SQL. Nessuna implementazione è completa senza aggiornamento DB.
Leggi e segui ESATTAMENTE STAFF_PLANNING_MODEL.md. Non inventare regole. Non riscrivere la logica degli slot settimanali: riusala. Implementa solo nel progetto agenda_backend. Non toccare agenda_core né agenda_frontend.