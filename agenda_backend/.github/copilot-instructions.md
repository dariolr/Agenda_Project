# Agenda Platform — AI Agent Instructions

Piattaforma **Agenda elettronica multi-staff** in Flutter (web primary, mobile/desktop).
L'agente deve produrre **file completi** e **non rompere le funzionalità esistenti**.
L'agente deve centralizzare il codice a favore del riutilizzo. Deve sempre verificare se esiste gia un implementazione utile prima di creare nuovo codice. Eventualmente deve estendere il codice esistente.

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
- **Mobile e Tablet**: bottom sheet (`AppBottomSheet`)

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

## ⚠️ Provider: regole obbligatorie

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
- Nuova email di benvenuto al nuovo admin

### Reinvia Invito
- Pulsante nel menu azioni della card business
- Genera nuovo token reset (24h) e invia email
- Utile se l'admin non ha impostato la password in tempo

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

### File
- `features/auth/presentation/change_password_screen.dart`

---

## 🔗 Reset Password con Verifica Token (01/01/2026)

La schermata di reset password verifica il token PRIMA di mostrare il form.

### Flow
1. Utente clicca link da email
2. App mostra "Verifica link in corso..."
3. Se token invalido/scaduto → dialog bloccante → redirect a login
4. Se token valido → mostra form reset password

### Endpoint API
- `GET /v1/auth/verify-reset-token/{token}` → verifica validità token

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

## 🔒 Login Error Persistence (01/01/2026)

Il messaggio "Credenziali non valide" è gestito in stato locale widget.

### Problema risolto
Router faceva rebuild su ogni cambio stato auth, perdendo l'errore.

### Soluzione
- Provider derivato `_routerAuthStateProvider` che cambia SOLO con autenticazione
- `LoginScreen` gestisce `_errorMessage` con `setState()`

---

## 🔄 Logout Silenzioso (01/01/2026)

### Problema risolto
Loop infinito di chiamate logout quando sessione scaduta.

### Soluzione
- `logout(silent: true)` non fa chiamata API
- `SessionExpiredListener` usa `silent: true`

---

## 📦 Categorie Servizi dall'API (01/01/2026)

### Problema risolto
Categorie hardcoded in `ServiceCategoriesNotifier`.

### Soluzione
- NO seed data, categorie caricate dall'API insieme ai servizi
- `ServicesApi.fetchServicesWithCategories()` estrae categorie dalla risposta

---

## 👤 User Menu (01/01/2026)

### Accesso
- Icona profilo nella navigation (index 4) → popup menu

### Voci
- Header: nome, email (+ badge Superadmin)
- Cambia password
- Cambia Business (solo superadmin)
- Esci

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