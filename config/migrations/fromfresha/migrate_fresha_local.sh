#!/bin/zsh
#
# migrate_fresha_local.sh
# Esegue la migrazione Fresha in locale
#
# Uso:
#   ./migrate_fresha_local.sh [--dry-run] [--clients-only]
#
# Prerequisiti:
#   1. Configurare config.php con i parametri corretti
#   2. Posizionare i file CSV nella stessa cartella
#   3. Avere PHP installato localmente
#   4. Configurare .env locale con connessione al DB desiderato
#

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directory dello script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Parse arguments
DRY_RUN=false
CLIENTS_ONLY=false
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --clients-only)
            CLIENTS_ONLY=true
            shift
            ;;
        --help)
            echo "Uso: $0 [--dry-run] [--clients-only]"
            echo ""
            echo "Opzioni:"
            echo "  --dry-run    Simula la migrazione senza modificare il database"
            echo "  --clients-only  Esegue solo import clienti"
            echo "  --help       Mostra questo messaggio"
            exit 0
            ;;
    esac
done

echo "${YELLOW}========================================${NC}"
echo "${YELLOW}   Migrazione Fresha - Locale${NC}"
echo "${YELLOW}========================================${NC}"
echo ""

# Verifica che config.php esista
if [[ ! -f "$SCRIPT_DIR/config.php" ]]; then
    echo "${RED}ERRORE: config.php non trovato in $SCRIPT_DIR${NC}"
    exit 1
fi

# Verifica che .env esista
if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
    echo "${RED}ERRORE: .env non trovato in $PROJECT_ROOT${NC}"
    echo "Crea il file .env con le credenziali del database locale"
    exit 1
fi

# Leggi configurazione CSV da config.php
CSV_CLIENTS=$(php -r "include '$SCRIPT_DIR/config.php'; echo FRESHA_CONFIG['csv_clients'];")
CSV_SERVICES=$(php -r "include '$SCRIPT_DIR/config.php'; echo FRESHA_CONFIG['csv_services'];")
CSV_STAFF=$(php -r "include '$SCRIPT_DIR/config.php'; echo FRESHA_CONFIG['csv_staff'];")
BUSINESS_ID=$(php -r "include '$SCRIPT_DIR/config.php'; echo FRESHA_CONFIG['business_id'];")
LOCATION_ID=$(php -r "include '$SCRIPT_DIR/config.php'; echo FRESHA_CONFIG['location_id'];")

RUN_CLIENTS=true
RUN_SERVICES=true
RUN_STAFF=true

if [[ -z "$CSV_CLIENTS" ]]; then
    RUN_CLIENTS=false
fi
if [[ -z "$CSV_SERVICES" ]]; then
    RUN_SERVICES=false
fi
if [[ -z "$CSV_STAFF" ]]; then
    RUN_STAFF=false
fi
if [[ "$CLIENTS_ONLY" == "true" ]]; then
    RUN_SERVICES=false
    RUN_STAFF=false
fi

echo "Configurazione:"
echo "  Business ID: $BUSINESS_ID"
echo "  Location ID: $LOCATION_ID"
echo "  CSV Clienti: ${CSV_CLIENTS:-[non valorizzato]}"
echo "  CSV Servizi: ${CSV_SERVICES:-[non valorizzato]}"
echo "  CSV Staff: ${CSV_STAFF:-[non valorizzato]}"
echo "  Dry Run: $DRY_RUN"
echo "  Clients Only: $CLIENTS_ONLY"
echo ""

if [[ "$RUN_CLIENTS" == "false" ]]; then
    echo "${YELLOW}WARN: csv_clients non valorizzato, salto import clienti${NC}"
fi
if [[ "$RUN_SERVICES" == "false" ]]; then
    echo "${YELLOW}WARN: csv_services non valorizzato o disabilitato, salto import servizi${NC}"
fi
if [[ "$RUN_STAFF" == "false" ]]; then
    echo "${YELLOW}WARN: csv_staff non valorizzato o disabilitato, salto import staff${NC}"
fi
if [[ "$RUN_CLIENTS" == "false" && "$RUN_SERVICES" == "false" && "$RUN_STAFF" == "false" ]]; then
    echo "${RED}ERRORE: Nessun CSV configurato da processare.${NC}"
    exit 1
fi

# Verifica che i file CSV esistano
MISSING_CSV=false
if [[ "$RUN_CLIENTS" == "true" && ! -f "$SCRIPT_DIR/$CSV_CLIENTS" ]]; then
    echo "${RED}ERRORE: File CSV clienti non trovato: $CSV_CLIENTS${NC}"
    MISSING_CSV=true
fi
if [[ "$RUN_SERVICES" == "true" && ! -f "$SCRIPT_DIR/$CSV_SERVICES" ]]; then
    echo "${RED}ERRORE: File CSV servizi non trovato: $CSV_SERVICES${NC}"
    MISSING_CSV=true
fi
if [[ "$RUN_STAFF" == "true" && ! -f "$SCRIPT_DIR/$CSV_STAFF" ]]; then
    echo "${RED}ERRORE: File CSV staff non trovato: $CSV_STAFF${NC}"
    MISSING_CSV=true
