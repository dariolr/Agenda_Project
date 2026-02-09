# Agenda Backend (Gestionale Operatori) — AI Agent Instructions

## 🚨 IDENTIFICAZIONE PROGETTO

| Campo | Valore |
|-------|--------|
| **Nome progetto** | agenda_backend |
| **Scopo** | Gestionale per OPERATORI/STAFF |
| **URL produzione** | **gestionale**.romeolab.it |
| **Cartella SiteGround PROD** | `www/gestionale.romeolab.it/public_html/` |
| **NON confondere con** | agenda_frontend (prenota.romeolab.it) |

### ⚠️ DEPLOY PRODUZIONE

```bash
# QUESTO PROGETTO VA SU gestionale.romeolab.it
cd agenda_backend
flutter build web --release --dart-define=API_BASE_URL=https://api.romeolab.it
rsync -avz --delete build/web/ siteground:www/gestionale.romeolab.it/public_html/
```

❌ **MAI** deployare su `prenota.romeolab.it` — quello è per agenda_frontend!

---

## ⚠️ TERMINOLOGIA OBBLIGATORIA

- Il termine **"frontend"** si riferisce SOLO al progetto `agenda_frontend` (prenotazioni clienti)
- Il termine **"backend"** si riferisce SOLO al progetto `agenda_backend` (gestionale operatori)
- Il termine **"core"** o **"API"** si riferisce al progetto `agenda_core` (backend PHP)
- NON usare "frontend" per indicare genericamente interfacce utente

## ⚠️ SCHEMA DATABASE - TERMINOLOGIA

- **NON esiste** una tabella `appointments` nel database
- La tabella principale è `bookings` che contiene le prenotazioni
- Ogni booking può avere più righe in `booking_items` (i singoli servizi prenotati)
- Nel codice Flutter, il modello `Appointment` rappresenta un `booking_item` (singolo servizio), NON un booking completo

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

### ⚠️ REGOLA WARNING (03/02/2026)

**Tutti i warning devono essere risolti** prima di considerare completata una modifica.

- Eseguire `flutter analyze` dopo ogni modifica
- Risolvere **tutti** i warning (info, warning, error)
- **Unica eccezione**: warning di tipo `TODO` possono rimanere

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
| 3 | `/staff` | TeamScreen |
| 4 | `/report` | ReportsScreen |
| 5 | `/prenotazioni` | BookingsListScreen |
| 6 | `/altro` | MoreScreen |
| 7 | `/chiusure` | LocationClosuresScreen |
| 8 | `/profilo` | ProfileScreen |
| 9 | `/permessi` | OperatorsScreen |

**Route non-shell:**
- `/change-password` → ChangePasswordScreen
- `/reset-password/:token` → ResetPasswordScreen

⚠️ NON modificare gli indici delle branch.

---

## 🧭 Navigazione Compatta (03/02/2026)

**Desktop e Mobile** usano la stessa struttura a 3 voci:

| Voce | Indice | Azione |
|------|--------|--------|
| Agenda | 0 | Naviga a branch 0 |
| Clienti | 1 | Naviga a branch 1 |
| Altro | 2 | Mostra sottomenu |

**Sottomenu "Altro" contiene:**
- Servizi → branch 2
- Team → branch 3
- **Permessi** → branch 9
- Report → branch 4
- Prenotazioni → branch 5
- Chiusure → branch 7
- Profilo → branch 8

**Implementazione:**
- Mobile: `_showMoreBottomSheet()` mostra BottomSheet
- Desktop: `_showMorePopupMenu()` mostra PopupMenu

### ⚠️ Aggiungere nuove interfacce in "Altro"

Quando si aggiunge una nuova sezione accessibile da "Altro", seguire **obbligatoriamente** questo pattern:

#### 🚨 REGOLE CRITICHE

1. **DEVE essere una StatefulShellBranch** — MAI usare route push (`parentNavigatorKey: _rootNavigatorKey`)
2. **La navigation bar DEVE rimanere visibile** — l'utente deve poter navigare liberamente
3. **NO AppBar con back button** — usa `automaticallyImplyLeading: false` o nessun `leading`
4. **Stessa struttura delle altre schermate** — Scaffold senza AppBar.leading custom

#### Pattern obbligatorio

1. **Router** (`router_provider.dart`):
   - Aggiungere un nuovo `StatefulShellBranch` con indice incrementale
   - **MAI** usare `parentNavigatorKey: _rootNavigatorKey`
   - Usare `context.go('/path')` nel menu, **MAI** `context.push()`

2. **Screen**:
   - **NO** `AppBar.leading: IconButton(icon: Icons.arrow_back, ...)`
   - **NO** `context.pop()` per tornare indietro
   - Usare `Scaffold` con `AppBar` semplice (solo titolo)
   
   ```dart
   // ✅ CORRETTO
   Scaffold(
     appBar: AppBar(
       title: Text(l10n.screenTitle),
     ),
     body: ...
   )
   
   // ❌ VIETATO
   Scaffold(
     appBar: AppBar(
       leading: IconButton(
         icon: const Icon(Icons.arrow_back),
         onPressed: () => context.pop(),
       ),
       title: Text(l10n.screenTitle),
     ),
     body: ...
   )
   ```

