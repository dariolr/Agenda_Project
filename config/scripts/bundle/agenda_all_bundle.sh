#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
FINAL_BUNDLE="$SCRIPT_DIR/agenda_all_bundle.txt"

BACKEND_SCRIPT="$SCRIPT_DIR/agenda_backend_bundle.sh"
FRONTEND_SCRIPT="$SCRIPT_DIR/agenda_frontend_bundle.sh"
CORE_SCRIPT="$SCRIPT_DIR/agenda_core_bundle.sh"
CONFIG_SCRIPT="$SCRIPT_DIR/config_bundle.sh"

BACKEND_FILE="$SCRIPT_DIR/agenda_backend_bundle.txt"
FRONTEND_FILE="$SCRIPT_DIR/agenda_frontend_bundle.txt"
CORE_FILE="$SCRIPT_DIR/agenda_core_bundle.txt"
CONFIG_FILE="$SCRIPT_DIR/config_bundle.txt"
ROOT_AGENTS_FILE="$ROOT_DIR/AGENTS.MD"

"$BACKEND_SCRIPT"
"$FRONTEND_SCRIPT"
"$CORE_SCRIPT"
"$CONFIG_SCRIPT"

{
  echo "=== Bundle di tutti i file sorgente ==="
  echo "Bundle generato il: $(date)"
  echo

  echo ">>> CONTENUTO: AGENTS.MD"
  if [[ -f "$ROOT_AGENTS_FILE" ]]; then
    cat "$ROOT_AGENTS_FILE"
  else
    echo "File non trovato: $ROOT_AGENTS_FILE"
  fi

  echo
  echo "--------------------------"
  echo

  echo ">>> CONTENUTO: Config"
  if [[ -f "$CONFIG_FILE" ]]; then
    cat "$CONFIG_FILE"
  else
    echo "File non trovato: $CONFIG_FILE"
  fi

  echo
  echo "--------------------------"
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
