#!/bin/bash

# 🧹 Pulisce eventuale file esistente
rm -f lib_bundle_frontend.txt

# 📦 Crea un bundle con tutti i file .dart
# Ogni file viene preceduto da un header che ne mostra il percorso
find lib -type f -name "*.dart" -exec echo "--- FILE: {} ---" \; -exec cat {} \; > lib_bundle_frontend.txt
# 📄 Aggiunge anche il file YAML (pubspec.yaml)
if [ -f "pubspec.yaml" ]; then
  echo "--- FILE: pubspec.yaml ---" >> lib_bundle_frontend.txt
  cat pubspec.yaml >> lib_bundle_frontend.txt
fi

# ✅ Messaggio finale
echo "✅ Bundle creato con successo: lib_bundle_frontend.txt"