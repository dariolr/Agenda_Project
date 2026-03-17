#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

"$SCRIPT_DIR/verify_demo_env_core.sh"

if ! command -v mysql >/dev/null 2>&1; then
  echo "ERROR: mysql client not found"
  exit 1
fi

RESET_SQL="$REPO_ROOT/scripts/reset_local_db.sql"
if [[ ! -f "$RESET_SQL" ]]; then
  echo "ERROR: missing reset script $RESET_SQL"
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

echo "[demo] resetting mutable data in $DB_DATABASE"
"${MYSQL_CMD[@]}" "$DB_DATABASE" < "$RESET_SQL"

echo "[demo] reset completed"

if [[ -f "$REPO_ROOT/config/migrations/seed_data.sql" ]]; then
  echo "[demo] re-seeding dataset"
  "$SCRIPT_DIR/seed_demo_core.sh"
else
  echo "[demo] WARNING: config/migrations/seed_data.sql not found, seed skipped"
fi
