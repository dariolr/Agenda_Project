#!/usr/bin/env bash
set -euo pipefail

if [[ "${APP_ENV:-}" != "staging" ]]; then
  echo "ERROR: APP_ENV must be staging"
  exit 1
fi

# Flags che devono essere false in staging
required_false=(
  ALLOW_REAL_EMAILS
  ALLOW_REAL_WHATSAPP
  ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS
  ALLOW_REAL_EXPORTS
)

for key in "${required_false[@]}"; do
  if [[ "${!key:-false}" == "true" ]]; then
    echo "ERROR: $key must be false in staging"
    exit 1
  fi
done

# URL non devono puntare a production
forbidden_urls=(
  "https://api.romeolab.it"
  "https://prenota.romeolab.it"
  "https://gestionale.romeolab.it"
)

for url in "${forbidden_urls[@]}"; do
  if [[ "${API_BASE_URL:-}" == "$url" || "${FRONTEND_URL:-}" == "$url" ]]; then
    echo "ERROR: URL punta al dominio di production: $url"
    exit 1
  fi
done

# DB non deve essere quello di produzione
db_lower="${DB_DATABASE:-}"
db_lower="${db_lower,,}"
if [[ -z "$db_lower" || "$db_lower" == "agenda_core" || "$db_lower" == "agenda_production" || "$db_lower" == "agenda_prod" ]]; then
  echo "ERROR: DB_DATABASE non puo' essere uguale al DB di produzione (attuale: '${DB_DATABASE:-}')"
  exit 1
fi

# Stripe key deve essere test mode se ALLOW_REAL_PAYMENTS=true
if [[ "${ALLOW_REAL_PAYMENTS:-false}" == "true" ]]; then
  stripe_key="${STRIPE_ONLINE_PAYMENTS_SECRET_KEY:-}"
  if [[ -n "$stripe_key" && "$stripe_key" != sk_test_* ]]; then
    echo "ERROR: STRIPE_ONLINE_PAYMENTS_SECRET_KEY deve iniziare con sk_test_ in staging (trovato: '${stripe_key:0:10}...')"
    exit 1
  fi

  webhook_secret="${STRIPE_CONNECT_WEBHOOK_SECRET:-}"
  if [[ -n "$webhook_secret" && "$webhook_secret" != whsec_* ]]; then
    echo "ERROR: STRIPE_CONNECT_WEBHOOK_SECRET deve iniziare con whsec_ in staging"
    exit 1
  fi

  success_url="${STRIPE_ONLINE_PAYMENT_SUCCESS_URL:-}"
  if [[ -n "$success_url" && "$success_url" != *"{slug}"* ]]; then
    echo "ERROR: STRIPE_ONLINE_PAYMENT_SUCCESS_URL deve contenere {slug} (attuale: '$success_url')"
    exit 1
  fi

  cancel_url="${STRIPE_ONLINE_PAYMENT_CANCEL_URL:-}"
  if [[ -n "$cancel_url" && "$cancel_url" != *"{slug}"* ]]; then
    echo "ERROR: STRIPE_ONLINE_PAYMENT_CANCEL_URL deve contenere {slug} (attuale: '$cancel_url')"
    exit 1
  fi
fi

echo "OK: core staging environment flags are safe"
