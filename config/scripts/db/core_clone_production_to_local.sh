#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

LOCAL_ENV_FILE="$ROOT_DIR/config/environments/local/agenda_core.env"
PROD_ENV_FILE="$ROOT_DIR/config/environments/production/agenda_core.env"
SSH_ALIAS=""
REMOTE_ENV_FILE=""
ASSUME_YES=0

usage() {
  cat <<'USAGE'
Uso:
  ./config/scripts/db/core_clone_production_to_local.sh [opzioni]

Opzioni:
  --yes                      Salta conferma interattiva
  --ssh-alias <alias>        Alias SSH remoto (default: da DEPLOY_SSH_ALIAS o "romeolab")
  --remote-env-file <path>   Path del file .env remoto (default: <REMOTE_BASE>/.env)
  --local-env-file <path>    Override env locale (default: config/environments/local/agenda_core.env)
  --prod-env-file <path>     Override env produzione (default: config/environments/production/agenda_core.env)
  -h, --help                 Mostra questo help

Note:
  - Operazione distruttiva: DROP DATABASE locale + import completo da produzione.
  - Richiede SSH access al server produzione e mysqldump disponibile sul server remoto.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      ASSUME_YES=1
      shift
      ;;
    --ssh-alias)
      SSH_ALIAS="${2:-}"
      shift 2
      ;;
    --remote-env-file)
      REMOTE_ENV_FILE="${2:-}"
      shift 2
      ;;
    --local-env-file)
      LOCAL_ENV_FILE="${2:-}"
      shift 2
      ;;
    --prod-env-file)
      PROD_ENV_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: opzione non riconosciuta: $1" >&2
      usage
      exit 1
      ;;
  esac
done

for cmd in ssh mysql; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: comando richiesto non trovato: $cmd" >&2
    exit 1
  fi
done

if [[ ! -f "$LOCAL_ENV_FILE" ]]; then
  echo "ERROR: file env locale non trovato: $LOCAL_ENV_FILE" >&2
  exit 1
fi

if [[ ! -f "$PROD_ENV_FILE" ]]; then
  echo "ERROR: file env produzione non trovato: $PROD_ENV_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$LOCAL_ENV_FILE"

LOCAL_DB_HOST="${DB_HOST:-127.0.0.1}"
LOCAL_DB_PORT="${DB_PORT:-3306}"
LOCAL_DB_NAME="${DB_DATABASE:-}"
LOCAL_DB_USER="${DB_USERNAME:-}"
LOCAL_DB_PASS="${DB_PASSWORD:-}"

if [[ -z "$LOCAL_DB_NAME" || -z "$LOCAL_DB_USER" ]]; then
  echo "ERROR: env locale incompleto (DB_DATABASE/DB_USERNAME obbligatori)" >&2
  exit 1
fi

if [[ "$LOCAL_DB_NAME" =~ prod|production ]]; then
  echo "ERROR: target locale sembra un DB di produzione: $LOCAL_DB_NAME" >&2
  exit 1
fi

if [[ "$LOCAL_DB_HOST" != "127.0.0.1" && "$LOCAL_DB_HOST" != "localhost" ]]; then
  echo "ERROR: DB locale deve puntare a localhost/127.0.0.1 (attuale: $LOCAL_DB_HOST)" >&2
  exit 1
fi

REMOTE_BASE=""
PROD_API_BASE_URL=""
while IFS='=' read -r key value; do
  [[ -z "${key// }" ]] && continue
  [[ "$key" == \#* ]] && continue
  case "$key" in
    DEPLOY_REMOTE_BASE) REMOTE_BASE="$value" ;;
    DEPLOY_SSH_ALIAS) [[ -z "$SSH_ALIAS" ]] && SSH_ALIAS="$value" ;;
    API_BASE_URL) PROD_API_BASE_URL="$value" ;;
  esac
done < "$PROD_ENV_FILE"

if [[ -z "$SSH_ALIAS" ]]; then
  SSH_ALIAS="romeolab"
