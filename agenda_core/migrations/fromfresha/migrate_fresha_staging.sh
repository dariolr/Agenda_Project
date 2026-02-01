#!/bin/zsh
# =============================================================================
# Script di migrazione dati Fresha in STAGING
# =============================================================================
#
# Questo script:
# 1. Copia i file CSV e gli script PHP sul server di staging
# 2. Esegue gli script di importazione in ordine
# 3. Pulisce i file temporanei dal server
#
# PREREQUISITI:
# - Configurare config.php con business_id e location_id corretti
# - Posizionare i file CSV nella directory fromfresha/
# - Alias SSH "siteground" configurato in ~/.ssh/config
#
# USO:
#   ./migrate_fresha_staging.sh [--dry-run] [--skip-cleanup]
#
# =============================================================================

set -e  # Esci su errore

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurazione percorsi
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"
REMOTE_HOST="siteground"
REMOTE_BASE="www/api-staging.romeolab.it"
REMOTE_MIGRATIONS_DIR="${REMOTE_BASE}/migrations/fromfresha"

# File da copiare
CSV_FILES=(
    "export_customer_list.csv"
    "export_service_list.csv"
    "employees_export.csv"
)

PHP_FILES=(
    "config.php"
    "import_services.php"
    "import_staff.php"
    "import_clients.php"
)

# Parsing argomenti
DRY_RUN=false
SKIP_CLEANUP=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --skip-cleanup)
            SKIP_CLEANUP=true
            ;;
        --help|-h)
            echo "Uso: $0 [--dry-run] [--skip-cleanup]"
            echo ""
            echo "Opzioni:"
            echo "  --dry-run       Mostra cosa farebbe senza eseguire"
            echo "  --skip-cleanup  Non eliminare i file temporanei dal server"
            exit 0
            ;;
    esac
done

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
echo "  MIGRAZIONE FRESHA → ${CYAN}STAGING${NC}"
echo "=========================================="
echo ""

if $DRY_RUN; then
    log_warning "MODALITÀ DRY-RUN: nessuna operazione verrà eseguita"
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
    log_info "Esecuzione migrazione su STAGING..."
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

# 6a. Import Servizi
log_info "Importazione SERVIZI..."
if ! $DRY_RUN; then
    ssh ${REMOTE_HOST} "cd ${REMOTE_BASE} && php migrations/fromfresha/import_services.php"
fi
log_success "Servizi importati"
echo ""

# 6b. Import Staff
log_info "Importazione STAFF..."
if ! $DRY_RUN; then
    ssh ${REMOTE_HOST} "cd ${REMOTE_BASE} && php migrations/fromfresha/import_staff.php"
fi
log_success "Staff importato"
echo ""

# 6c. Import Clienti
log_info "Importazione CLIENTI..."
if ! $DRY_RUN; then
    ssh ${REMOTE_HOST} "cd ${REMOTE_BASE} && php migrations/fromfresha/import_clients.php"
fi
log_success "Clienti importati"

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
echo "${GREEN}  MIGRAZIONE STAGING COMPLETATA${NC}"
echo "=========================================="
echo ""
log_info "Verifica i dati su: https://gestionale-staging.romeolab.it"
echo ""
