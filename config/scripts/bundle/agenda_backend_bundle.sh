#!/bin/bash

# Root di agenda_backend.
# Caso 1: script dentro agenda_backend/scripts (comportamento originario)
# Caso 2: script dentro config/scripts/bundle (questa copia)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ ! -d "$ROOT_DIR/lib" ] || [ ! -f "$ROOT_DIR/pubspec.yaml" ]; then
  ROOT_DIR="$(cd "$SCRIPT_DIR/../../../agenda_backend" && pwd)"
fi

# Percorso output (cartella config/scripts/bundle)
OUTPUT_DIR="$SCRIPT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/lib_bundle_backend.txt"

# 🧹 Pulisce eventuali file esistenti
rm -f "$OUTPUT_FILE"

# 📦 Crea il bundle locale
find "$ROOT_DIR/lib" -type f -name "*.dart" \
  -exec echo "--- FILE: {} ---" \; \
  -exec cat {} \; > "$OUTPUT_FILE"

# 📄 Aggiunge pubspec.yaml se esiste
if [ -f "$ROOT_DIR/pubspec.yaml" ]; then
  echo "--- FILE: pubspec.yaml ---" >> "$OUTPUT_FILE"
  cat "$ROOT_DIR/pubspec.yaml" >> "$OUTPUT_FILE"
fi

# 📁 Crea la cartella output se non esiste
mkdir -p "$OUTPUT_DIR"

# ✅ Messaggio finale
echo "✅ Bundle backend creato:"
echo " - output: $OUTPUT_FILE"
