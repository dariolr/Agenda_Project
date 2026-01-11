#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# 1) Bump versione cache-busting in web/index.html (flutter_bootstrap.js?v=...)
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

# Estrae l'attuale valore v=YYYYMMDD-N (se esiste)
current_v="$(
  perl -0777 -ne '
    if (m/flutter_bootstrap\.js\?v=([0-9]{8}-[0-9]+)/) { print $1; }
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

# Aggiorna SOLO il tag script che punta a flutter_bootstrap.js
# Se non c'è query, aggiunge ?v=...
NEW_V="$new_v" perl -0777 -i -pe '
  my $newv = $ENV{NEW_V};

  s{
    (<script\b[^>]*\bsrc=")                # group 1: inizio src="
    (flutter_bootstrap\.js)                # group 2: file
    (?:\?[^"]*)?                           # query attuale (opzionale)
    ("[^>]*>\s*</script>)                  # group 3: chiusura src e tag
  }{
    my ($a,$b,$c) = ($1,$2,$3);
    $a.$b."?v=".$newv.$c
  }gex;
' "$INDEX_FILE"

echo "OK: aggiornato $INDEX_FILE -> flutter_bootstrap.js?v=$new_v"

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

echo "Eseguo: $FLUTTER_BIN build web --release --no-tree-shake-icons --pwa-strategy=none --dart-define=API_BASE_URL=https://api.romeolab.it"
"$FLUTTER_BIN" build web --release --no-tree-shake-icons --pwa-strategy=none --dart-define=API_BASE_URL=https://api.romeolab.it

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

rsync -avz --delete "$ROOT_DIR/build/web/" siteground:www/gestionale.romeolab.it/public_html/

# Use the VSCode task named dart-analyze instead of running dart analyze directly.