fi

if [[ -z "$REMOTE_BASE" ]]; then
  prod_host="${PROD_API_BASE_URL#*://}"
  prod_host="${prod_host%%/*}"
  if [[ -z "$prod_host" || "$prod_host" == "localhost"* || "$prod_host" == "127.0.0.1"* ]]; then
    echo "ERROR: impossibile derivare REMOTE_BASE da API_BASE_URL=$PROD_API_BASE_URL" >&2
    echo "Imposta DEPLOY_REMOTE_BASE in $PROD_ENV_FILE oppure passa --remote-env-file" >&2
    exit 1
  fi
  REMOTE_BASE="www/$prod_host"
fi

if [[ -z "$REMOTE_ENV_FILE" ]]; then
  REMOTE_ENV_FILE="$REMOTE_BASE/.env"
fi

echo "[clone] sorgente produzione via SSH: $SSH_ALIAS"
echo "[clone] env remoto: $REMOTE_ENV_FILE"
echo "[clone] target locale: $LOCAL_DB_USER@$LOCAL_DB_HOST:$LOCAL_DB_PORT/$LOCAL_DB_NAME"

if [[ "$ASSUME_YES" -ne 1 ]]; then
  echo ""
  echo "ATTENZIONE: il DB locale '$LOCAL_DB_NAME' verra' ELIMINATO e ricreato da produzione."
  read -r -p "Digita CLONE_PRODUCTION per continuare: " confirmation
  if [[ "$confirmation" != "CLONE_PRODUCTION" ]]; then
    echo "Operazione annullata"
    exit 1
  fi
fi

MYSQL_BASE=(mysql -h "$LOCAL_DB_HOST" -P "$LOCAL_DB_PORT" -u "$LOCAL_DB_USER" --default-character-set=utf8mb4)
if [[ -n "$LOCAL_DB_PASS" ]]; then
  MYSQL_BASE+=("-p$LOCAL_DB_PASS")
fi

echo "[clone] reset database locale"
"${MYSQL_BASE[@]}" -e "DROP DATABASE IF EXISTS \`$LOCAL_DB_NAME\`; CREATE DATABASE \`$LOCAL_DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

REMOTE_DUMP_CMD=$(cat <<REMOTE
set -euo pipefail
if ! command -v mysqldump >/dev/null 2>&1; then
  echo "ERROR: mysqldump non trovato sul server remoto" >&2
  exit 1
fi
if [[ ! -f "$REMOTE_ENV_FILE" ]]; then
  echo "ERROR: file env remoto non trovato: $REMOTE_ENV_FILE" >&2
  exit 1
fi
set -a
source "$REMOTE_ENV_FILE"
set +a
PROD_DB_HOST="\${DB_HOST:-127.0.0.1}"
PROD_DB_PORT="\${DB_PORT:-3306}"
PROD_DB_NAME="\${DB_DATABASE:-\${DB_NAME:-}}"
PROD_DB_USER="\${DB_USERNAME:-\${DB_USER:-}}"
PROD_DB_PASS="\${DB_PASSWORD:-\${DB_PASS:-}}"
if [[ -z "\$PROD_DB_NAME" || -z "\$PROD_DB_USER" ]]; then
  echo "ERROR: variabili DB mancanti nel file env remoto ($REMOTE_ENV_FILE)" >&2
  exit 1
fi
MYSQL_PWD="\$PROD_DB_PASS" mysqldump \
  -h "\$PROD_DB_HOST" \
  -P "\$PROD_DB_PORT" \
  -u "\$PROD_DB_USER" \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --default-character-set=utf8mb4 \
  "\$PROD_DB_NAME"
REMOTE
)

echo "[clone] dump produzione -> import locale (stream)"
ssh "$SSH_ALIAS" "bash -lc $(printf '%q' "$REMOTE_DUMP_CMD")" | "${MYSQL_BASE[@]}" "$LOCAL_DB_NAME"

echo "[clone] completato con successo"
