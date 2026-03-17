# Demo Environment (agenda_core)

## Obiettivo

La demo usa lo stesso codice API con policy ambiente dedicate per bloccare operazioni sensibili reali.

## Blocchi server-side attivi

- invio email reale (inviti/operatori e servizi email)
- create/update/delete business admin
- export/import business sync
- sync da produzione

Le risposte bloccate sono standardizzate con `demo_blocked`.

## Sicurezza dati demo

In `APP_ENV=demo` la bootstrap validation richiede:

- endpoint API demo (no production)
- DB demo separato
- flag reali/sensibili disattivi

## Verifica rapida

```bash
APP_ENV=demo \
API_BASE_URL=https://demo-api.romeolab.it \
WEB_BASE_URL=https://demo-gestionale.romeolab.it \
SHOW_DEMO_BANNER=true \
ALLOW_REAL_EMAILS=false \
ALLOW_REAL_WHATSAPP=false \
ALLOW_REAL_PAYMENTS=false \
ALLOW_EXTERNAL_WEBHOOKS=false \
ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS=false \
ALLOW_PLAN_CHANGES=false \
ALLOW_REAL_EXPORTS=false \
DB_DATABASE=agenda_demo \
./config/scripts/demo/verify_demo_env_core.sh
```

## Script operativi demo

- `config/scripts/demo/prepare_demo_core.sh`  
  Applica schema DB demo (`config/migrations/FULL_DATABASE_SCHEMA.sql`).
- `config/scripts/demo/seed_demo_core.sh`  
  Applica seed demo (`config/migrations/seed_data.sql`, se presente).
- `config/scripts/demo/reset_demo_core.sh`  
  Reset dati mutabili e reseed.
- `config/scripts/demo/verify_demo_env_core.sh`  
  Verifica coerenza/sicurezza flag demo.

## Copertura policy endpoint

Matrice aggiornata: `config/docs/agenda_core-demo-policy-matrix.md`.
