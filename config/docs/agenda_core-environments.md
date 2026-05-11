# Environments (agenda_core)

`agenda_core` usa configurazione ambiente centralizzata server-side:

- `src/Infrastructure/Environment/AppEnvironment.php`
- `src/Infrastructure/Environment/EnvironmentConfig.php`
- `src/Infrastructure/Environment/EnvironmentPolicy.php`

## Ambienti supportati

- `local`
- `demo`
- `staging`
- `production`

## Variabili principali

- `APP_ENV`
- `API_BASE_URL`
- `FRONTEND_URL`
- `DB_HOST`
- `DB_PORT`
- `DB_DATABASE`
- `DB_USERNAME`
- `DB_PASSWORD`
- `CORS_ALLOWED_ORIGINS`
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

## Bootstrap/validazione

`public/index.php` chiama `EnvironmentConfig::bootstrap()` e fallisce in modo esplicito se la configurazione è incoerente.

Controlli principali:

- `APP_ENV` valido
- URL API/WEB validi
- in `demo`: flag sensibili obbligatoriamente `false`
- in `demo`: banner demo obbligatorio
- in `demo`: API non può puntare a `https://api.romeolab.it`
- in `demo`: DB deve essere separato dal DB default/production
- in `staging`: `ALLOW_REAL_EMAILS`, `ALLOW_REAL_WHATSAPP`, `ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS`, `ALLOW_REAL_EXPORTS` obbligatoriamente `false`
- in `staging`: `ALLOW_REAL_PAYMENTS=true` consentito solo con `STRIPE_ONLINE_PAYMENTS_SECRET_KEY` che inizia con `sk_test_`
- in `staging`: `STRIPE_CONNECT_WEBHOOK_SECRET` deve iniziare con `whsec_`
- in `staging`: URL non devono puntare ai domini production
- in `staging`: DB deve essere separato dal DB production

## Risposta blocco demo

Per azioni non consentite in demo, usare `Response::demoBlocked(...)`:

- HTTP `403`
- codice `demo_blocked`
- payload con `demo_blocked = true`
