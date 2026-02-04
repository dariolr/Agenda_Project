#!/bin/bash
# Deploy script per agenda_core su SiteGround
# 
# Uso: ./scripts/deploy.sh
#
# ⚠️  WHITELIST APPROACH: deploya SOLO le cartelle elencate esplicitamente
#
# Struttura target su SiteGround:
#   www/api.romeolab.it/
#   ├── public_html/     ← index.php, .htaccess (da public/)
#   ├── src/             ← codice PHP
#   ├── vendor/          ← composer dependencies
#   └── .env             ← configurazione (NON sovrascrivere!)
#
# ❌ MAI DEPLOYARE: tests/, docs/, migrations/, scripts/, bin/, .git/, *.md

set -e

# === CONFIGURAZIONE ===
SSH_ALIAS="romeolab"
REMOTE_BASE="www/api.romeolab.it"

# Path locale
LOCAL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "📦 Deploy agenda_core"
echo "   Da: $LOCAL_DIR"
echo "   A:  $SSH_ALIAS:$REMOTE_BASE"
echo ""

# === VERIFICA PRE-DEPLOY ===
# Controlla che non esistano cartelle vietate sul server
echo "🔍 Verifica cartelle vietate sul server..."
FORBIDDEN_DIRS="tests docs migrations scripts .git phpunit.xml composer.json"
for dir in $FORBIDDEN_DIRS; do
  if ssh "$SSH_ALIAS" "test -e $REMOTE_BASE/$dir" 2>/dev/null; then
    echo "⚠️  ATTENZIONE: trovata cartella/file vietato sul server: $dir"
    echo "   Rimuovila manualmente: ssh $SSH_ALIAS 'rm -rf $REMOTE_BASE/$dir'"
  fi
done
echo ""

# === 1. Deploy public/ → public_html/ ===
echo "🔹 [1/3] Sincronizzando public_html (index.php, .htaccess)..."
rsync -avz --delete \
  --exclude='.DS_Store' \
  -e "ssh" \
  "$LOCAL_DIR/public/" \
  "$SSH_ALIAS:$REMOTE_BASE/public_html/"

# === 2. Deploy src/ ===
echo "🔹 [2/3] Sincronizzando src/..."
rsync -avz --delete \
  --exclude='.DS_Store' \
  -e "ssh" \
  "$LOCAL_DIR/src/" \
  "$SSH_ALIAS:$REMOTE_BASE/src/"

# === 3. Deploy vendor/ ===
echo "🔹 [3/4] Sincronizzando vendor/..."
rsync -avz --delete \
  --exclude='.DS_Store' \
  --exclude='.git' \
  --exclude='*/test' \
  --exclude='*/tests' \
  --exclude='*/Tests' \
  --exclude='*/doc' \
  --exclude='*/docs' \
  -e "ssh" \
  "$LOCAL_DIR/vendor/" \
  "$SSH_ALIAS:$REMOTE_BASE/vendor/"

# === 4. Deploy bin/ (worker cron) ===
echo "🔹 [4/4] Sincronizzando bin/ (worker cron)..."
rsync -avz --delete \
  --exclude='.DS_Store' \
  -e "ssh" \
  "$LOCAL_DIR/bin/" \
  "$SSH_ALIAS:$REMOTE_BASE/bin/"

# === NON toccare .env ===
# Il file .env contiene credenziali di produzione e NON deve essere sovrascritto

echo ""
echo "✅ Deploy completato!"
echo ""
echo "📋 Cartelle deployate:"
echo "   ✓ public_html/ (da public/)"
echo "   ✓ src/"
echo "   ✓ vendor/"
echo "   ✓ bin/ (worker cron)"
echo ""
echo "⚠️  Ricorda: .env NON viene sincronizzato per sicurezza."
echo "   Se devi modificarlo, usa: ssh $SSH_ALIAS"
