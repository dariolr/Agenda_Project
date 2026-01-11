#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PROJECTS_ROOT="$(cd -- "$ROOT_DIR/.." && pwd)"

frontend_deploy="$PROJECTS_ROOT/agenda_frontend/scripts/deploy.sh"
backend_deploy="$PROJECTS_ROOT/agenda_backend/scripts/deploy.sh"
core_deploy="$ROOT_DIR/scripts/deploy.sh"

if [[ ! -x "$frontend_deploy" ]]; then
  echo "Errore: script non eseguibile o mancante: $frontend_deploy" >&2
  exit 1
fi
if [[ ! -x "$backend_deploy" ]]; then
  echo "Errore: script non eseguibile o mancante: $backend_deploy" >&2
  exit 1
fi
if [[ ! -x "$core_deploy" ]]; then
  echo "Errore: script non eseguibile o mancante: $core_deploy" >&2
  exit 1
fi

echo "Deploy agenda_frontend..."
"$frontend_deploy"

echo "Deploy agenda_backend..."
"$backend_deploy"

echo "Deploy agenda_core..."
"$core_deploy"
