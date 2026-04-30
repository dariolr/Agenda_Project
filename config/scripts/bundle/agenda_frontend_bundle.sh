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

append_file() {
  local file="$1"
  echo "--- FILE: $file ---" >> "$OUTPUT_FILE"
  cat "$file" >> "$OUTPUT_FILE"
  echo >> "$OUTPUT_FILE"
}

# Bundle sorgenti Dart
while IFS= read -r file; do
  append_file "$file"
done < <(find "$ROOT_DIR/lib" -type f -name "*.dart" | sort)

# Bundle cartella web: includi solo file testuali, salta asset binari
if [[ -d "$ROOT_DIR/web" ]]; then
  while IFS= read -r file; do
    if grep -Iq . "$file"; then
      append_file "$file"
    fi
  done < <(find "$ROOT_DIR/web" -type f ! -name ".DS_Store" | sort)
fi

# File YAML/YML di progetto (es. pubspec, analysis options, devtools)
while IFS= read -r file; do
  append_file "$file"
done < <(
  find "$ROOT_DIR" \
    \( -path "$ROOT_DIR/build" -o -path "$ROOT_DIR/.dart_tool" -o -path "$ROOT_DIR/.git" \) -prune -o \
    -type f \( -name "*.yaml" -o -name "*.yml" \) -print | sort
)

echo "Bundle frontend creato: $OUTPUT_FILE"
