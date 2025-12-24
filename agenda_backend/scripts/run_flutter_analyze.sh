#!/bin/bash
set -euo pipefail

# Percorso assoluto a flutter, se necessario sovrascrivi FLUTTER_HOME
FLUTTER_BIN="${FLUTTER_HOME:-/Applications/flutter}/bin/flutter"

if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Errore: non trovo flutter in $FLUTTER_BIN" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

echo "Eseguo: $FLUTTER_BIN analyze"
"$FLUTTER_BIN" analyze


# Use the VSCode task named dart-analyze instead of running dart analyze directly.