#!/bin/bash
# Deploy script per agenda_core su SiteGround
# 
# Uso: ./scripts/deploy.sh
#
# ⚠️  WHITELIST APPROACH: deploya SOLO le cartelle elencate esplicitamente
#
# Struttura target su SiteGround:
#   www/api.romeolab.it/
#   ├── public_html/     ← index.php, .htaccess (da public/)
#   ├── src/             ← codice PHP
#   ├── vendor/          ← composer dependencies
#   └── .env             ← configurazione (NON sovrascrivere!)
#
# ❌ MAI DEPLOYARE: tests/, docs/, config/migrations/, scripts/, bin/, .git/, *.md

set -euo pipefail

# Ambiente deploy (default: production)
ENV_NAME="production"
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      ;;
    demo|production)
      ENV_NAME="$arg"
      ;;
    *)
      echo "ERROR: argomento non valido: $arg" >&2
      echo "Uso: $0 [demo|production] [--dry-run]" >&2
      exit 1
      ;;
  esac
done

# === CONFIGURAZIONE ===
SSH_ALIAS="romeolab"
REMOTE_BASE=""

# Path locale (root agenda_core).
# Caso 1: script dentro agenda_core/scripts (comportamento originario)
# Caso 2: script dentro config/scripts/deploy (questa copia)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ ! -d "$LOCAL_DIR/public" || ! -d "$LOCAL_DIR/src" || ! -d "$LOCAL_DIR/vendor" || ! -d "$LOCAL_DIR/bin" ]]; then
  LOCAL_DIR="$(cd "$SCRIPT_DIR/../../../agenda_core" && pwd)"
fi

MONOREPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ENV_FILE="$MONOREPO_ROOT/config/environments/$ENV_NAME/agenda_core.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: file ambiente non trovato: $ENV_FILE"
  exit 1
fi

API_BASE_URL=""
while IFS='=' read -r key value; do
  [[ -z "${key// }" ]] && continue
  [[ "$key" == \#* ]] && continue

  if [[ "$key" == "API_BASE_URL" ]]; then
    API_BASE_URL="$value"
  fi
  if [[ "$key" == "DEPLOY_REMOTE_BASE" ]]; then
    REMOTE_BASE="$value"
  fi
  if [[ "$key" == "DEPLOY_SSH_ALIAS" ]]; then
    SSH_ALIAS="$value"
  fi
done < "$ENV_FILE"

if [[ -z "$REMOTE_BASE" ]]; then
  api_host="${API_BASE_URL#*://}"
  api_host="${api_host%%/*}"
  if [[ -z "$api_host" || "$api_host" == "localhost"* || "$api_host" == "127.0.0.1"* ]]; then
    echo "ERROR: impossibile derivare REMOTE_BASE da API_BASE_URL=$API_BASE_URL. Imposta DEPLOY_REMOTE_BASE in $ENV_FILE"
    exit 1
  fi
  REMOTE_BASE="www/$api_host"
fi

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %q' "$1"
    shift
    for token in "$@"; do
      printf ' %q' "$token"
    done
    printf '\n'
    return 0
  fi
  "$@"
}

echo "📦 Deploy agenda_core"
echo "   Env: $ENV_NAME"
echo "   Da: $LOCAL_DIR"
echo "   A:  $SSH_ALIAS:$REMOTE_BASE"
echo ""

# === VERIFICA PRE-DEPLOY ===
# Controlla che non esistano cartelle vietate sul server
echo "🔍 Verifica cartelle vietate sul server..."
FORBIDDEN_DIRS="tests docs migrations scripts .git phpunit.xml composer.json"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] salto verifica remota cartelle vietate"
else
  for dir in $FORBIDDEN_DIRS; do
    if run_cmd ssh "$SSH_ALIAS" "test -e $REMOTE_BASE/$dir" 2>/dev/null; then
      echo "⚠️  ATTENZIONE: trovata cartella/file vietato sul server: $dir"
      echo "   Rimuovila manualmente: ssh $SSH_ALIAS 'rm -rf $REMOTE_BASE/$dir'"
    fi
  done
fi
echo ""

# === 1. Deploy public/ → public_html/ ===
echo "🔹 [1/3] Sincronizzando public_html (index.php, .htaccess)..."
run_cmd rsync -avz --delete \
  --exclude='.DS_Store' \
  -e "ssh" \
  "$LOCAL_DIR/public/" \
  "$SSH_ALIAS:$REMOTE_BASE/public_html/"

# === 2. Deploy src/ ===
echo "🔹 [2/3] Sincronizzando src/..."
run_cmd rsync -avz --delete \
  --exclude='.DS_Store' \
  -e "ssh" \
  "$LOCAL_DIR/src/" \
  "$SSH_ALIAS:$REMOTE_BASE/src/"

# === 3. Deploy vendor/ ===
echo "🔹 [3/4] Sincronizzando vendor/..."
run_cmd rsync -avz --delete \
  --exclude='.DS_Store' \
  --exclude='.git' \
  --exclude='*/test' \
  --exclude='*/tests' \
  --exclude='*/Tests' \
  --exclude='*/doc' \
  --exclude='*/docs' \
  -e "ssh" \
  "$LOCAL_DIR/vendor/" \
  "$SSH_ALIAS:$REMOTE_BASE/vendor/"

# === 4. Deploy bin/ (worker cron) ===
echo "🔹 [4/4] Sincronizzando bin/ (worker cron)..."
run_cmd rsync -avz --delete \
  --exclude='.DS_Store' \
  -e "ssh" \
  "$LOCAL_DIR/bin/" \
  "$SSH_ALIAS:$REMOTE_BASE/bin/"

# === NON toccare .env ===
# Il file .env contiene credenziali di produzione e NON deve essere sovrascritto

echo ""
echo "✅ Deploy completato!"
echo ""
echo "📋 Cartelle deployate:"
echo "   ✓ public_html/ (da public/)"
echo "   ✓ src/"
echo "   ✓ vendor/"
echo "   ✓ bin/ (worker cron)"
echo ""
echo "⚠️  Ricorda: .env NON viene sincronizzato per sicurezza."
echo "   Se devi modificarlo, usa: ssh $SSH_ALIAS"