fi

if [[ "$MISSING_CSV" == "true" ]]; then
    echo ""
    echo "Posiziona i file CSV nella cartella: $SCRIPT_DIR"
    exit 1
fi

# Info esecuzionee ai servizi della sede anche le categorie 
if [[ "$DRY_RUN" == "false" ]]; then
    echo "${YELLOW}Esecuzione migrazione su database LOCALE...${NC}"
    echo ""
fi

# Imposta dry_run nel config se richiesto
if [[ "$DRY_RUN" == "true" ]]; then
    echo "${YELLOW}Modalità DRY RUN attiva - nessuna modifica al database${NC}"
    echo ""
    # Crea config temporaneo con dry_run = true
    TEMP_CONFIG="$SCRIPT_DIR/config_temp.php"
    php -r "
        include '$SCRIPT_DIR/config.php';
        \$config = FRESHA_CONFIG;
        \$config['dry_run'] = true;
        echo '<?php' . PHP_EOL;
        echo 'const FRESHA_CONFIG = ' . var_export(\$config, true) . ';' . PHP_EOL;
        echo 'return FRESHA_CONFIG;' . PHP_EOL;
    " > "$TEMP_CONFIG"
    
    # Backup config originale e usa temporaneo
    mv "$SCRIPT_DIR/config.php" "$SCRIPT_DIR/config_backup.php"
    mv "$TEMP_CONFIG" "$SCRIPT_DIR/config.php"
    RESTORE_CONFIG=true
else
    RESTORE_CONFIG=false
fi

# Funzione per ripristinare config originale
restore_config() {
    if [[ "$RESTORE_CONFIG" == "true" ]]; then
        mv "$SCRIPT_DIR/config_backup.php" "$SCRIPT_DIR/config.php"
    fi
}

# Trap per ripristinare config in caso di errore
trap restore_config EXIT

# Cambia directory al progetto root per caricare vendor/autoload.php
cd "$PROJECT_ROOT"

# Variabili per catturare i report
REPORT_CLIENTS=""
REPORT_SERVICES=""
REPORT_STAFF=""

# 1. Import Clienti
if [[ "$RUN_CLIENTS" == "true" ]]; then
    echo "${GREEN}Importazione Clienti...${NC}"
    OUTPUT_CLIENTS=$(php "$SCRIPT_DIR/import_clients.php" 2>&1)
    echo "$OUTPUT_CLIENTS" | grep -v "=== REPORT FINALE" | grep -v "^Clienti inseriti:" | grep -v "^Duplicati email saltati:" | grep -v "^Business ID:" | grep -v "^====" || true
    REPORT_CLIENTS=$(echo "$OUTPUT_CLIENTS" | grep -A20 "=== REPORT FINALE ===")
    echo ""
fi

if [[ "$RUN_SERVICES" == "true" ]]; then
    # 2. Import Servizi
    echo "${GREEN}Importazione Servizi...${NC}"
    OUTPUT_SERVICES=$(php "$SCRIPT_DIR/import_services.php" 2>&1)
    echo "$OUTPUT_SERVICES" | grep -v "=== REPORT FINALE" | grep -v "^Categorie inserite:" | grep -v "^Servizi inseriti:" | grep -v "^Variants inseriti:" | grep -v "^====" || true
    REPORT_SERVICES=$(echo "$OUTPUT_SERVICES" | grep -A20 "=== REPORT FINALE ===")
    echo ""
fi

if [[ "$RUN_STAFF" == "true" ]]; then
    # 3. Import Staff
    echo "${GREEN}Importazione Staff...${NC}"
    OUTPUT_STAFF=$(php "$SCRIPT_DIR/import_staff.php" 2>&1)
    echo "$OUTPUT_STAFF" | grep -v "=== REPORT FINALE" | grep -v "^Staff inseriti:" | grep -v "^Staff disattivati:" | grep -v "^====" || true
    REPORT_STAFF=$(echo "$OUTPUT_STAFF" | grep -A20 "=== REPORT FINALE ===")
    echo ""
fi

echo "${GREEN}========================================${NC}"
echo "${GREEN}   Migrazione completata!${NC}"
echo "${GREEN}========================================${NC}"
echo ""
if [[ "$RUN_CLIENTS" == "true" ]]; then
    echo "${YELLOW}=== REPORT FINALE CLIENTI ===${NC}"
    echo "$REPORT_CLIENTS" | tail -n +2
fi
if [[ "$RUN_SERVICES" == "true" ]]; then
    echo ""
    echo "${YELLOW}=== REPORT FINALE SERVIZI ===${NC}"
    echo "$REPORT_SERVICES" | tail -n +2
fi
if [[ "$RUN_STAFF" == "true" ]]; then
    echo ""
    echo "${YELLOW}=== REPORT FINALE STAFF ===${NC}"
    echo "$REPORT_STAFF" | tail -n +2
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "${YELLOW}Questa era una simulazione (dry run).${NC}"
    echo "Esegui senza --dry-run per applicare le modifiche."
fi
