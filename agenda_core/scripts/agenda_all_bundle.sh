#!/usr/bin/env bash

# File generati dai progetti
FRONTEND_FILE="../agenda_frontend/lib_bundle_frontend.txt"
BACKEND_FILE="../agenda_backend/lib_bundle_backend.txt"
CORE_FILE="../agenda_core/agenda_core_snapshot.txt"

# File di output finale
FINAL_BUNDLE="agenda_all_bundle.txt"

# Inizio
echo "=== Bundle di tutti i file TXT dei progetti ===" > "$FINAL_BUNDLE"
echo "Bundle generato il: $(date)" >> "$FINAL_BUNDLE"
echo "" >> "$FINAL_BUNDLE"

# Aggiungi frontend
echo ">>> CONTENUTO: Frontend" >> "$FINAL_BUNDLE"
if [ -f "$FRONTEND_FILE" ]; then
  cat "$FRONTEND_FILE" >> "$FINAL_BUNDLE"
else
  echo "⚠ File non trovato: $FRONTEND_FILE" >> "$FINAL_BUNDLE"
fi
echo -e "\n--------------------------\n" >> "$FINAL_BUNDLE"

# Aggiungi backend
echo ">>> CONTENUTO: Backend" >> "$FINAL_BUNDLE"
if [ -f "$BACKEND_FILE" ]; then
  cat "$BACKEND_FILE" >> "$FINAL_BUNDLE"
else
  echo "⚠ File non trovato: $BACKEND_FILE" >> "$FINAL_BUNDLE"
fi
echo -e "\n--------------------------\n" >> "$FINAL_BUNDLE"

# Aggiungi core
echo ">>> CONTENUTO: Core" >> "$FINAL_BUNDLE"
if [ -f "$CORE_FILE" ]; then
  cat "$CORE_FILE" >> "$FINAL_BUNDLE"
else
  echo "⚠ File non trovato: $CORE_FILE" >> "$FINAL_BUNDLE"
fi
echo -e "\n=== FINE DEL BUNDLE ===" >> "$FINAL_BUNDLE"

echo "File unificato creato: $FINAL_BUNDLE"
