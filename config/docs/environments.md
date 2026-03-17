# Agenda Platform Environments

Monorepo: stesso codicebase per `agenda_frontend`, `agenda_backend`, `agenda_core`.

Ambienti ufficiali:

- `local`
- `demo`
- `production`

Principio: differenze ambiente centralizzate in config/policy, non in fork di progetto.

## Cartelle monorepo dedicate

- `config/environments/{local,demo,production}`
- `database/{migrations,seeds,demo}`
- `config/scripts/deploy`
- `config/scripts/db`

I template ambiente centralizzati sono in `config/environments/`:

- `agenda_backend.env`
- `agenda_frontend.env`
- `agenda_core.env`

## Documentazione per progetto

- Backend gestionale: `config/docs/agenda_backend-environments.md`
- Frontend clienti: `config/docs/agenda_frontend-environments.md`
- API core: `config/docs/agenda_core-environments.md`

## Regole sicurezza demo

- DB demo separato da production
- endpoint/API demo separati
- flag reali sensibili disabilitati
- blocchi policy lato server in `agenda_core`

## Script wrapper monorepo

- deploy backend web con env: `config/scripts/deploy/deploy_backend.sh <demo|production>`
- deploy frontend web con env: `config/scripts/deploy/deploy_frontend.sh <demo|production>`
- deploy core API con env: `config/scripts/deploy/deploy_core.sh <demo|production>`
- prepare demo DB core: `config/scripts/db/core_prepare_demo.sh`
- seed demo DB core: `config/scripts/db/core_seed_demo.sh`
- reset demo DB core: `config/scripts/db/core_reset_demo.sh`