3. **MoreScreen** (`more_screen.dart`):
   - Aggiungere un `_MoreItem` nella lista con:
     - `icon`: icona outlined
     - `title`: chiave localizzazione titolo
     - `description`: chiave localizzazione descrizione
     - `color`: colore Material distintivo
     - `onTap`: `context.go('/path')` — **MAI** `context.push()`

4. **Localizzazioni** (`intl_it.arb`, `intl_en.arb`):
   - Aggiungere chiavi per titolo e descrizione

5. **Scaffold** (`scaffold_with_navigation.dart`):
   - Verificare che la mappatura indici includa il nuovo branch nel gruppo "Altro"

6. **AGENTS.md**:
   - Aggiornare tabella "Route fisse" con nuovo indice
   - Aggiornare lista "Sottomenu Altro"

**Esempio `_MoreItem`:**
```dart
_MoreItem(
  icon: Icons.new_feature_outlined,
  title: l10n.newFeatureTitle,
  description: l10n.newFeatureDescription,
  color: const Color(0xFF9C27B0),
  onTap: () => context.go('/new-feature'),
),
```

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
- **Divider**: usare sempre `PopupMenuDivider()` nei menu popup e `Divider()` per le liste. Non specificare parametri custom se non richiesto esplicitamente.

### Icone Standard (30/01/2026)

**Regole OBBLIGATORIE per icone consistenti:**

| Elemento | Icona CORRETTA | Icona VIETATA |
|----------|----------------|---------------|
| **Servizi** | `Icons.category_outlined` | ~~`Icons.cut`~~, ~~`Icons.content_cut`~~ (forbici) |
| **Prenotazione online** | `Icons.cloud_outlined` | - |
| **Prenotazione telefono** | `Icons.phone` | - |
| **Prenotazione walk-in** | `Icons.directions_walk` | - |
| **Prenotazione interna** | `Icons.person` | - |

**IMPORTANTE:** NON usare MAI l'icona delle forbici (`Icons.cut`, `Icons.content_cut`) per rappresentare servizi. Usare sempre `Icons.category_outlined` o `Icons.category`, coerentemente con la navigation rail principale.

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

### 🚨 REGOLA CRITICA DEPLOY (29/01/2026)
**MAI eseguire deploy (build + rsync) di progetti Flutter (agenda_frontend o agenda_backend) senza ESPLICITA richiesta dell'utente.**

- **Eseguire deploy in PRODUZIONE** (build + rsync verso `gestionale.romeolab.it`) senza richiesta esplicita dell'utente
- **Avviare l'applicazione** (`flutter run`) senza richiesta esplicita dell'utente
- **Suggerire "hot reload"** — l'utente sa già quando fare reload, non serve dirgli nulla
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
| Location Closures | `features/business/providers/location_closures_provider.dart` |
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

### Location Closures (Chiusure Sedi) (03/02/2026)
Periodi di chiusura per una o più sedi (festività, ferie, manutenzione).

**Relazione N:M:** Una chiusura può applicarsi a più location, e una location può avere più chiusure.

**Provider:** `locationClosuresProvider` (AsyncNotifier)
- Carica chiusure da API per business corrente
- Metodi: `addClosure()`, `updateClosure()`, `deleteClosure()`

**Provider derivati:**
- `isDateClosedProvider(DateTime)` - verifica se una data è chiusa per la location corrente

**Modello:** `LocationClosure`
- `id`, `businessId`, `startDate`, `endDate`, `reason`
- `locationIds` (List<int>) - sedi interessate dalla chiusura
- `durationDays` - getter per calcolare durata
- `containsDate(DateTime)` - verifica se una data ricade nel periodo

**File Flutter:**
- `lib/core/models/location_closure.dart` - modello dati
- `lib/features/business/providers/location_closures_provider.dart` - provider + isDateClosedProvider
- `lib/features/business/providers/closures_filter_provider.dart` - filtri periodo UI
- `lib/features/business/presentation/location_closures_screen.dart` - schermata principale
- `lib/features/business/presentation/dialogs/location_closure_dialog.dart` - dialog crea/modifica
- `lib/features/business/widgets/closures_header.dart` - header con filtri periodo e location
- `lib/core/network/api_client.dart` → metodi `getLocationClosures`, `createLocationClosure`, `updateLocationClosure`, `deleteLocationClosure`

**Integrazione disponibilità:**
- `staffSlotAvailabilityProvider` verifica chiusure prima di calcolare disponibilità
- Se la data è chiusa per la location corrente, ritorna tutti gli slot come non disponibili

**Localizzazioni:** Chiavi con prefisso `closures*`

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

## � Prenotazioni Ricorrenti (23/01/2026)

