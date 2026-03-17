#!/usr/bin/env zsh
set -euo pipefail

# Ambiente deploy (default: production)
ENV_NAME="${1:-production}"

###############################################################################
# 1) Bump versione in web/index.html (window.appVersion)
###############################################################################

# Cartella in cui si trova questo script
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"

# Root di agenda_backend.
# Caso 1: script dentro agenda_backend/scripts (comportamento originario)
# Caso 2: script dentro config/scripts/deploy (questa copia)
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
if [[ ! -f "$ROOT_DIR/pubspec.yaml" || ! -f "$ROOT_DIR/web/index.html" ]]; then
  ROOT_DIR="$(cd -- "$SCRIPT_DIR/../../../agenda_backend" && pwd)"
fi

MONOREPO_ROOT="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
ENV_FILE="$MONOREPO_ROOT/config/environments/$ENV_NAME/agenda_backend.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Errore: file ambiente non trovato: $ENV_FILE" >&2
  exit 1
fi

DART_DEFINES=()
WEB_BASE_URL=""
DEPLOY_PATH=""
DEPLOY_SSH_ALIAS=""
while IFS='=' read -r key value; do
  [[ -z "${key// }" ]] && continue
  [[ "$key" == \#* ]] && continue

  if [[ "$key" == "WEB_BASE_URL" ]]; then
    WEB_BASE_URL="$value"
  fi
  if [[ "$key" == "DEPLOY_PATH" ]]; then
    DEPLOY_PATH="$value"
    continue
  fi
  if [[ "$key" == "DEPLOY_SSH_ALIAS" ]]; then
    DEPLOY_SSH_ALIAS="$value"
    continue
  fi

  DART_DEFINES+=("--dart-define=${key}=${value}")
done < "$ENV_FILE"

if [[ -z "$WEB_BASE_URL" ]]; then
  echo "Errore: WEB_BASE_URL mancante in $ENV_FILE" >&2
  exit 1
fi

if [[ -z "$DEPLOY_SSH_ALIAS" ]]; then
  DEPLOY_SSH_ALIAS="romeolab"
fi

if [[ -z "$DEPLOY_PATH" ]]; then
  web_host="${WEB_BASE_URL#*://}"
  web_host="${web_host%%/*}"
  if [[ -z "$web_host" || "$web_host" == "localhost"* || "$web_host" == "127.0.0.1"* ]]; then
    echo "Errore: impossibile derivare DEPLOY_PATH da WEB_BASE_URL=$WEB_BASE_URL. Imposta DEPLOY_PATH in $ENV_FILE" >&2
    exit 1
  fi
  DEPLOY_PATH="www/${web_host}/public_html/"
fi

INDEX_FILE="$ROOT_DIR/web/index.html"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "Errore: non trovo index.html in $INDEX_FILE" >&2
  exit 1
fi

today="$(date +%Y%m%d)"

# Estrae l'attuale valore di window.appVersion (supporta sia YYYYMMDD-N che YYYYMMDD-N.P)
current_v="$(
  perl -0777 -ne '
    if (m/window\.appVersion\s*=\s*"([0-9]{8}-[0-9]+(?:\.[0-9]+)?)"/) { print $1; }
  ' "$INDEX_FILE" || true
)"

next_n=1
current_p="0"
if [[ -n "${current_v:-}" ]]; then
  # Estrae la data (primi 8 caratteri)
  current_date="${current_v:0:8}"
  # Estrae il resto dopo il trattino (es: "1" o "1.9")
  rest="${current_v#*-}"
  
  # Controlla se c'è un suffisso .P (numero deploy produzione)
  if [[ "$rest" == *"."* ]]; then
    current_n="${rest%%.*}"
    current_p="${rest#*.}"
  else
    current_n="$rest"
    current_p="0"
  fi

  if [[ "$current_date" == "$today" ]]; then
    if [[ "$current_n" =~ ^[0-9]+$ ]]; then
      next_n=$(( current_n + 1 ))
    else
      next_n=1
    fi
  else
    next_n=1
  fi
fi

# Incrementa P (numero progressivo deploy PRODUZIONE)
if [[ "$current_p" =~ ^[0-9]+$ ]]; then
  next_p=$(( current_p + 1 ))
else
  next_p=1
fi

new_v="${today}-${next_n}.${next_p}"

# Aggiorna window.appVersion (supporta sia formato YYYYMMDD-N che YYYYMMDD-N.P)
NEW_V="$new_v" perl -0777 -i -pe '
  my $newv = $ENV{NEW_V};
  s{(window\.appVersion\s*=\s*")[0-9]{8}-[0-9]+(?:\.[0-9]+)?(")}{\1$newv\2}g;
' "$INDEX_FILE"

echo "OK: aggiornato $INDEX_FILE -> window.appVersion = \"$new_v\""

# Aggiorna anche app_version.txt (usato dal VersionChecker per auto-aggiornamento)
VERSION_FILE="$ROOT_DIR/web/app_version.txt"
echo "$new_v" > "$VERSION_FILE"
echo "OK: aggiornato $VERSION_FILE -> \"$new_v\""

###############################################################################
# 2) Build Flutter Web (zsh)
###############################################################################

# Percorso assoluto a flutter, se necessario sovrascrivi FLUTTER_HOME
FLUTTER_BIN="${FLUTTER_HOME:-/Applications/flutter}/bin/flutter"

if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Errore: non trovo flutter in $FLUTTER_BIN" >&2
  exit 1
fi

cd "$ROOT_DIR"

echo "Eseguo build backend per env=$ENV_NAME usando $ENV_FILE"
"$FLUTTER_BIN" build web --no-pub --release --no-tree-shake-icons --pwa-strategy=none "${DART_DEFINES[@]}"

###############################################################################
# 3) Copia .htaccess nel build (necessario per SPA routing)
###############################################################################

HTACCESS_SRC="$ROOT_DIR/web/.htaccess"
HTACCESS_DST="$ROOT_DIR/build/web/.htaccess"

if [[ -f "$HTACCESS_SRC" ]]; then
  cp "$HTACCESS_SRC" "$HTACCESS_DST"
  echo "OK: copiato .htaccess in build/web/"
else
  echo "WARN: .htaccess non trovato in web/, SPA routing potrebbe non funzionare"
fi

echo "Deploy target: $DEPLOY_SSH_ALIAS:$DEPLOY_PATH"
rsync -avz --delete "$ROOT_DIR/build/web/" "$DEPLOY_SSH_ALIAS:$DEPLOY_PATH"

# Use the VSCode task named dart-analyze instead of running dart analyze directly.
