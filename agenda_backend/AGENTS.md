# Agenda Backend (Gestionale Operatori) — AGENTS

## Root Monorepo e Percorsi

Questo file può essere letto quando il workspace viene aperto direttamente dentro `agenda_backend`.

In questo caso `agenda_backend` è il progetto operativo principale, ma **non è la root reale del monorepo**.

La root reale del monorepo è la cartella padre:

`..`

Struttura attesa:

- `../agenda_backend/` — gestionale Flutter operatori/staff
- `../agenda_core/` — API PHP, DB, business logic e source of truth server-side
- `../agenda_frontend/` — booking pubblico clienti
- `../config/` — configurazioni, migrazioni, documentazione e istruzioni agenti

Non cercare le istruzioni operative in `agenda_backend/README.md`.

Prima di qualsiasi modifica leggere le istruzioni centralizzate da:

1. `../config/agents/GLOBAL_RULES.md`
2. `../config/agents/MONOREPO_MAP.md`
3. `../config/agents/agenda_backend/PROJECT_RULES.md`
4. `../config/agents/agenda_backend/UI_RULES.md`
5. `../config/agents/agenda_backend/RIVERPOD_RULES.md`
6. `../config/agents/agenda_backend/TIMEZONE_RULES.md`
7. `../config/agents/agenda_backend/TEST_COMMANDS.md`

Poi proseguire con le regole locali contenute in questo file.

Se il task impatta API, booking, disponibilità, permessi, pagamenti, notifiche o DB, verificare anche `../agenda_core` e le relative regole in `../config/agents/agenda_core/`.

Non leggere tutto il monorepo se il task è circoscritto.

Prima di modificare codice, controllare `git status` in modo coerente con la root monorepo.

## Identificazione Progetto

- Progetto: `agenda_backend`
- Scopo: gestionale operatori/staff
- Produzione: `https://gestionale.romeolab.it`
- Deploy path: `www/gestionale.romeolab.it/public_html/`
- Non confondere con `agenda_frontend` (`https://prenota.romeolab.it`)

## Regole Critiche

1. Non eseguire deploy produzione (`build + rsync`) senza richiesta esplicita.
2. Non avviare `flutter run` senza richiesta esplicita.
3. Non modificare DB/dati reali senza richiesta esplicita.
4. Non usare `StateProvider` (Riverpod 3.x): usare `Notifier` + `NotifierProvider`.
5. Non usare `SnackBar`: usare `FeedbackDialog`.
6. Non cambiare indici route `StatefulShellRoute` senza richiesta esplicita.
7. Ogni modifica DB deve avere una query SQL unica e operativa (phpMyAdmin-ready) in `config/migrations/`.
8. Ogni modifica DB deve aggiornare anche `config/migrations/FULL_DATABASE_SCHEMA.sql`.

## Terminologia Obbligatoria

- `frontend` = progetto `agenda_frontend` (clienti)
- `backend` = progetto `agenda_backend` (gestionale)
- `core` / `API` = progetto `agenda_core` (PHP)
- DB: tabella principale `bookings`, non `appointments`
- Modello Flutter `Appointment` rappresenta un `booking_item`

## Comandi Operativi

```bash
dart run intl_utils:generate
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build web --release --no-tree-shake-icons
flutter test
```

## Regola Qualità

- Eseguire `flutter analyze` dopo modifiche.
- Risolvere warning/error/info.
- Eccezione consentita: warning `TODO`.

## Architettura (sintesi)

- Pattern feature: `domain/ -> data/ -> providers/ -> presentation/`
- Routing: `go_router` con `StatefulShellRoute.indexedStack`
- Stack: Flutter 3.35+, Riverpod 3.x, go_router 16.x, intl 0.20+

## Provider Critici (non rompere)

- Drag: `dragSessionProvider`, `draggedAppointmentIdProvider`, `draggedBaseRangeProvider`, `pendingDropProvider`
- Resize: `resizingProvider`, `isResizingProvider`
- Scroll sync: `agendaScrollProvider`
- Booking: `bookingsProvider`, `appointmentsProvider`

## Route Shell Fisse (indice)

- `0 /agenda`
- `1 /clienti`
- `2 /servizi`
- `3 /staff`
- `4 /report`
- `5 /prenotazioni`
- `6 /altro`
- `7 /chiusure`
- `8 /profilo`
- `9 /permessi`
- `10 /notifiche-prenotazioni`

Route non-shell:

- `/change-password`
- `/reset-password/:token`

## Navigazione "Altro"

- Aggiunte nuove schermate devono essere branch shell, non push root.
- Usare `context.go('/path')`, non `context.push()`.
- Non usare AppBar con back custom (`context.pop()`) per tornare.

## UI/UX Essenziale

- Responsive con `formFactorProvider`.
- Desktop: dialog/popup.
- Mobile: `AppBottomSheet`.
- Localizzazione obbligatoria con `context.l10n`.
- Divider menu/lista: `PopupMenuDivider()` / `Divider()`.
- Icona servizi: usare `Icons.category_outlined`, non forbici.
- Pulsanti async con loading per prevenire doppio click.

## Superadmin (regola chiave)

- Quando si esce da un business, invalidare tutti i provider business-specific.
- Ogni nuovo provider legato a `business_id` deve essere aggiunto alla invalidazione.

## Source of Truth Staff Planning

- Documento canonico: `../config/docs/STAFF_PLANNING_MODEL.md`
- Non inventare regole oltre quel documento.

## Documentazione Progetto Centralizzata

- Cartella regole agenti: `../config/agents/agenda_backend/`
- Cartella documentazione canonica: `../config/docs/`

## Checklist Rapida

1. Drag & drop invariato.
2. Resize invariato.
3. Scroll sync invariato.
4. Testi con `context.l10n`.
5. `ref.watch()` per UI, `ref.read()` per azioni.
6. API async (`Future<T>`) nei repository.

## Uso MCP Dart/Flutter runtime

Quando lavori su questo progetto Flutter e l’app è avviata in debug, usa sempre il server MCP Dart/Flutter disponibile per verificare lo stato reale dell’app in esecuzione prima di proporre o applicare modifiche che riguardano UI, layout, navigazione, stato, errori runtime, hot reload/hot restart o comportamento visibile.

Prima di modificare codice, controlla tramite MCP:

- app Flutter/Dart collegate;
- errori runtime;
- output diagnostico rilevante;
- widget tree quando utile;
- eventuali overflow o problemi di layout;
- disponibilità di hot reload/hot restart.

Se l’app non risulta collegata al Dart Tooling Daemon o non è disponibile alcuna istanza Flutter in esecuzione, segnala chiaramente che la verifica runtime non è possibile e procedi solo con analisi statica del codice.

Non considerare MCP come sostituto dell’analisi del codice: usa sempre entrambe le fonti, cioè codice sorgente aggiornato e stato runtime quando disponibile.

Mantieni invariati tutti i comportamenti esistenti non direttamente coinvolti dalla modifica richiesta.
