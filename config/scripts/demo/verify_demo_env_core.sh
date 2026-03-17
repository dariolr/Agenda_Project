#!/usr/bin/env bash
set -euo pipefail

if [[ "${APP_ENV:-}" != "demo" ]]; then
  echo "ERROR: APP_ENV must be demo"
  exit 1
fi

required_false=(
  ALLOW_REAL_EMAILS
  ALLOW_REAL_WHATSAPP
  ALLOW_REAL_PAYMENTS
  ALLOW_EXTERNAL_WEBHOOKS
  ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS
  ALLOW_PLAN_CHANGES
  ALLOW_REAL_EXPORTS
)

for key in "${required_false[@]}"; do
  if [[ "${!key:-false}" == "true" ]]; then
    echo "ERROR: $key must be false in demo"
    exit 1
  fi
done

if [[ "${SHOW_DEMO_BANNER:-true}" != "true" ]]; then
  echo "ERROR: SHOW_DEMO_BANNER must be true in demo"
  exit 1
fi

if [[ "${API_BASE_URL:-}" == "https://api.romeolab.it" ]]; then
  echo "ERROR: API_BASE_URL points to production endpoint"
  exit 1
fi

if [[ -z "${DB_DATABASE:-}" || "${DB_DATABASE}" == "agenda_core" || "${DB_DATABASE}" == "agenda_production" || "${DB_DATABASE}" == "agenda_prod" ]]; then
  echo "ERROR: DB_DATABASE must point to dedicated demo database"
  exit 1
fi

echo "OK: core demo environment flags are safe"
