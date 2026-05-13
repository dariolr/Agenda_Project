# Staging Environment

## Scopo

L'ambiente `staging` è il quarto ambiente ufficiale del monorepo, separato da `local`, `demo` e `production`.

Serve per test reali controllati dei pagamenti Stripe in test mode, senza rischiare dati o transazioni reali.

Differenze principali rispetto a `demo`:

| Flag                              | demo  | staging |
|-----------------------------------|-------|---------|
| `ALLOW_REAL_EMAILS`               | false | false   |
| `ALLOW_REAL_WHATSAPP`             | false | false   |
| `ALLOW_REAL_PAYMENTS`             | false | **true** (solo sk_test_) |
| `ALLOW_EXTERNAL_WEBHOOKS`         | false | **true** |
| `ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS` | false | false |
| `ALLOW_REAL_EXPORTS`              | false | false   |
| `SHOW_DEMO_BANNER`                | true  | false   |
| Stripe key                        | vuota | sk_test_... |

## Setup

### 1. Copia i template

```bash
cp config/environments/staging/agenda_core.env agenda_core/.env
cp config/environments/staging/agenda_backend.env agenda_backend/.env.staging
cp config/environments/staging/agenda_frontend.env agenda_frontend/.env.staging
```

### 2. Popola i placeholder `__SET_ME__` in `agenda_core/.env`

Valori obbligatori:

- `DB_PASSWORD` — password del DB staging
- `STRIPE_ONLINE_PAYMENTS_SECRET_KEY` — chiave Stripe test mode (`sk_test_...`)
- `STRIPE_CONNECT_CLIENT_ID` — client ID Stripe Connect test
- `STRIPE_CONNECT_WEBHOOK_SECRET` — secret webhook Stripe (`whsec_...`)

### 3. Crea il database staging

```sql
CREATE DATABASE agenda_staging CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'agenda_staging_user'@'localhost' IDENTIFIED BY 'password_staging';
GRANT ALL PRIVILEGES ON agenda_staging.* TO 'agenda_staging_user'@'localhost';
FLUSH PRIVILEGES;
```

### 4. Esegui le migrazioni

```bash
cd agenda_core
php bin/migrate.php
```

### 5. Configura il webhook Stripe in test mode

Nel dashboard Stripe test, crea un webhook endpoint:

- URL: `https://staging-api.romeolab.it/v1/online-payments/stripe/webhook`
- Evento: `checkout.session.completed`, `checkout.session.expired`
- Copia il `whsec_...` in `STRIPE_CONNECT_WEBHOOK_SECRET`

## Deploy

```bash
# Core API
config/scripts/deploy/deploy_core.sh staging

# Backend gestionale
config/scripts/deploy/deploy_backend.sh staging

# Frontend prenotazioni
config/scripts/deploy/deploy_frontend.sh staging
```

Oppure tramite i task VSCode:

- "Deploy agenda_core (staging)"
- "Deploy agenda_backend (staging)"
- "Deploy agenda_frontend (staging)"

## Test pagamento con carta Stripe test

Usa la carta di test Stripe:

- **Numero**: `4242 4242 4242 4242`
- **Scadenza**: qualsiasi data futura (es. `12/34`)
- **CVC**: qualsiasi 3 cifre (es. `123`)
- **CAP**: qualsiasi (es. `00000`)

### Flusso completo

1. Crea un business in staging con Stripe Connect attivo (onboarding con account test).
2. Configura almeno un servizio con `online_payment_required = true` e un prezzo > 0.
3. Apri `https://staging-prenota.romeolab.it/{slug}` e completa una prenotazione.
4. Verifica che il frontend mostri il badge "Pagamento online richiesto".
5. Dopo il submit, il frontend deve redirigere a Stripe Checkout.
6. Inserisci la carta `4242 4242 4242 4242` e completa il pagamento.
7. Verifica il redirect a `/{slug}/payment-result?status=success`.
8. Verifica che il booking sia `confirmed` e il payment sia `paid`.

### Test cancel/retry

1. Vai al checkout Stripe e clicca "Torna indietro".
2. Il frontend mostra "Pagamento non completato" con pulsante "Riprova".
3. Verifica che booking sia ancora `pending_payment` e payment `pending`.
4. Clicca "Riprova" e completa il pagamento.

## Verifica variabili critiche

```bash
# Carica .env e verifica
source agenda_core/.env
bash config/scripts/demo/verify_staging_env_core.sh

source agenda_backend/.env.staging
bash config/scripts/demo/verify_staging_env_backend.sh

source agenda_frontend/.env.staging
bash config/scripts/demo/verify_staging_env_frontend.sh
```

## Query SQL di verifica

### Verifica pagamenti pending scaduti

```sql
SELECT id, booking_id, class_booking_id, status, provider_checkout_id, expires_at, created_at
FROM online_booking_payments
WHERE status = 'pending'
  AND expires_at < NOW()
ORDER BY expires_at DESC
LIMIT 20;
```

### Verifica pagamenti completati nelle ultime 24h

```sql
SELECT obp.id, obp.status, obp.amount_cents, obp.currency,
       b.status AS booking_status, obp.created_at, obp.updated_at
FROM online_booking_payments obp
LEFT JOIN bookings b ON b.id = obp.booking_id
WHERE obp.status = 'paid'
  AND obp.updated_at >= NOW() - INTERVAL 24 HOUR
ORDER BY obp.updated_at DESC;
```

### Verifica booking in pending_payment orfani (senza payment)

```sql
SELECT b.id, b.status, b.created_at
FROM bookings b
LEFT JOIN online_booking_payments obp ON obp.booking_id = b.id
WHERE b.status = 'pending_payment'
  AND obp.id IS NULL;
```

### Verifica eventi webhook ricevuti

```sql
SELECT id, provider, event_type, provider_event_id, processed_at, created_at
FROM online_payment_provider_events
ORDER BY created_at DESC
LIMIT 20;
```

### Verifica account Stripe Connect del business

```sql
SELECT business_id, provider_code, provider_account_id, onboarding_complete,
       charges_enabled, payouts_enabled, created_at, updated_at
FROM business_online_payment_accounts
WHERE provider_code = 'stripe'
ORDER BY updated_at DESC;
```

## Policy di sicurezza staging

- `ALLOW_REAL_EMAILS=false` — nessuna email reale inviata
- `ALLOW_REAL_WHATSAPP=false` — nessun messaggio WhatsApp reale
- `ALLOW_REAL_PAYMENTS=true` — pagamenti attivi, **solo con `sk_test_`**
- `ALLOW_EXTERNAL_WEBHOOKS=true` — webhook Stripe ricevuti
- `ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS=false` — no cancellazioni business/location
- `ALLOW_REAL_EXPORTS=false` — no export reali
- `STRIPE_ONLINE_PAYMENTS_SECRET_KEY` deve iniziare con `sk_test_` (mai `sk_live_`)
- `STRIPE_CONNECT_WEBHOOK_SECRET` deve iniziare con `whsec_`
- DB staging (`agenda_staging`) separato dal DB production (`agenda_production`)
- URL staging non devono mai puntare ai domini production

## Differenze da demo

La demo blocca i pagamenti a livello di policy (`ALLOW_REAL_PAYMENTS=false`) e risponde `demo_blocked` a qualsiasi tentativo di checkout. Lo staging invece esegue checkout reali Stripe in test mode — i fondi non vengono addebitati realmente ma tutti i webhook, stati e record DB vengono scritti esattamente come in production.
