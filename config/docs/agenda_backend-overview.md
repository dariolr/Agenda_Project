# agenda_backend

Gestionale multi-staff Flutter per la piattaforma Agenda.

Applicazione desktop/web per la gestione di appuntamenti, clienti, servizi e staff.

## Stack

- Flutter 3.35+ (web primary, desktop ready)
- Riverpod 3.x — state management
- go_router 16.x — navigation
- API REST: agenda_core (PHP)

## Architettura

```
lib/
├── app/          # Router, theme, providers globali
├── core/
│   ├── l10n/     # Localizzazione IT/EN
│   ├── models/   # Domain models condivisi
│   ├── network/  # ApiClient, error handling
│   └── widgets/  # Widget riutilizzabili
└── features/
    ├── agenda/   # Calendario (FEATURE PRINCIPALE)
    ├── clients/
    ├── services/
    ├── staff/
    └── business/
```

## Comandi base

```bash
# Dipendenze
flutter pub get

# Code generation (dopo @riverpod)
dart run build_runner build --delete-conflicting-outputs

# Localizzazione (dopo .arb)
dart run intl_utils:generate

# Run (local)
flutter run -d chrome

# Build produzione
flutter build web --release --no-tree-shake-icons
```

Configurazione ambienti (`--dart-define`): `config/docs/agenda_backend-environments.md`

## Note critiche

- Timezone: usare timezone location/business, mai browser. Provider: `effectiveTenantTimezoneProvider`, `tenantNowProvider`, `tenantTodayProvider`. Dettagli: `config/docs/agenda_backend-timezone-location-policy.md`.
- Calendario: non modificare `dragSessionProvider`, `resizingProvider`, `agendaScrollProvider`, `bookingsProvider` senza task esplicito.
- Nessun ripple/splash effect.
- Nessun mock nei provider di produzione.

## Regole agente

- `config/agents/agenda_backend/PROJECT_RULES.md`
- `config/agents/agenda_backend/AGENDA_RULES.md`
- `config/agents/agenda_backend/TIMEZONE_RULES.md`
- `config/agents/agenda_backend/RIVERPOD_RULES.md`
- `config/agents/agenda_backend/UI_RULES.md`

## Documentazione correlata

- `config/docs/agenda_backend-environments.md` — configurazione ambienti
- `config/docs/agenda_backend-demo-environment.md` — ambiente demo
- `config/docs/agenda_backend-timezone-location-policy.md` — policy timezone
- `config/docs/api_contract_v1.md` — contratto API
