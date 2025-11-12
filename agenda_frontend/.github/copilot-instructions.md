# Copilot instructions — Agenda Platform (Flutter)

These rules teach AI coding agents how to work productively in this repo. Keep it concise, code-first, and consistent with existing patterns.

## Big picture
- App type: Flutter (web-first, also mobile/tablet). Dart SDK 3.9+.
- State: Riverpod v3 with generators (riverpod_annotation, riverpod_generator).
- Routing: go_router with a single top-level StatefulShellRoute exposing 4 branches: agenda, clienti, servizi, staff.
- Theme/localization: MaterialApp.router with custom theme builders, localization via intl_utils (L10n) with ARB files under `lib/core/l10n`.

Key entry points
- `lib/main.dart`: wraps app in `ProviderScope`.
- `lib/app/app.dart`: `MyApp`, theme + router + localization; wraps child with `LayoutConfigAutoListener` and sets app `Title` from `context.l10n`.
- `lib/app/router.dart`: `appRouter` with `StatefulShellRoute` and branch routes (e.g., `/agenda`, `/clienti`, `/servizi`, `/staff`).
- `lib/app/scaffold_with_navigation.dart`: Adaptive shell. Uses `formFactorProvider` to pick NavigationRail (desktop/tablet) vs BottomNavigationBar (mobile). Agenda branch shows `AgendaTopControls` in AppBar.

## Project structure and conventions
- Features live in `lib/features/<feature>/{data,domain,presentation,providers}`. See `scripts/setup_structure.sh` for the canonical scaffold and naming (e.g., `${feature}_screen.dart`, `${feature}_providers.dart`).
- Core shared code: `lib/core/{l10n,models,network,utils,widgets}`.
- App-level config: `lib/app/{providers,theme}`. Use `themeNotifierProvider` with `buildTheme`.
- Use Riverpod Notifiers for state; avoid ad-hoc singletons. Keep local widget state minimal.
- Use `context.l10n` for all user-facing strings. Do not hardcode texts.
- For layout/responsiveness, derive sizes from `LayoutConfig` via providers. Don’t introduce magic numbers; prefer reading `layoutConfigProvider` and `formFactorProvider`.

## How to extend routing (example)
- Add a screen under `lib/features/<feature>/presentation/<feature>_screen.dart`.
- Register route in `lib/app/router.dart` inside the appropriate `StatefulShellBranch`:
  - Example: Clients
    - Path: `/clienti`, name: `clienti`, builder: `ClientsScreen()`.
- Do not create a new top-level `MaterialApp`; screens render inside the shell.

## State and UI patterns (examples)
- Read providers with `WidgetRef`:
  - `final themeConfig = ref.watch(themeNotifierProvider);`
  - `final formFactor = ref.watch(formFactorProvider);`
- Agenda feature layers (don’t break this chain):
  - `AgendaScreen → AgendaDay → MultiStaffDayView → AgendaStaffBody → StaffColumn`
  - Scrolling, drag/drop, and overlays rely on dedicated providers; reuse existing calculators like `computeDropResult()` where present.

## Localization
- ARB and generated files live under `lib/core/l10n`. Class name: `L10n`, extension: `context.l10n`.
- Default locale is Italian (`it`). Keep new keys in ARB, not in code.

## Developer workflows
- Lint/typecheck: `scripts/run_flutter_analyze.sh` (uses `$FLUTTER_HOME/bin/flutter analyze`).
- Bundle sources for review: `scripts/bundle_lib.sh` creates `lib_bundle.txt` with all Dart files (and `pubspec.yaml`).
- Tests: use Flutter test layout under `test/` mirrors `lib/` structure. Prefer Riverpod-friendly patterns.
- MCP integration: a VS Code task "Start MCP Server (Agenda Frontend)" runs `dart mcp-server --log-file mcp.log` from the project root when needed.

## Dos and don’ts for this repo
- Do: reuse providers/components in `lib/core/widgets` like `LayoutConfigAutoListener` and `NoScrollbarBehavior`.
- Do: obey theme and interaction colors (`AppThemeConfig`, `AppInteractionColors`). Avoid hardcoded colors and paddings.
- Don’t: mount independent Scaffolds for feature roots; rely on the shell’s AppBar/navigation.
- Don’t: bypass `formFactorProvider`/`LayoutConfig` for responsive decisions.

