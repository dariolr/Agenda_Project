#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../agenda_frontend" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/agenda_frontend_bundle.txt"

if [[ ! -d "$ROOT_DIR/lib" || ! -f "$ROOT_DIR/pubspec.yaml" ]]; then
  echo "Errore: root agenda_frontend non valida: $ROOT_DIR" >&2
  exit 1
fi

rm -f "$OUTPUT_FILE"

# Bundle sorgenti Dart
while IFS= read -r file; do
  echo "--- FILE: $file ---" >> "$OUTPUT_FILE"
  cat "$file" >> "$OUTPUT_FILE"
  echo >> "$OUTPUT_FILE"
done < <(find "$ROOT_DIR/lib" -type f -name "*.dart" | sort)

# Pubspec
if [[ -f "$ROOT_DIR/pubspec.yaml" ]]; then
  echo "--- FILE: $ROOT_DIR/pubspec.yaml ---" >> "$OUTPUT_FILE"
  cat "$ROOT_DIR/pubspec.yaml" >> "$OUTPUT_FILE"
  echo >> "$OUTPUT_FILE"
fi

echo "Bundle frontend creato: $OUTPUT_FILE"