### Funzionalità
Gli operatori possono creare prenotazioni ricorrenti (settimanali, bisettimanali, mensili) per un cliente.

### Modello Dati Flutter

**Appointment** (`lib/core/models/appointment.dart`):
```dart
final int? recurrenceRuleId;   // ID regola ricorrenza (null se singolo)
final int? recurrenceIndex;    // Posizione nella serie (1-based)
final int? recurrenceTotal;    // Totale appuntamenti attivi nella serie

bool get isRecurring => recurrenceRuleId != null;
```

### UI Visualizzazione

**AppointmentCard** mostra:
- Icona `Icons.repeat` per appuntamenti ricorrenti
- Tooltip "X di Y" (es. "3 di 12")

### Dialog Azioni Serie

**File:** `lib/features/agenda/presentation/dialogs/recurring_action_dialog.dart`

**Scope disponibili:**
| Scope | Descrizione |
|-------|-------------|
| `single` | Solo questo appuntamento |
| `thisAndFuture` | Questo e tutti i futuri |
| `all` | Tutta la serie |

**Funzioni:**
- `showRecurringDeleteDialog()` → Restituisce `RecurringDeleteResult`
- `showRecurringEditDialog()` → Restituisce `RecurringEditResult`

### API Client

**File:** `lib/features/agenda/data/bookings_api.dart`

| Metodo | Endpoint |
|--------|----------|
| `previewRecurringBooking()` | `POST /v1/locations/{id}/bookings/recurring/preview` |
| `createRecurringBooking()` | `POST /v1/locations/{id}/bookings/recurring` |
| `getRecurringSeries()` | `GET /v1/bookings/recurring/{rule_id}` |
| `modifyRecurringSeries()` | `PATCH /v1/bookings/recurring/{rule_id}` |
| `cancelRecurringSeries()` | `DELETE /v1/bookings/recurring/{rule_id}` |

### Preview Date Ricorrenti (24/01/2026)

Prima di creare la serie ricorrente, l'operatore visualizza un'anteprima delle date con eventuali conflitti.

**Dialog:** `RecurrencePreviewDialog` in `lib/features/agenda/presentation/dialogs/recurrence_summary_dialog.dart`

**Flow:**
1. Operatore configura ricorrenza nel `BookingDialog`
2. `RecurrencePreviewDialog.show()` chiama API preview
3. Mostra lista date con checkbox per escludere quelle con conflitti
4. Ritorna `List<int>?` (indici esclusi) o `null` se annullato
5. `BookingDialog._createRecurringBooking()` passa `excludedIndices` alla creazione

**Payload Preview:**
```json
POST /v1/locations/{id}/bookings/recurring/preview
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

### Integrazione con Dialog Appuntamento

**File:** `lib/features/agenda/presentation/widgets/appointment_dialog.dart`

Il metodo `_handleDelete()` verifica se l'appuntamento è ricorrente:
- Se ricorrente → mostra `showRecurringDeleteDialog()`
- Se singolo → procede con cancellazione diretta

### Localizzazioni

**Chiavi aggiunte** in `intl_it.arb` e `intl_en.arb`:
- `recurrenceSeriesOf` — "X di Y"
- `recurrenceSeriesIcon` — "Appuntamento ricorrente"
- `recurringDeleteTitle` / `recurringEditTitle`
- `recurringDeleteMessage` / `recurringEditMessage`
- `recurringDeleteChooseScope` / `recurringEditChooseScope`
- `recurringScopeOnlyThis` / `recurringScopeThisAndFuture` / `recurringScopeAll`

### File di Riferimento

| Concetto | File |
|----------|------|
| Modello Appointment | `lib/core/models/appointment.dart` |
| Card appuntamento | `lib/features/agenda/presentation/screens/widgets/appointment_card_interactive.dart` |
| Dialog azioni serie | `lib/features/agenda/presentation/dialogs/recurring_action_dialog.dart` |
| Dialog appuntamento | `lib/features/agenda/presentation/widgets/appointment_dialog.dart` |
| API bookings | `lib/features/agenda/data/bookings_api.dart` |

---

## �🔐 Autenticazione Operator (02/01/2026)

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
- `scope_type = 'business' | 'locations'` → Scope accesso per location

### File di Riferimento
| Concetto | File |
|----------|------|
| Auth provider | `lib/features/auth/providers/auth_provider.dart` |
| Login screen | `lib/features/auth/presentation/login_screen.dart` |
| API client | `lib/core/network/api_client.dart` |
| Session listener | `lib/app/session_expired_listener.dart` |

---

## 🏢 Role Scope per Location (31/01/2026)

### Funzionalità
Gli operatori possono avere accesso a **tutte le sedi** o solo a **sedi specifiche**.

### Campi Database

**Tabella `business_users`:**
- `scope_type ENUM('business','locations')` — DEFAULT 'business'

**Tabella pivot `business_user_locations`:**
- `business_user_id` (FK → business_users.id)
- `location_id` (FK → locations.id)

**Tabella pivot `business_invitation_locations`:**
- `invitation_id` (FK → business_invitations.id)
- `location_id` (FK → locations.id)

### Modelli Flutter

**BusinessUser:**
```dart
final String scopeType;     // 'business' o 'locations'
final List<int> locationIds; // IDs location accessibili

