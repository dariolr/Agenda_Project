#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# DEPLOY STAGING - prenota-staging.romeolab.it
###############################################################################

###############################################################################
# 1) Bump versione in web/index.html (window.appVersion)
###############################################################################

# Cartella in cui si trova questo script (script/)
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
# Root del repo (contiene sia script/ che web/)
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

INDEX_FILE="$ROOT_DIR/web/index.html"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "Errore: non trovo index.html in $INDEX_FILE" >&2
  exit 1
fi

today="$(date +%Y%m%d)"

# Estrae l'attuale valore di window.appVersion (se esiste)
current_v="$(
  perl -0777 -ne '
    if (m/window\.appVersion\s*=\s*"([0-9]{8}-[0-9]+)"/) { print $1; }
  ' "$INDEX_FILE" || true
)"

next_n=1
if [[ -n "${current_v:-}" ]]; then
  current_date="${current_v%%-*}"
  current_n="${current_v##*-}"

  if [[ "$current_date" == "$today" ]]; then
    if [[ "$current_n" == <-> ]]; then
      next_n=$(( current_n + 1 ))
    else
      next_n=1
    fi
  else
    next_n=1
  fi
fi

new_v="${today}-${next_n}"

# Aggiorna window.appVersion
NEW_V="$new_v" perl -0777 -i -pe '
  my $newv = $ENV{NEW_V};
  s{(window\.appVersion\s*=\s*")[0-9]{8}-[0-9]+(")}{\1$newv\2}g;
' "$INDEX_FILE"

echo "OK: aggiornato $INDEX_FILE -> window.appVersion = \"$new_v\""

# Aggiorna anche app_version.txt (usato dal VersionChecker per auto-aggiornamento)
VERSION_FILE="$ROOT_DIR/web/app_version.txt"
echo "$new_v" > "$VERSION_FILE"
echo "OK: aggiornato $VERSION_FILE -> \"$new_v\""

###############################################################################
# 2) Build Flutter Web (zsh) - STAGING API
###############################################################################

# Percorso assoluto a flutter, se necessario sovrascrivi FLUTTER_HOME
FLUTTER_BIN="${FLUTTER_HOME:-/Applications/flutter}/bin/flutter"

if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Errore: non trovo flutter in $FLUTTER_BIN" >&2
  exit 1
fi

cd "$ROOT_DIR"

echo "Eseguo: $FLUTTER_BIN build web --release --no-tree-shake-icons --pwa-strategy=none --dart-define=API_BASE_URL=https://api-staging.romeolab.it"
"$FLUTTER_BIN" build web --no-pub --release --no-tree-shake-icons --pwa-strategy=none --dart-define=API_BASE_URL=https://api-staging.romeolab.it

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

###############################################################################
# 4) Deploy su STAGING
###############################################################################

rsync -avz --delete "$ROOT_DIR/build/web/" siteground:www/prenota-staging.romeolab.it/public_html/

echo "✅ Deploy STAGING completato: https://prenota-staging.romeolab.it"
