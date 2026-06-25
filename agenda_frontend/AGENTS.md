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

- Documento canonico: `../config/docs/STAFF_PLANNING_MODEL.md`

## Documentazione Progetto Centralizzata

- Cartella regole agenti: `../config/agents/agenda_frontend/`
- Cartella documentazione canonica: `../config/docs/`

## Checklist

1. `context.l10n` per i testi
2. Provider senza loop infiniti
3. Flusso booking coerente (servizi/staff/data)

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
