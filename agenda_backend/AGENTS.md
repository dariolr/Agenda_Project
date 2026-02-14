# Agenda Backend (Gestionale Operatori) — AGENTS

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
- Eseguire `flutter analyze` dopo modifiche
- Risolvere warning/error/info
- Eccezione consentita: warning `TODO`

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
- Aggiunte nuove schermate devono essere branch shell (non push root)
- Usare `context.go('/path')`, non `context.push()`
- Non usare AppBar con back custom (`context.pop()`) per tornare

## UI/UX Essenziale
- Responsive con `formFactorProvider`
- Desktop: dialog/popup
- Mobile: `AppBottomSheet`
- Localizzazione obbligatoria con `context.l10n`
- Divider menu/lista: `PopupMenuDivider()` / `Divider()`
- Icona servizi: usare `Icons.category_outlined` (non forbici)
- Pulsanti async con loading per prevenire doppio click

## Superadmin (regola chiave)
- Quando si esce da un business, invalidare tutti i provider business-specific.
- Ogni nuovo provider legato a `business_id` deve essere aggiunto alla invalidazione.

## Source of Truth Staff Planning
- Documento canonico: `docs/STAFF_PLANNING_MODEL.md`
- Non inventare regole oltre quel documento.

## Checklist Rapida
1. Drag & drop invariato
2. Resize invariato
3. Scroll sync invariato
4. Testi con `context.l10n`
5. `ref.watch()` per UI, `ref.read()` per azioni
6. API async (`Future<T>`) nei repository
