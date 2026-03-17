# Demo Environment

## Scopo

La demo usa lo stesso codice di `agenda_backend`, ma con configurazione ambiente dedicata (`APP_ENV=demo`) e API/DB demo lato `agenda_core`.

## Cosa viene bloccato in demo

Nel layer policy (`EnvironmentPolicy`) le capability sensibili devono risultare disabilitate:

- invio email reali
- invio WhatsApp reali
- pagamenti reali
- webhook esterni reali
- azioni distruttive business
- cambi piano
- export reali

In questo repo è stato aggiunto un blocco UI coerente su invito operatore (niente invio email se policy lo vieta).

## Indicatori UX demo

In demo compare un banner persistente globale con avviso:

- ambiente demo
- reset periodico dei dati

## Seed/reset demo

Questo repository non gestisce il database.

- Seed e reset DB demo sono responsabilità di `agenda_core`.
- Qui sono disponibili script wrapper:
  - `config/scripts/demo/verify_demo_env_backend.sh`
  - `config/scripts/demo/prepare_demo_backend.sh`
  - `config/scripts/demo/reset_demo_backend.sh`

## Verifica sicurezza demo

```bash
APP_ENV=demo \
API_BASE_URL=https://demo-api.romeolab.it \
SHOW_DEMO_BANNER=true \
ALLOW_REAL_EMAILS=false \
ALLOW_REAL_WHATSAPP=false \
ALLOW_REAL_PAYMENTS=false \
ALLOW_EXTERNAL_WEBHOOKS=false \
ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS=false \
ALLOW_PLAN_CHANGES=false \
./config/scripts/demo/verify_demo_env_backend.sh
```

## Deploy demo

1. Build web con dart-define demo (vedi `config/docs/agenda_backend-environments.md`).
2. Deploy artefatto su host demo.
3. Verifica banner demo e API endpoint demo.
4. Esegui checklist sicurezza policy lato server in `agenda_core`.
