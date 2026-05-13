#!/usr/bin/env bash
set -euo pipefail

if [[ "${APP_ENV:-}" != "staging" ]]; then
  echo "ERROR: APP_ENV must be staging"
  exit 1
fi

# DEMO_MODE deve essere false in staging
if [[ "${DEMO_MODE:-false}" == "true" ]]; then
  echo "ERROR: DEMO_MODE must be false in staging"
  exit 1
fi

# ALLOW_REAL_EXPORTS deve essere false in staging
if [[ "${ALLOW_REAL_EXPORTS:-false}" == "true" ]]; then
  echo "ERROR: ALLOW_REAL_EXPORTS must be false in staging"
  exit 1
fi

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

echo "OK: frontend staging environment flags are safe"
