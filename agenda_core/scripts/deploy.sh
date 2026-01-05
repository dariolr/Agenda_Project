#!/bin/bash
# Deploy script per agenda_core su SiteGround
# 
# Uso: ./scripts/deploy.sh
#
# Struttura target su SiteGround:
#   www/api.romeolab.it/
#   ├── public_html/     ← index.php, .htaccess
#   ├── vendor/          ← composer dependencies
#   ├── src/             ← codice PHP
#   └── .env             ← configurazione (NON sovrascrivere!)

set -e

# === CONFIGURAZIONE ===
# Usa alias "siteground" da ~/.ssh/config
SSH_ALIAS="siteground"
REMOTE_BASE="www/api.romeolab.it"

# Path locale
LOCAL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "📦 Deploy agenda_core"
echo "   Da: $LOCAL_DIR"
echo "   A:  $SSH_ALIAS:$REMOTE_BASE"
echo ""

# === 1. Deploy public/ → public_html/ ===
echo "🔹 Sincronizzando public_html (index.php, .htaccess)..."
rsync -avz --delete \
  -e "ssh" \
  "$LOCAL_DIR/public/" \
  "$SSH_ALIAS:$REMOTE_BASE/public_html/"

# === 2. Deploy src/ ===
echo "🔹 Sincronizzando src/..."
rsync -avz --delete \
  -e "ssh" \
  "$LOCAL_DIR/src/" \
  "$SSH_ALIAS:$REMOTE_BASE/src/"

# === 3. Deploy vendor/ ===
echo "🔹 Sincronizzando vendor/..."
rsync -avz --delete \
  -e "ssh" \
  "$LOCAL_DIR/vendor/" \
  "$SSH_ALIAS:$REMOTE_BASE/vendor/"

# === NON toccare .env ===
# Il file .env contiene credenziali di produzione e NON deve essere sovrascritto
# Se serve aggiornarlo, fallo manualmente via SSH

echo ""
echo "✅ Deploy completato!"
echo ""
echo "⚠️  Ricorda: .env NON viene sincronizzato per sicurezza."
echo "   Se devi modificarlo, usa: ssh $SSH_ALIAS"
