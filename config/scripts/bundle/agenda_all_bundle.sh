#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FINAL_BUNDLE="$SCRIPT_DIR/agenda_all_bundle.txt"

BACKEND_SCRIPT="$SCRIPT_DIR/agenda_backend_bundle.sh"
FRONTEND_SCRIPT="$SCRIPT_DIR/agenda_frontend_bundle.sh"
CORE_SCRIPT="$SCRIPT_DIR/agenda_core_bundle.sh"

BACKEND_FILE="$SCRIPT_DIR/agenda_backend_bundle.txt"
FRONTEND_FILE="$SCRIPT_DIR/agenda_frontend_bundle.txt"
CORE_FILE="$SCRIPT_DIR/agenda_core_bundle.txt"

"$BACKEND_SCRIPT"
"$FRONTEND_SCRIPT"
"$CORE_SCRIPT"

{
  echo "=== Bundle di tutti i file sorgente ==="
  echo "Bundle generato il: $(date)"
  echo

  echo ">>> CONTENUTO: Frontend"
  if [[ -f "$FRONTEND_FILE" ]]; then
    cat "$FRONTEND_FILE"
  else
    echo "File non trovato: $FRONTEND_FILE"
  fi

  echo
  echo "--------------------------"
  echo

  echo ">>> CONTENUTO: Backend"
  if [[ -f "$BACKEND_FILE" ]]; then
    cat "$BACKEND_FILE"
  else
    echo "File non trovato: $BACKEND_FILE"
  fi

  echo
  echo "--------------------------"
  echo

  echo ">>> CONTENUTO: Core"
  if [[ -f "$CORE_FILE" ]]; then
    cat "$CORE_FILE"
  else
    echo "File non trovato: $CORE_FILE"
  fi

  echo
  echo "=== FINE DEL BUNDLE ==="
} > "$FINAL_BUNDLE"

echo "Bundle unificato creato: $FINAL_BUNDLE"
