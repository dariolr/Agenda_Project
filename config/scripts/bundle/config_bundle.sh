#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/config_bundle.txt"

if [[ ! -d "$ROOT_DIR" || ! -d "$ROOT_DIR/scripts" ]]; then
  echo "Errore: root config non valida: $ROOT_DIR" >&2
  exit 1
fi

rm -f "$OUTPUT_FILE"

{
  echo "======================================="
  echo "CONFIG - SOURCE BUNDLE"
  echo "Generated on: $(date)"
  echo "Project root: $ROOT_DIR"
  echo "======================================="
  echo
} >> "$OUTPUT_FILE"

append_file() {
  local file="$1"
  echo "--- FILE: $file ---" >> "$OUTPUT_FILE"
  cat "$file" >> "$OUTPUT_FILE"
  echo >> "$OUTPUT_FILE"
}

while IFS= read -r file; do
  if grep -Iq . "$file"; then
    append_file "$file"
  fi
done < <(
  find "$ROOT_DIR" \
    \( \
      -path "$OUTPUT_FILE" -o \
      -path "$SCRIPT_DIR/agenda_all_bundle.txt" -o \
      -path "$SCRIPT_DIR/agenda_backend_bundle.txt" -o \
      -path "$SCRIPT_DIR/agenda_core_bundle.txt" -o \
      -path "$SCRIPT_DIR/agenda_frontend_bundle.txt" -o \
      -path "$SCRIPT_DIR/config_bundle.txt" -o \
      -path "*/.DS_Store" \
    \) -prune -o \
    -type f -print | sort
)

{
  echo "======================================="
  echo "END OF BUNDLE"
  echo "======================================="
} >> "$OUTPUT_FILE"

echo "Bundle config creato: $OUTPUT_FILE"
