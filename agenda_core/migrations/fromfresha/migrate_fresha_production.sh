#!/bin/zsh
# =============================================================================
# Script di migrazione dati Fresha in PRODUZIONE
# =============================================================================
#
# Questo script:
# 1. Copia i file CSV e gli script PHP sul server di produzione
# 2. Esegue gli script di importazione in ordine
# 3. Pulisce i file temporanei dal server
#
# PREREQUISITI:
# - Configurare config.php con business_id e location_id corretti
# - Posizionare i file CSV nella directory fromfresha/
# - Alias SSH "siteground" configurato in ~/.ssh/config
#
# USO:
#   ./migrate_fresha_production.sh [--dry-run] [--skip-cleanup] [--clients-only]
#
# =============================================================================

set -e  # Esci su errore

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurazione percorsi
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"
REMOTE_HOST="romeolab"
REMOTE_BASE="www/api.romeolab.it"
REMOTE_MIGRATIONS_DIR="${REMOTE_BASE}/migrations/fromfresha"

# Parsing argomenti
DRY_RUN=false
SKIP_CLEANUP=false
CLIENTS_ONLY=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --skip-cleanup)
            SKIP_CLEANUP=true
            ;;
        --clients-only)
            CLIENTS_ONLY=true
            ;;
        --help|-h)
            echo "Uso: $0 [--dry-run] [--skip-cleanup] [--clients-only]"
            echo ""
            echo "Opzioni:"
            echo "  --dry-run       Mostra cosa farebbe senza eseguire"
            echo "  --skip-cleanup  Non eliminare i file temporanei dal server"
            echo "  --clients-only  Esegue solo import clienti (richiede solo CSV clienti)"
            exit 0
            ;;
    esac
done

# Verifica file config
if [[ ! -f "${LOCAL_DIR}/config.php" ]]; then
    echo "${RED}[ERROR]${NC} File non trovato: config.php"
    echo "${RED}[ERROR]${NC} Percorso atteso: ${LOCAL_DIR}/config.php"
    exit 1
fi

# Leggi i nomi CSV da config.php per evitare mismatch con hardcoded.
CSV_CLIENTS=$(php -r "include '${LOCAL_DIR}/config.php'; echo FRESHA_CONFIG['csv_clients'] ?? '';")
CSV_SERVICES=$(php -r "include '${LOCAL_DIR}/config.php'; echo FRESHA_CONFIG['csv_services'] ?? '';")
CSV_STAFF=$(php -r "include '${LOCAL_DIR}/config.php'; echo FRESHA_CONFIG['csv_staff'] ?? '';")

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

if $CLIENTS_ONLY; then
    RUN_SERVICES=false
    RUN_STAFF=false
fi

# File da copiare
CSV_FILES=()
if $RUN_CLIENTS; then
    CSV_FILES+=("$CSV_CLIENTS")
fi
if $RUN_SERVICES; then
    CSV_FILES+=("$CSV_SERVICES")
fi
if $RUN_STAFF; then
    CSV_FILES+=("$CSV_STAFF")
fi

PHP_FILES=("config.php")
if $RUN_CLIENTS; then
    PHP_FILES+=("import_clients.php")
fi
if $RUN_SERVICES; then
    PHP_FILES+=("import_services.php")
fi
if $RUN_STAFF; then
    PHP_FILES+=("import_staff.php")
fi

if ! $RUN_CLIENTS; then
    echo "${YELLOW}[WARN]${NC} csv_clients non valorizzato: salto import clienti"
fi
if ! $RUN_SERVICES; then
    echo "${YELLOW}[WARN]${NC} csv_services non valorizzato o disabilitato: salto import servizi"
fi
if ! $RUN_STAFF; then
    echo "${YELLOW}[WARN]${NC} csv_staff non valorizzato o disabilitato: salto import staff"
