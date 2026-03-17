#!/bin/bash

# Root di agenda_frontend.
# Caso 1: script dentro agenda_frontend/scripts (comportamento originario)
# Caso 2: script dentro config/scripts/bundle (questa copia)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ ! -d "$ROOT_DIR/lib" ] || [ ! -f "$ROOT_DIR/pubspec.yaml" ]; then
  ROOT_DIR="$(cd "$SCRIPT_DIR/../../../agenda_frontend" && pwd)"
fi

# Percorsi output
LOCAL_BUNDLE="$ROOT_DIR/lib_bundle_frontend.txt"
OUTPUT_DIR="$(cd "$ROOT_DIR/.." && pwd)/agenda_core"
OUTPUT_FILE="$OUTPUT_DIR/lib_bundle_frontend.txt"

# 🧹 Pulisce eventuali file esistenti
rm -f "$LOCAL_BUNDLE"
rm -f "$OUTPUT_FILE"

# 📦 Crea il bundle locale
find "$ROOT_DIR/lib" -type f -name "*.dart" \
  -exec echo "--- FILE: {} ---" \; \
  -exec cat {} \; > "$LOCAL_BUNDLE"

# 📄 Aggiunge pubspec.yaml se esiste
if [ -f "$ROOT_DIR/pubspec.yaml" ]; then
  echo "--- FILE: pubspec.yaml ---" >> "$LOCAL_BUNDLE"
  cat "$ROOT_DIR/pubspec.yaml" >> "$LOCAL_BUNDLE"
fi

# 📁 Crea la cartella agenda_core se non esiste
mkdir -p "$OUTPUT_DIR"

# 📤 Copia il bundle anche in agenda_core
cp "$LOCAL_BUNDLE" "$OUTPUT_FILE"

# ✅ Messaggio finale
echo "✅ Bundle creato:"
echo " - locale: $LOCAL_BUNDLE"
echo " - copia:  $OUTPUT_FILE"
