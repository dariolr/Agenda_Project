#!/bin/bash
# Script per rimuovere cartelle/file non necessari dal server SiteGround
#
# Uso: ./scripts/cleanup-server.sh
#
# ⚠️  Eseguire UNA VOLTA per pulire deploy errati precedenti

set -e

SSH_ALIAS="romeolab"
REMOTE_BASE="www/api.romeolab.it"

echo "🧹 Pulizia server agenda_core"
echo "   Target: $SSH_ALIAS:$REMOTE_BASE"
echo ""

# Lista di cartelle/file da rimuovere
# ⚠️  bin/ NON è in lista: contiene worker per cron job!
ITEMS_TO_REMOVE=(
  "tests"
  "docs"
  "migrations"
  "scripts"
  ".git"
  "phpunit.xml"
  "composer.json"
  "composer.lock"
  "AGENTS.md"
  "DEPLOY.md"
  "README.md"
  "STAFF_PLANNING_MODEL.m"
  "agenda_all_bundle.txt"
  "agenda_core_snapshot.txt"
  "lib_bundle_backend.txt"
  "lib_bundle_frontend.txt"
  ".phpunit.result.cache"
  "pubspec.lock"
)

echo "📋 Verifico e rimuovo elementi non necessari..."
echo ""

for item in "${ITEMS_TO_REMOVE[@]}"; do
  if ssh "$SSH_ALIAS" "test -e $REMOTE_BASE/$item" 2>/dev/null; then
    echo "   ❌ Rimuovo: $item"
    ssh "$SSH_ALIAS" "rm -rf $REMOTE_BASE/$item"
  fi
done

echo ""
echo "✅ Pulizia completata!"
echo ""
echo "📂 Struttura corretta sul server:"
echo "   $REMOTE_BASE/"
echo "   ├── public_html/   (index.php, .htaccess)"
echo "   ├── src/           (codice PHP)"
echo "   ├── vendor/        (dipendenze)"
echo "   └── .env           (configurazione)"
