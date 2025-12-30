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
│   └── business_repository.dart      # getAll, getAllAdmin, create, update
├── providers/
│   └── business_providers.dart       # businessRepositoryProvider
└── presentation/
    ├── business_list_screen.dart     # Lista + provider selezione
    └── dialogs/
        ├── create_business_dialog.dart
        └── edit_business_dialog.dart
```

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