bool get hasBusinessScope => scopeType == 'business';
bool get hasLocationScope => scopeType == 'locations';
```

**BusinessInvitation:**
- Stessi campi di BusinessUser

### API Client

```dart
// Invito operatore con scope
createBusinessInvitation(
  businessId: 1,
  email: 'user@example.com',
  role: 'staff',
  scopeType: 'locations',      // 'business' o 'locations'
  locationIds: [1, 2, 3],      // solo se scopeType='locations'
)

// Aggiornamento operatore con scope
updateBusinessUser(
  businessId: 1,
  userId: 42,
  role: 'staff',
  scopeType: 'locations',
  locationIds: [1, 2],
)
```

### Provider

```dart
// Invito con scope
await ref.read(businessUsersProvider(businessId).notifier).createInvitation(
  email: email,
  role: role,
  scopeType: 'locations',
  locationIds: [1, 2, 3],
);

// Aggiornamento con scope
await ref.read(businessUsersProvider(businessId).notifier).updateUser(
  userId: userId,
  role: role,
  scopeType: 'locations',
  locationIds: [1, 2],
);
```

### UI Dialog Invito

La sezione "Accesso" appare solo se il business ha più di una location:
1. **Toggle scope**: "Tutte le sedi" / "Sedi specifiche"
2. **Multi-select location**: visibile solo se scopeType='locations'
3. **Validazione**: almeno una location richiesta se scopeType='locations'

### Localizzazioni

| Chiave | IT | EN |
|--------|----|----|
| `operatorsScopeTitle` | Accesso | Access |
| `operatorsScopeBusiness` | Tutte le sedi | All locations |
| `operatorsScopeBusinessDesc` | Accesso completo a tutte le sedi | Full access to all locations |
| `operatorsScopeLocations` | Sedi specifiche | Specific locations |
| `operatorsScopeLocationsDesc` | Accesso limitato alle sedi selezionate | Access limited to selected locations |
| `operatorsScopeSelectLocations` | Seleziona sedi | Select locations |
| `operatorsScopeLocationsRequired` | Seleziona almeno una sede | Select at least one location |

### File Coinvolti

| File | Responsabilità |
|------|----------------|
| `lib/core/models/business_user.dart` | Model con scopeType e locationIds |
| `lib/core/models/business_invitation.dart` | Model con scopeType e locationIds |
| `lib/core/network/api_client.dart` | Metodi API con parametri scope |
| `lib/features/business/data/business_users_repository.dart` | Repository CRUD |
| `lib/features/business/providers/business_users_provider.dart` | Notifier state |
| `lib/features/business/presentation/dialogs/invite_operator_dialog.dart` | Dialog invito con scope UI |
| `lib/core/l10n/intl_it.arb` | Localizzazioni IT |
| `lib/core/l10n/intl_en.arb` | Localizzazioni EN |

---

## 🔐 Sistema Permessi UI (03/02/2026)

### Funzionalità
Il gestionale applica controlli di visibilità in base al ruolo dell'utente loggato.

### Gerarchia Ruoli

| Ruolo | Permessi |
|-------|----------|
| **Owner** | Accesso completo, può gestire operatori e business |
| **Admin** | Come owner ma non può cedere ownership |
| **Manager** | Vede tutti gli appuntamenti, non gestisce operatori/impostazioni |
| **Staff** | Vede solo propri appuntamenti, nessuna gestione |

### API Endpoint
`GET /v1/me/business/{business_id}` — Ritorna contesto utente nel business:

```json
{
  "user_id": 6,
  "business_id": 1,
  "role": "staff",
  "scope_type": "business",
  "location_ids": [],
  "staff_id": 3,
  "is_superadmin": false
}
```

### Provider Flutter

| Provider | Tipo | Descrizione |
|----------|------|-------------|
| `currentBusinessUserContextProvider` | AsyncNotifier | Carica contesto da API |
| `canManageOperatorsProvider` | bool | True se owner/admin |
| `canViewAllAppointmentsProvider` | bool | True se owner/admin/manager |
| `canManageBusinessSettingsProvider` | bool | True se owner/admin |
| `currentUserStaffIdProvider` | int? | ID staff se l'utente ha ruolo staff |

### Effetti UI per Ruolo Staff

1. **Menu "Altro"**: Non vede Servizi, Staff, Chiusure, Permessi
2. **Agenda**: Vede solo propri appuntamenti
3. **Selettore staff**: Nascosto (vede solo se stesso)
4. **Colonne agenda**: Solo la propria

### File Coinvolti

| File | Responsabilità |
|------|----------------|
| `lib/features/auth/providers/current_business_user_provider.dart` | Provider contesto + permessi |
| `lib/features/business/presentation/more_screen.dart` | Visibilità menu condizionale |
| `lib/features/agenda/providers/appointment_providers.dart` | Filtro appuntamenti per staff |
| `lib/features/agenda/providers/staff_filter_providers.dart` | Filtro staff visibili per ruolo |
| `lib/app/widgets/top_controls.dart` | Nasconde selettore staff per role=staff |
| `lib/app/scaffold_with_navigation.dart` | Nasconde selettore staff compatto |
| `src/Http/Controllers/AuthController.php` | Endpoint myBusinessContext |

### Uso nei Widget

```dart
// Verificare permesso prima di mostrare elemento
final canManage = ref.watch(canManageOperatorsProvider);
if (canManage) {
  // Mostra voce menu "Permessi"
}

