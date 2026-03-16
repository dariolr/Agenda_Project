# Environment Configuration

`agenda_backend` usa un modello ambiente centralizzato in `lib/core/environment/`.

## Ambienti supportati

- `local`
- `demo`
- `staging`
- `production`

## Variabili supportate

- `APP_ENV` (`local|demo|staging|production`)
- `DEMO_MODE`
- `API_BASE_URL`
- `WEB_BASE_URL`
- `ALLOW_REAL_EMAILS`
- `ALLOW_REAL_WHATSAPP`
- `ALLOW_REAL_PAYMENTS`
- `ALLOW_EXTERNAL_WEBHOOKS`
- `ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS`
- `ALLOW_PLAN_CHANGES`
- `ALLOW_REAL_EXPORTS`
- `SHOW_DEMO_BANNER`
- `DEMO_RESET_EXPECTED`
- `DEMO_AUTO_LOGIN_ENABLED`

## Bootstrap e validazione

L'app esegue bootstrap in `main.dart` con `AppEnvironmentConfig.bootstrap()`.

Controlli fail-fast:

- `APP_ENV` deve essere valido.
- `API_BASE_URL` e `WEB_BASE_URL` devono essere URL validi.
- In `demo`, i flag reali/sensibili devono essere `false`.
- In `demo`, `SHOW_DEMO_BANNER` deve essere `true`.
- In `demo`, `API_BASE_URL` non può essere `https://api.romeolab.it`.
- `DEMO_MODE` deve essere coerente con `APP_ENV`.

## Accesso centralizzato

- Config: `AppEnvironmentConfig.current`
- Policy: `EnvironmentPolicy`
- Provider Riverpod:
  - `appEnvironmentConfigProvider`
  - `environmentPolicyProvider`

Regola: evitare lettura diretta e sparsa di `String.fromEnvironment` nei moduli feature.

## Build examples

Demo:

```bash
flutter build web --release --no-tree-shake-icons \
  --dart-define=APP_ENV=demo \
  --dart-define=DEMO_MODE=true \
  --dart-define=API_BASE_URL=https://demo-api.romeolab.it \
  --dart-define=WEB_BASE_URL=https://demo-gestionale.romeolab.it \
  --dart-define=ALLOW_REAL_EMAILS=false \
  --dart-define=ALLOW_REAL_WHATSAPP=false \
  --dart-define=ALLOW_REAL_PAYMENTS=false \
  --dart-define=ALLOW_EXTERNAL_WEBHOOKS=false \
  --dart-define=ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS=false \
  --dart-define=ALLOW_PLAN_CHANGES=false \
  --dart-define=ALLOW_REAL_EXPORTS=false \
  --dart-define=SHOW_DEMO_BANNER=true \
  --dart-define=DEMO_RESET_EXPECTED=true
```

Production:

```bash
flutter build web --release --no-tree-shake-icons \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.romeolab.it \
  --dart-define=WEB_BASE_URL=https://gestionale.romeolab.it
```
