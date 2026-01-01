# Agenda Platform — AI Agent Instructions

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
        └── edit_business_dialog.dart    # Con campo admin_email
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

## 👤 User Menu (01/01/2026)

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