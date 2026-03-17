#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../agenda_core" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/agenda_core_bundle.txt"

if [[ ! -d "$ROOT_DIR/src" || ! -d "$ROOT_DIR/public" ]]; then
  echo "Errore: root agenda_core non valida: $ROOT_DIR" >&2
  exit 1
fi

rm -f "$OUTPUT_FILE"

{
  echo "======================================="
  echo "AGENDA CORE - SOURCE BUNDLE"
  echo "Generated on: $(date)"
  echo "Project root: $ROOT_DIR"
  echo "======================================="
  echo
} >> "$OUTPUT_FILE"

append_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    echo "--- FILE: $file ---" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
  fi
}

# File singoli utili
append_file "$ROOT_DIR/AGENTS.md"
append_file "$ROOT_DIR/.env.example"
append_file "$ROOT_DIR/public/index.php"
append_file "$ROOT_DIR/composer.json"

# Documentazione locale core
while IFS= read -r file; do
  append_file "$file"
done < <(find "$ROOT_DIR/docs" -type f -name "*.md" 2>/dev/null | sort)

# Config core
while IFS= read -r file; do
  append_file "$file"
done < <(find "$ROOT_DIR/config" -type f \( -name "*.php" -o -name "*.json" \) 2>/dev/null | sort)

# Migrations centralizzate monorepo
while IFS= read -r file; do
  append_file "$file"
done < <(find "$ROOT_DIR/../config/migrations" -type f -name "*.sql" 2>/dev/null | sort)

# Sorgenti PHP core
while IFS= read -r file; do
  append_file "$file"
done < <(find "$ROOT_DIR/public" "$ROOT_DIR/src" "$ROOT_DIR/routes" "$ROOT_DIR/tests" -type f -name "*.php" 2>/dev/null | sort)

{
  echo "======================================="
  echo "END OF BUNDLE"
  echo "======================================="
} >> "$OUTPUT_FILE"

echo "Bundle core creato: $OUTPUT_FILE"
