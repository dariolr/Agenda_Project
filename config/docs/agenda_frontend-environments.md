# Environments (agenda_frontend)

Il frontend prenotazioni supporta `local`, `demo`, `staging`, `production` con config centralizzata in `lib/core/environment/`.

## Variabili

- `APP_ENV`
- `API_BASE_URL`
- `FRONTEND_URL`
- `DEMO_MODE`
- `SHOW_DEMO_BANNER`
- `DEMO_RESET_EXPECTED`
- `DEMO_AUTO_LOGIN_ENABLED`
- `ALLOW_REAL_PAYMENTS`
- `ALLOW_EXTERNAL_WEBHOOKS`
- `ALLOW_REAL_EXPORTS`

## Bootstrap

`main.dart` chiama `AppEnvironmentConfig.bootstrap()` all'avvio e valida coerenza ambiente.

## Demo safety

In `demo`:

- blocco su flag sensibili reali (`ALLOW_*`)
- banner demo obbligatorio
- API demo obbligatoria (no `https://api.romeolab.it`)

In `staging`:

- `ALLOW_REAL_EXPORTS` deve essere `false`
- `DEMO_MODE` deve essere `false`
- URL non devono puntare ai domini production

## Build staging

```bash
flutter build web --release --no-tree-shake-icons \
  --dart-define=APP_ENV=staging \
  --dart-define=DEMO_MODE=false \
  --dart-define=API_BASE_URL=https://staging-api.romeolab.it \
  --dart-define=FRONTEND_URL=https://staging-prenota.romeolab.it \
  --dart-define=ALLOW_REAL_PAYMENTS=true \
  --dart-define=ALLOW_EXTERNAL_WEBHOOKS=true \
  --dart-define=ALLOW_REAL_EXPORTS=false \
  --dart-define=SHOW_DEMO_BANNER=false
```

## Build demo

```bash
flutter build web --release --no-tree-shake-icons \
  --dart-define=APP_ENV=demo \
  --dart-define=DEMO_MODE=true \
  --dart-define=API_BASE_URL=https://demo-api.romeolab.it \
  --dart-define=FRONTEND_URL=https://demo-prenota.romeolab.it \
  --dart-define=ALLOW_REAL_PAYMENTS=false \
  --dart-define=ALLOW_EXTERNAL_WEBHOOKS=false \
  --dart-define=ALLOW_REAL_EXPORTS=false \
  --dart-define=SHOW_DEMO_BANNER=true \
  --dart-define=DEMO_RESET_EXPECTED=true
```