## Where to look first
- App skeleton: `lib/app/app.dart`, `lib/app/router.dart`, `lib/app/scaffold_with_navigation.dart`.
- Feature blueprint: `scripts/setup_structure.sh` and any existing folder in `lib/features/*`.
- Conventions overview: `.github/instructions.md` (project context for AI agents).

If anything here seems off or missing, prefer the patterns in the referenced files and open an update to this document alongside your change.


# Agent Context — Feature: Appointment Management in Agenda

## 🎯 Obiettivo
Estendere la feature **Agenda** del progetto `agenda_frontend` per consentire all’operatore di:
- **creare**, **modificare**, **eliminare** e **duplicare** appuntamenti;
- tramite un nuovo pulsante "Aggiungi" nella top bar (`AgendaTopControls`);
- e tramite interazioni dirette sugli slot e sugli appuntamenti nella griglia dell’agenda.

---

## ⚙️ Contesto architetturale
- L’agenda è composta da:
  - `AgendaScreen` → vista principale con top controls e corpo staff.
  - `AgendaStaffBody` → gestisce colonne dello staff e slot temporali.
  - `AppointmentCard` → rappresenta un singolo appuntamento.
  - `appointmentsProvider` (o similare) → fornisce la lista degli appuntamenti.
- Drag, resize, overlay, scroll e sync verticale/orizzontale sono già implementati.
- Tutte le modifiche devono rispettare i comportamenti esistenti senza introdurre regressioni.

---

## 🧩 Step 1 — Aggiungere pulsante “Aggiungi” in `AgendaTopControls`
Aggiungere un piccolo pulsante “+” o “Aggiungi” accanto ai controlli data dell’agenda.

### Comportamento
Quando cliccato:
- apre un `PopupMenu` o `DropdownMenu` con due opzioni:
  1. **Aggiungi appuntamento**
  2. **Aggiungi blocco** (placeholder per future versioni)
- Se l’utente sceglie *Aggiungi appuntamento*:
  - aprire un dialog (`AppointmentDialog`) precompilato con la **data corrente** dell’agenda (`agendaDateProvider`).

---

## 🧠 Step 2 — Interazioni nella griglia Agenda

### Click su slot vuoto
- Se l’utente clicca su uno slot vuoto:
  - aprire `AppointmentDialog` precompilato con:
    - data corrente dell’agenda,
    - orario dello slot,
    - staff relativo alla colonna cliccata.

### Click su appuntamento esistente
- Mostrare un menu contestuale con le opzioni:
  - **Modifica** → apre `AppointmentDialog` con dati esistenti
  - **Duplica** → crea una copia e la inserisce nel provider
  - **Elimina** → rimuove dal provider e aggiorna la UI

---

## 🎨 Step 3 — `AppointmentDialog` (UI/UX)

### Widget
Creare un nuovo file:
lib/features/agenda/presentation/widgets/appointment_dialog.dart


### Comportamento
Dialog (o `showDialog` / `showModal`) riutilizzabile per creazione e modifica.

### Campi previsti
| Campo | Tipo | Note |
|-------|------|------|
| **Data** | `DatePicker` o `TextFormField` con validazione | precompilata |
| **Orario** | `TimePicker` o textfield validato | precompilato |
| **Servizio** | dropdown o ricerca (`Autocomplete<Service>`) | obbligatorio |
| **Cliente** | ricerca (`Autocomplete<Client>`) | opzionale |
| **Staff** | dropdown | precompilato se passato |
| **Note** | `TextFormField` multiline | opzionale |

### Azioni
- **Salva** → chiama `appointmentsProvider.notifier.add()` o `update()`
- **Annulla** → chiude il dialog
- **Elimina** → disponibile in modalità modifica

---

## 🔄 Step 4 — Provider logico

Se non esiste già, creare:
lib/features/agenda/providers/appointments_provider.dart


### Implementazione
Riverpod `Notifier` o `AsyncNotifier` che gestisce:
```dart
void add(Appointment a);
void update(Appointment a);
void remove(int id);
void duplicate(Appointment a);

