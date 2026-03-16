# Agenda Platform Environments

Monorepo: stesso codicebase per `agenda_frontend`, `agenda_backend`, `agenda_core`.

Ambienti ufficiali:

- `local`
- `demo`
- `staging`
- `production`

Principio: differenze ambiente centralizzate in config/policy, non in fork di progetto.

## Cartelle monorepo dedicate

- `config/environments/{local,demo,staging,production}`
- `database/{migrations,seeds,demo}`
- `scripts/deploy`
- `scripts/db`

I template ambiente centralizzati sono in `config/environments/`:

- `agenda_backend.env`
- `agenda_frontend.env`
- `agenda_core.env`

## Documentazione per progetto

- Backend gestionale: `agenda_backend/docs/environments.md`
- Frontend clienti: `agenda_frontend/docs/environments.md`
- API core: `agenda_core/docs/environments.md`

## Regole sicurezza demo

- DB demo separato da production
- endpoint/API demo separati
- flag reali sensibili disabilitati
- blocchi policy lato server in `agenda_core`

## Script wrapper monorepo

- build backend web con env: `scripts/deploy/build_backend.sh <env>`
- build frontend web con env: `scripts/deploy/build_frontend.sh <env>`
- prepare demo DB core: `scripts/db/core_prepare_demo.sh`
- seed demo DB core: `scripts/db/core_seed_demo.sh`
- reset demo DB core: `scripts/db/core_reset_demo.sh`
