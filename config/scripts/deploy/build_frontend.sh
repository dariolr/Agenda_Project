#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${1:-demo}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENV_FILE="$ROOT_DIR/config/environments/$ENV_NAME/agenda_frontend.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: missing env file $ENV_FILE"
  exit 1
fi

DART_DEFINES=()
while IFS='=' read -r key value; do
  [[ -z "${key// }" ]] && continue
  [[ "$key" =~ ^# ]] && continue
  DART_DEFINES+=("--dart-define=${key}=${value}")
done < "$ENV_FILE"

cd "$ROOT_DIR/agenda_frontend"
flutter build web --release --no-tree-shake-icons "${DART_DEFINES[@]}"
