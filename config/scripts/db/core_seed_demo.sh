#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENV_FILE="$ROOT_DIR/config/environments/demo/agenda_core.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: missing env file $ENV_FILE"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

cd "$ROOT_DIR"
./config/scripts/demo/seed_demo_core.sh
