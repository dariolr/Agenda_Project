# Agenda Frontend (Prenotazioni Clienti) — AGENTS

## Identificazione Progetto
- Progetto: `agenda_frontend`
- Scopo: prenotazioni online clienti
- Produzione: `https://prenota.romeolab.it`
- Deploy path: `www/prenota.romeolab.it/public_html/`
- Non confondere con `agenda_backend` (`https://gestionale.romeolab.it`)

## Regole Critiche
1. Non eseguire deploy produzione senza richiesta esplicita.
2. Non avviare `flutter run` senza richiesta esplicita.
3. Non usare `SnackBar`: usare `FeedbackDialog`.
4. Non usare `StateProvider` per stato mutabile: usare `Notifier`.

## Terminologia e DB
- `frontend` = agenda_frontend
- `backend` = agenda_backend
- `core` = agenda_core API
- Tabella principale prenotazioni: `bookings` (non `appointments`)

## Comandi
```bash
dart run intl_utils:generate
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build web --release --no-tree-shake-icons
flutter test
```

## Qualità
- `flutter analyze` dopo modifiche
- warning/info/error da risolvere (eccetto TODO)

## Routing (chiave)
- URL path-based con slug: `/:slug/...`
- Non usare resolver statici per slug; usare provider route corrente
- Route protette devono redirect a `/:slug/login` se non autenticato

## Multi-location
- Se più sedi attive: step sede visibile
- Se una sede: step sede saltato

## Source of Truth Staff Planning
- Documento canonico: `docs/STAFF_PLANNING_MODEL.md`

## Checklist
1. `context.l10n` per i testi
2. Provider senza loop infiniti
3. Flusso booking coerente (servizi/staff/data)
