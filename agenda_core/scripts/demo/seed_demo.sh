#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

"$SCRIPT_DIR/verify_demo_env.sh"

if ! command -v mysql >/dev/null 2>&1; then
  echo "ERROR: mysql client not found"
  exit 1
fi

SEED_FILE="$REPO_ROOT/migrations/seed_data.sql"
if [[ ! -f "$SEED_FILE" ]]; then
  echo "ERROR: missing seed file $SEED_FILE"
  echo "Create migrations/seed_data.sql with demo dataset before running seed."
  exit 1
fi

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_DATABASE="${DB_DATABASE:-}"
DB_USERNAME="${DB_USERNAME:-}"
DB_PASSWORD="${DB_PASSWORD:-}"

if [[ -z "$DB_DATABASE" || -z "$DB_USERNAME" ]]; then
  echo "ERROR: DB_DATABASE and DB_USERNAME are required"
  exit 1
fi

MYSQL_CMD=(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME")
if [[ -n "$DB_PASSWORD" ]]; then
  MYSQL_CMD+=("-p$DB_PASSWORD")
fi

echo "[demo] applying seed to $DB_DATABASE"
"${MYSQL_CMD[@]}" "$DB_DATABASE" < "$SEED_FILE"

echo "[demo] seed applied"
