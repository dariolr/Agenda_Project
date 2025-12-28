#!/bin/bash

# ================================
# Agenda Core - Project Snapshot
# ================================

OUTPUT_FILE="agenda_core_snapshot.txt"

echo "Generating Agenda Core snapshot..."
echo "Output file: $OUTPUT_FILE"
echo ""

# Pulizia file precedente
rm -f "$OUTPUT_FILE"

# Header
{
  echo "======================================="
  echo "AGENDA CORE - PROJECT SNAPSHOT"
  echo "Generated on: $(date)"
  echo "======================================="
  echo ""
} >> "$OUTPUT_FILE"

# Funzione helper
dump_section () {
  TITLE=$1
  PATTERN=$2

  echo "---- $TITLE ----"
  echo ""
  echo "======================================="
  echo "$TITLE"
  echo "=======================================" >> "$OUTPUT_FILE"

  for FILE in $PATTERN; do
    if [ -f "$FILE" ]; then
      echo ""
      echo "----- FILE: $FILE -----" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
      cat "$FILE" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
    fi
  done
}

# ================================
# Documentazione
# ================================
dump_section "DOCUMENTATION (.md)" \
"AGENTS.md docs/*.md"

# ================================
# Config / Env (se presenti)
# ================================
dump_section "CONFIG FILES" \
".env.example config/*.php config/*.json"

# ================================
# Database / Migrations
# ================================
dump_section "DATABASE MIGRATIONS" \
"migrations/*.sql"

# ================================
# Source Code (PHP)
# ================================
dump_section "PHP SOURCE CODE" \
"public/*.php src/**/*.php"

# ================================
# Routing / Entry points
# ================================
dump_section "ENTRY POINTS & ROUTING" \
"public/index.php routes/*.php"

# ================================
# Tests (se presenti)
# ================================
dump_section "TESTS" \
"tests/**/*.php"

# Footer
{
  echo ""
  echo "======================================="
  echo "END OF SNAPSHOT"
  echo "======================================="
} >> "$OUTPUT_FILE"

echo ""
echo "Snapshot completed."
echo "File created: $OUTPUT_FILE"
