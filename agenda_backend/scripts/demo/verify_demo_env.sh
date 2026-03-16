#!/usr/bin/env bash
set -euo pipefail

if [[ "${APP_ENV:-}" != "demo" ]]; then
  echo "ERROR: APP_ENV must be demo"
  exit 1
fi

if [[ "${ALLOW_REAL_EMAILS:-false}" == "true" ]]; then
  echo "ERROR: ALLOW_REAL_EMAILS must be false in demo"
  exit 1
fi

if [[ "${ALLOW_REAL_WHATSAPP:-false}" == "true" ]]; then
  echo "ERROR: ALLOW_REAL_WHATSAPP must be false in demo"
  exit 1
fi

if [[ "${ALLOW_REAL_PAYMENTS:-false}" == "true" ]]; then
  echo "ERROR: ALLOW_REAL_PAYMENTS must be false in demo"
  exit 1
fi

if [[ "${ALLOW_EXTERNAL_WEBHOOKS:-false}" == "true" ]]; then
  echo "ERROR: ALLOW_EXTERNAL_WEBHOOKS must be false in demo"
  exit 1
fi

if [[ "${ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS:-false}" == "true" ]]; then
  echo "ERROR: ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS must be false in demo"
  exit 1
fi

if [[ "${ALLOW_PLAN_CHANGES:-false}" == "true" ]]; then
  echo "ERROR: ALLOW_PLAN_CHANGES must be false in demo"
  exit 1
fi

if [[ "${SHOW_DEMO_BANNER:-true}" != "true" ]]; then
  echo "ERROR: SHOW_DEMO_BANNER must be true in demo"
  exit 1
fi

if [[ "${API_BASE_URL:-}" == "https://api.romeolab.it" ]]; then
  echo "ERROR: API_BASE_URL points to production endpoint"
  exit 1
fi

echo "OK: demo environment flags are safe"
