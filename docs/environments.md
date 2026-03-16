# Agenda Platform Environments

Monorepo: stesso codicebase per `agenda_frontend`, `agenda_backend`, `agenda_core`.

Ambienti ufficiali:

- `local`
- `demo`
- `staging`
- `production`

Principio: differenze ambiente centralizzate in config/policy, non in fork di progetto.

## Documentazione per progetto

- Backend gestionale: `agenda_backend/docs/environments.md`
- Frontend clienti: `agenda_frontend/docs/environments.md`
- API core: `agenda_core/docs/environments.md`

## Regole sicurezza demo

- DB demo separato da production
- endpoint/API demo separati
- flag reali sensibili disabilitati
- blocchi policy lato server in `agenda_core`