// Ottenere staff_id dell'utente corrente (null se non è staff)
final staffId = ref.watch(currentUserStaffIdProvider);
```

---

## 🏷️ Versione App e Cache Busting (01/02/2026)

### Singolo punto di configurazione
La versione è definita **una sola volta** in `web/index.html`:

```html
<script>
  window.appVersion = "YYYYMMDD-N.P";
</script>
```

Questa variabile viene usata per:
1. **Cache busting** — Il tag `flutter_bootstrap.js` viene generato dinamicamente con `?v=` dalla stessa variabile
2. **Footer login** — Mostrato nella schermata di login come `vYYYYMMDD-N.P`
3. **Auto-aggiornamento** — Il file `web/app_version.txt` viene usato dal `VersionChecker` per rilevare nuove versioni

### Formato versione

```
YYYYMMDD-N.P
│        │ │
│        │ └── P = Numero progressivo deploy PRODUZIONE (incrementa AUTOMATICAMENTE con deploy.sh)
│        └──── N = Contatore giornaliero modifiche (incrementa automaticamente)
└───────────── Data (anno, mese, giorno)
```

**Esempio:** `20260201-1.10` = prima modifica del 01/02/2026, decimo deploy in produzione

### Script di Deploy (aggiornamento automatico)

| Script | Comportamento P |
|--------|-----------------|
| `deploy.sh` | Incrementa P automaticamente (+1 ad ogni deploy) |

**Lo script:**
- Incrementa N se stesso giorno, resetta a 1 se giorno diverso
- Aggiorna `web/index.html` (window.appVersion)
- Aggiorna `web/app_version.txt` (per VersionChecker)

### File app_version.txt

Il file `web/app_version.txt` contiene solo la stringa versione (es. `20260201-1.10`).

**Scopo:** Permette al `VersionChecker` di rilevare nuove versioni deployate senza dover parsare index.html.

**Flow auto-aggiornamento:**
1. `VersionChecker` legge `/app_version.txt?_={timestamp}` periodicamente
2. Confronta con versione corrente da `window.appVersion`
3. Se diversa → mostra dialog "Nuova versione disponibile"
4. Utente clicca "Aggiorna" → `window.location.reload(true)`

### File di riferimento
| File | Scopo |
|------|-------|
| `web/index.html` | Definizione `window.appVersion` |
| `web/app_version.txt` | Versione plain text per VersionChecker |
| `lib/core/utils/app_version.dart` | Utility `getAppVersion()` per leggere da JS |
| `lib/core/services/version_checker.dart` | Controllo periodico nuove versioni |
| `lib/features/auth/presentation/login_screen.dart` | Mostra versione nel footer |
| `scripts/deploy.sh` | Deploy PROD (incrementa P) |

---

## 📊 Servizi Popolari nel Picker (26/01/2026)

### Funzionalità
Quando l'operatore crea/modifica una prenotazione, il picker servizi mostra in cima una sezione "Più richiesti" con i servizi più prenotati **per quello staff** negli ultimi 90 giorni.

### Numero di Servizi Popolari Mostrati
Il numero è **proporzionale ai servizi abilitati** per lo staff:
- 1 servizio popolare ogni 7 servizi abilitati
- Massimo 5 servizi popolari
- Se meno di 7 servizi abilitati → sezione nascosta

| Servizi abilitati | Popolari mostrati |
|-------------------|-------------------|
| 0-6 | 0 (nascosto) |
| 7-13 | 1 |
| 14-20 | 2 |
| 21-27 | 3 |
| 28-34 | 4 |
| 35+ | 5 |

### Come funziona
- I servizi popolari sono calcolati **per staff**, non per location
- Quando si clicca su uno slot di uno staff, vengono caricati i servizi popolari di quello staff specifico
- Se lo staff del primo servizio cambia, vengono ricaricati i servizi popolari del nuovo staff

### Regole di visualizzazione
- **Categoria mostrata** solo se i servizi popolari appartengono a categorie diverse
- **Filtro staff abilitati**: se presente, mostra solo i servizi popolari che lo staff può erogare
- **Checkbox "Mostra tutti"**: se attivo, mostra tutti i servizi indipendentemente dall'abilitazione

### File Flutter
| File | Responsabilità |
|------|----------------|
| `lib/core/models/popular_service.dart` | Modello `PopularService` e `PopularServicesResult` |
| `lib/features/services/providers/popular_services_provider.dart` | FutureProvider.family per staffId |
| `lib/features/agenda/presentation/widgets/service_picker_field.dart` | Sezione `_PopularServicesSection` |
| `lib/features/agenda/presentation/widgets/booking_dialog.dart` | Passa staffId del primo item |
| `lib/features/agenda/presentation/widgets/appointment_dialog.dart` | Passa staffId del primo item |
| `lib/core/network/api_client.dart` | Metodo `getPopularServices(staffId)` |

### Localizzazioni
- `popularServicesTitle` — "Più richiesti" (IT) / "Most Popular" (EN)

---

## ⏰ Smart Time Slots - Configurazione Fasce Orarie (27/01/2026)

### Funzionalità
Gli operatori possono configurare come vengono mostrati gli orari disponibili ai clienti che prenotano online tramite il dialog delle sedi.

### Campi Configurabili (tabella `locations`)
| Campo | Tipo | Default | Descrizione |
|-------|------|---------|-------------|
| `slot_interval_minutes` | INT | 15 | Intervallo tra gli slot mostrati (5-60 min) |
| `slot_display_mode` | ENUM | 'all' | Modalità visualizzazione |
| `min_gap_minutes` | INT | 30 | Gap minimo accettabile (0-120 min) |

### Modalità Visualizzazione

| Modalità | Label UI | Descrizione |
|----------|----------|-------------|
| `all` | "Massima disponibilità" | Mostra tutti gli slot disponibili |
| `min_gap` | "Riduci spazi vuoti" | Nasconde slot che creerebbero gap < min_gap_minutes |

### UI nel Dialog Sede

La sezione "Fasce orarie intelligenti" appare nel dialog di modifica sede con:
1. **Dropdown intervallo** — 5, 10, 15, 20, 30, 45, 60 minuti
2. **Dropdown modalità** — "Massima disponibilità" / "Riduci spazi vuoti"
3. **Dropdown gap minimo** — 15, 30, 45, 60, 90, 120 minuti (visibile solo se mode='min_gap')

### File Flutter (agenda_backend)
| File | Responsabilità |
|------|----------------|
| `lib/core/models/location.dart` | Campi `slotIntervalMinutes`, `slotDisplayMode`, `minGapMinutes` |
| `lib/core/network/api_client.dart` | Parametri in `updateLocation()` |
| `lib/features/business/data/locations_repository.dart` | Passaggio parametri API |
| `lib/features/agenda/providers/location_providers.dart` | Metodo `updateLocation()` |
| `lib/features/staff/presentation/dialogs/location_dialog.dart` | UI configurazione |

### Localizzazioni
- `teamLocationSmartSlotSection` — "Fasce orarie intelligenti"
- `teamLocationSlotIntervalLabel` — "Intervallo tra gli orari"
- `teamLocationSlotDisplayModeLabel` — "Modalità visualizzazione"
- `teamLocationSlotDisplayModeAll` — "Massima disponibilità"
- `teamLocationSlotDisplayModeMinGap` — "Riduci spazi vuoti"
- `teamLocationMinGapLabel` — "Gap minimo accettabile"
- `teamLocationMinutes` — "{count} minuti"

### Note Importanti
- Il filtraggio avviene **solo** nel frontend prenotazioni (agenda_frontend)
- Il gestionale mostra sempre tutti gli slot disponibili
- La logica di filtraggio è implementata in `ComputeAvailability` (agenda_core)

---

## 📊 Reports - Statistiche Appuntamenti (27/01/2026)

### Funzionalità
Sezione dedicata alle statistiche con filtri avanzati per periodo, sede, staff, servizi e stato appuntamenti.

### Struttura a Tab (02/02/2026)
La sezione Reports è organizzata in due tab:
1. **Appuntamenti** — Statistiche appuntamenti (fatturato, occupazione, breakdown per staff/sede/servizio/orario)
2. **Team** — Riepilogo ore pianificate, prenotate, blocchi e assenze per staff

### Filtri Periodo Predefiniti

| Preset | Descrizione |
|--------|-------------|
| `custom` | Scegli periodo (apre date picker) |
| `today` | Oggi |
| `month` | Mese corrente (1° - ultimo giorno) |
| `quarter` | Trimestre corrente |
| `semester` | Semestre corrente |
| `year` | Anno corrente (1 gen - 31 dic) |
| `last_month` | Mese scorso |
| `last_3_months` | Ultimi 3 mesi (fino a fine mese scorso) |
| `last_6_months` | Ultimi 6 mesi (fino a fine mese scorso) |
| `last_year` | Anno precedente |

### Toggle "Includi intero periodo"

Per i preset "correnti" (mese, trimestre, semestre, anno) è disponibile uno switch:
- **OFF (default)**: il periodo arriva fino alla data odierna
- **ON**: il periodo copre l'intero arco temporale (anche futuro)

Lo switch NON appare per: `custom`, `today`, `last_month`, `last_3_months`, `last_6_months`, `last_year`.

### Sezioni Report Appuntamenti

| Sezione | Colonne |
|---------|----------|
| **Riepilogo** | Card con totali (appuntamenti, fatturato, media, tasso occupazione) |
| **Per operatore** | Staff, Appuntamenti, Fatturato, Media/app, % |
| **Per sede** | Sede, Appuntamenti, Fatturato, Ore, % |
| **Per servizio** | Servizio, Categoria, Appuntamenti, Fatturato |
| **Per fascia oraria** | Ora, Appuntamenti, Fatturato, % |
| **Per periodo** | Periodo, Appuntamenti, Fatturato |

### Sezioni Report Team (02/02/2026)

| Sezione | Descrizione |
|---------|-------------|
| **Riepilogo** | 6 card: Pianificate, Prenotate, Blocchi, Assenze, Effettive, Occupazione % |
| **Per operatore** | Tabella con breakdown per staff |

**Colonne tabella staff:**
| Colonna | Descrizione |
|---------|-------------|
| Operatore | Nome staff con colore |
| Pianificate | Ore da planning settimanale |
| Prenotate | Ore da booking_items |
| Blocchi | Ore da time_blocks |
| Assenze | Ore da staff_availability_exceptions (unavailable) |
| Effettive | Pianificate - Blocchi |
| Occupazione | Prenotate / Effettive × 100 |

**API Endpoint:** `GET /v1/reports/work-hours`

**Parametri query:**
- `business_id` (required)
- `start_date`, `end_date` (required, formato Y-m-d)
- `location_ids[]` (optional)
- `staff_ids[]` (optional)

**Filtri tab Team:**
- Sede e Staff → mostrati se multipli
- Servizi e Stato → **NON mostrati** (non pertinenti)

### File Flutter

| File | Responsabilità |
|------|----------------|
| `lib/features/reports/presentation/reports_screen.dart` | Schermata principale con TabBar e contenuti |
| `lib/features/reports/providers/reports_provider.dart` | Provider per fetch dati da API (reportsProvider + workHoursReportProvider) |
| `lib/features/reports/domain/report_models.dart` | Modelli dati report (AppointmentsReport + WorkHoursReport) |

### Localizzazioni Principali
- `reportsPresetCustom` — "Scegli periodo"
- `reportsPresetMonth` — "Mese corrente"
- `reportsPresetQuarter` — "Trimestre corrente"
- `reportsPresetSemester` — "Semestre corrente"
- `reportsPresetYear` — "Anno corrente"
- `reportsFullPeriodToggle` — "Includi intero periodo (anche futuro)"
- `reportsTabAppointments` — "Appuntamenti"
- `reportsTabStaff` — "Team"
- `reportsWorkHoursScheduled` — "Pianificate"
- `reportsWorkHoursWorked` — "Prenotate"
- `reportsWorkHoursBlocked` — "Blocchi"
- `reportsWorkHoursOff` — "Assenze"
- `reportsWorkHoursAvailable` — "Effettive"
- `reportsWorkHoursUtilization` — "Occupazione"
- `actionApply` — "Applica" (pulsante date picker)

---

## 📋 Lista Prenotazioni - Bookings List (30/01/2026)

### Funzionalità
Sezione dedicata alla visualizzazione e gestione delle prenotazioni con filtri avanzati, paginazione e ordinamento.

### Accesso
- Tab "Prenotazioni" nella navigation bar (index 5)
- Scorciatoia: pulsante refresh nella AppBar per ricaricare

### API Endpoint
`GET /v1/businesses/{business_id}/bookings/list`

Documentato in dettaglio in `agenda_core/docs/api_contract_v1.md`.

### Filtri Disponibili

| Filtro | Tipo | Descrizione |
|--------|------|-------------|
| **Periodo** | Date range | Preset predefiniti o range custom |
| **Sede** | Multi-select | Una o più sedi |
| **Operatore** | Multi-select | Uno o più staff |
| **Servizio** | Multi-select | Uno o più servizi |
| **Stato** | Multi-select | confirmed, cancelled, completed, no_show, pending |
| **Ricerca cliente** | Testo | Cerca in nome/email/telefono |

### Preset Periodo

| Preset | Descrizione |
|--------|-------------|
| `today` | Oggi |
| `month` | Mese corrente (intero) |
| `quarter` | Trimestre corrente |
| `semester` | Semestre corrente |
| `year` | Anno corrente |
| `last_month` | Mese scorso |
| `last_3_months` | Ultimi 3 mesi |
| `last_6_months` | Ultimi 6 mesi |
| `last_year` | Anno precedente |
| `custom` | Range personalizzato |

**Nota**: A differenza dei Report, i preset "correnti" mostrano sempre l'intero periodo (incluso futuro) per vedere le prenotazioni programmate.

### Ordinamento

| Campo | Descrizione |
|-------|-------------|
| `appointment` | Per data appuntamento (default) |
| `created` | Per data creazione |

Toggle asc/desc disponibile.

### Paginazione
- Caricamento iniziale: 50 elementi
- Scroll infinito: carica altri 50 quando vicino al fondo
- Totale risultati mostrato nell'header

### Colonne Tabella

| Colonna | Campo |
|---------|-------|
| Data/ora | `first_start_time` - `last_end_time` |
| Cliente | `client_name` (+ email/phone in tooltip) |
| Servizi | `service_names` (aggregati) |
| Operatore | `staff_names` (aggregati) |
| Stato | `status` con badge colorato |
| Prezzo | `total_price` |
| Azioni | Modifica / Cancella / Dettagli |

### Azioni su Prenotazione

| Azione | Descrizione |
|--------|-------------|
| **Dettagli** | Apre dialog con dettaglio completo |
| **Modifica** | Naviga alla prenotazione nell'agenda |
| **Cancella** | Cancella con conferma (scope se ricorrente) |

### Provider Flutter

| Provider | Responsabilità |
|----------|----------------|
| `bookingsListProvider` | Stato lista + paginazione |
| `bookingsListFiltersProvider` | Filtri API (location, staff, date, etc.) |
| `bookingsListFilterProvider` | Stato UI filtro periodo (preset + date range) |

### Modello Dati

`BookingListItem` in `lib/core/models/booking_list_item.dart`:
- Dati aggregati per evitare join lato client
- `serviceNames` / `staffNames`: stringhe già formattate
- `firstStartTime` / `lastEndTime`: orari estremi
- `isRecurring`: indica se parte di serie ricorrente

`BookingsListState`:
- `bookings`: lista elementi
- `total`: totale risultati (per paginazione)
- `hasMore`: indica se ci sono altre pagine
- `isLoading` / `isLoadingMore`: stati caricamento

### File Flutter

| File | Responsabilità |
|------|----------------|
| `lib/features/bookings_list/presentation/bookings_list_screen.dart` | Schermata principale |
| `lib/features/bookings_list/providers/bookings_list_provider.dart` | Provider lista + filtri API |
| `lib/features/bookings_list/providers/bookings_list_filter_provider.dart` | Provider filtro periodo UI |
| `lib/features/bookings_list/widgets/bookings_list_header.dart` | Header con filtri |
| `lib/core/models/booking_list_item.dart` | Modello dati |
| `lib/core/network/api_client.dart` | Metodo `getBookingsList()` |

### Localizzazioni

Chiavi con prefisso `bookingsList*`:
- `bookingsListTitle` — "Prenotazioni"
- `bookingsListColumnDate` — "Data"
- `bookingsListColumnClient` — "Cliente"
- `bookingsListColumnServices` — "Servizi"
- `bookingsListColumnStaff` — "Operatore"
- `bookingsListColumnStatus` — "Stato"
- `bookingsListColumnPrice` — "Prezzo"
- `bookingsListColumnActions` — "Azioni"
- `bookingsListStatusConfirmed` — "Confermato"
- `bookingsListStatusCancelled` — "Cancellato"
- `bookingsListStatusCompleted` — "Completato"
- `bookingsListStatusNoShow` — "No Show"
- `bookingsListStatusPending` — "In attesa"
- `bookingsListActionEdit` — "Modifica"
- `bookingsListActionCancel` — "Cancella"
- `bookingsListActionView` — "Dettagli"
- `bookingsListAllLocations` — "Tutte le sedi"
- `bookingsListAllStaff` — "Tutti gli operatori"
- `bookingsListAllServices` — "Tutti i servizi"
- `bookingsListAllStatus` — "Tutti gli stati"
- `bookingsListResetFilters` — "Reset filtri"
- `bookingsListCancelConfirmTitle` — "Cancellare prenotazione?"
- `bookingsListCancelConfirmMessage` — "Questa azione non può essere annullata."
- `bookingsListCancelSuccess` — "Prenotazione cancellata"
- `bookingsListLoading` — "Caricamento..."
- `bookingsListEmpty` — "Nessuna prenotazione trovata"
- `bookingsListSourceOnline` — "Online"
- `bookingsListSourcePhone` — "Telefono"
- `bookingsListSourceWalkIn` — "Walk-in"
- `bookingsListSourceInternal` — "Interno"

---

SOURCE OF TRUTH: STAFF_PLANNING_MODEL.md
OBBLIGO: genera anche le migrazioni SQL. Nessuna implementazione è completa senza aggiornamento DB.
Leggi e segui ESATTAMENTE STAFF_PLANNING_MODEL.md. Non inventare regole. Non riscrivere la logica degli slot settimanali: riusala. Implementa solo nel progetto agenda_backend. Non toccare agenda_core né agenda_frontend.