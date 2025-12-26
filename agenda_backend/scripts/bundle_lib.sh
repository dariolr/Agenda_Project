#!/bin/bash

# 📁 Percorso di output (2 livelli sopra, cartella agenda_core)
OUTPUT_DIR="../agenda_core"
OUTPUT_FILE="$OUTPUT_DIR/lib_bundle_backend.txt"

# 🧹 Pulisce eventuali file esistenti
rm -f lib_bundle_backend.txt
rm -f "$OUTPUT_FILE"

# 📦 Crea il bundle locale
find lib -type f -name "*.dart" \
  -exec echo "--- FILE: {} ---" \; \
  -exec cat {} \; > lib_bundle_backend.txt

# 📄 Aggiunge pubspec.yaml se esiste
if [ -f "pubspec.yaml" ]; then
  echo "--- FILE: pubspec.yaml ---" >> lib_bundle_backend.txt
  cat pubspec.yaml >> lib_bundle_backend.txt
fi

# 📁 Crea la cartella agenda_core se non esiste
mkdir -p "$OUTPUT_DIR"

# 📤 Copia il bundle anche in agenda_core
cp lib_bundle_backend.txt "$OUTPUT_FILE"

# ✅ Messaggio finale
echo "✅ Bundle backend creato:"
echo " - locale: lib_bundle_backend.txt"
echo " - copia:  $OUTPUT_FILE"