fi
if [[ ${#CSV_FILES[@]} -eq 0 ]]; then
    echo "${RED}[ERROR]${NC} Nessun CSV configurato da processare."
    exit 1
fi

# =============================================================================
# Funzioni
# =============================================================================

log_info() {
    echo "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo "${RED}[ERROR]${NC} $1"
}

check_file_exists() {
    local file="$1"
    if [[ ! -f "${LOCAL_DIR}/${file}" ]]; then
        log_error "File non trovato: ${file}"
        return 1
    fi
    return 0
}

remote_exec() {
    local cmd="$1"
    if $DRY_RUN; then
        log_info "[DRY-RUN] ssh ${REMOTE_HOST} \"$cmd\""
    else
        ssh ${REMOTE_HOST} "$cmd"
    fi
}

remote_copy() {
    local src="$1"
    local dst="$2"
    if $DRY_RUN; then
        log_info "[DRY-RUN] scp ${src} ${REMOTE_HOST}:${dst}"
    else
        scp -q "${src}" "${REMOTE_HOST}:${dst}"
    fi
}

# =============================================================================
# Main
# =============================================================================

echo ""
echo "=========================================="
echo "  MIGRAZIONE FRESHA → PRODUZIONE"
echo "=========================================="
echo ""

if $DRY_RUN; then
    log_warning "MODALITÀ DRY-RUN: nessuna operazione verrà eseguita"
    echo ""
fi
if $CLIENTS_ONLY; then
    log_warning "MODALITÀ CLIENTI-ONLY: servizi e staff verranno saltati"
    echo ""
fi

# 1. Verifica file locali
log_info "Verifica file locali..."
missing_files=0

for file in "${CSV_FILES[@]}"; do
    if ! check_file_exists "$file"; then
        missing_files=$((missing_files + 1))
    fi
done

for file in "${PHP_FILES[@]}"; do
    if ! check_file_exists "$file"; then
        missing_files=$((missing_files + 1))
    fi
done

if [[ $missing_files -gt 0 ]]; then
    log_error "Mancano $missing_files file. Assicurati che tutti i file siano presenti in:"
    log_error "  ${LOCAL_DIR}"
    exit 1
fi
log_success "Tutti i file presenti"

# 2. Mostra configurazione
log_info "Lettura configurazione..."
echo ""
echo "  Configurazione attuale (config.php):"
grep -E "(business_id|location_id|csv_|dry_run)" "${LOCAL_DIR}/config.php" | head -10
echo ""

# 3. Info esecuzione
if ! $DRY_RUN; then
    log_warning "Esecuzione migrazione in PRODUZIONE..."
    echo ""
fi

# 4. Crea directory remota se non esiste
log_info "Creazione directory remota..."
remote_exec "mkdir -p ${REMOTE_MIGRATIONS_DIR}"
log_success "Directory pronta"

# 5. Copia file sul server
log_info "Copia file CSV sul server..."
for file in "${CSV_FILES[@]}"; do
    remote_copy "${LOCAL_DIR}/${file}" "${REMOTE_MIGRATIONS_DIR}/${file}"
    log_success "  ${file}"
done

log_info "Copia script PHP sul server..."
for file in "${PHP_FILES[@]}"; do
    remote_copy "${LOCAL_DIR}/${file}" "${REMOTE_MIGRATIONS_DIR}/${file}"
    log_success "  ${file}"
done

# 6. Esegui migrazione
echo ""
log_info "=== ESECUZIONE MIGRAZIONE ==="
echo ""

# Variabili per catturare i report
REPORT_SERVICES=""
REPORT_STAFF=""
REPORT_CLIENTS=""

# 6a. Import Servizi
if $RUN_SERVICES; then
    log_info "Importazione SERVIZI..."
    if ! $DRY_RUN; then
        OUTPUT_SERVICES=$(ssh ${REMOTE_HOST} "cd ${REMOTE_BASE} && php migrations/fromfresha/import_services.php" 2>&1)
        echo "$OUTPUT_SERVICES" | grep -v "=== REPORT FINALE" | grep -v "^Categorie inserite:" | grep -v "^Servizi inseriti:" | grep -v "^Variants inseriti:" | grep -v "^====" || true
        REPORT_SERVICES=$(echo "$OUTPUT_SERVICES" | grep -A20 "=== REPORT FINALE ===")
    fi
    log_success "Servizi importati"
    echo ""

    # 6b. Import Staff
    log_info "Importazione STAFF..."
    if ! $DRY_RUN; then
        OUTPUT_STAFF=$(ssh ${REMOTE_HOST} "cd ${REMOTE_BASE} && php migrations/fromfresha/import_staff.php" 2>&1)
        echo "$OUTPUT_STAFF" | grep -v "=== REPORT FINALE" | grep -v "^Staff inseriti:" | grep -v "^Staff disattivati:" | grep -v "^====" || true
        REPORT_STAFF=$(echo "$OUTPUT_STAFF" | grep -A20 "=== REPORT FINALE ===")
    fi
    log_success "Staff importato"
    echo ""
fi

# 6c. Import Clienti
if $RUN_CLIENTS; then
    log_info "Importazione CLIENTI..."
    if ! $DRY_RUN; then
        OUTPUT_CLIENTS=$(ssh ${REMOTE_HOST} "cd ${REMOTE_BASE} && php migrations/fromfresha/import_clients.php" 2>&1)
        echo "$OUTPUT_CLIENTS" | grep -v "=== REPORT FINALE" | grep -v "^Clienti inseriti:" | grep -v "^Duplicati email saltati:" | grep -v "^Business ID:" | grep -v "^====" || true
        REPORT_CLIENTS=$(echo "$OUTPUT_CLIENTS" | grep -A20 "=== REPORT FINALE ===")
    fi
    log_success "Clienti importati"
else
    log_info "Importazione CLIENTI saltata (csv_clients non valorizzato)"
fi

# 7. Cleanup file temporanei
echo ""
if ! $SKIP_CLEANUP; then
    log_info "Pulizia file temporanei dal server..."
    for file in "${CSV_FILES[@]}"; do
        remote_exec "rm -f ${REMOTE_MIGRATIONS_DIR}/${file}"
    done
    log_success "File CSV rimossi dal server"
else
    log_warning "Pulizia saltata (--skip-cleanup)"
fi

# 8. Riepilogo
echo ""
echo "=========================================="
echo "${GREEN}  MIGRAZIONE COMPLETATA${NC}"
echo "=========================================="
echo ""

if ! $DRY_RUN; then
    if $RUN_SERVICES; then
        echo "${YELLOW}=== REPORT FINALE SERVIZI ===${NC}"
        echo "$REPORT_SERVICES" | tail -n +2
        echo ""
    fi
    if $RUN_STAFF; then
        echo "${YELLOW}=== REPORT FINALE STAFF ===${NC}"
        echo "$REPORT_STAFF" | tail -n +2
        echo ""
    fi
    if $RUN_CLIENTS; then
        echo "${YELLOW}=== REPORT FINALE CLIENTI ===${NC}"
        echo "$REPORT_CLIENTS" | tail -n +2
        echo ""
    fi
fi

log_info "Prossimi passi:"
echo "  1. Verificare i dati importati nel gestionale"
if $RUN_SERVICES || $RUN_STAFF; then
    echo "  2. Configurare le abilitazioni staff-servizi"
    echo "  3. Impostare i planning settimanali dello staff"
fi
echo ""
