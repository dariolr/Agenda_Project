#!/bin/bash

# =============================================================================
# Deploy Locale - Flutter Projects su MAMP
# =============================================================================
# Questo script builda e deploya i progetti Flutter su MAMP locale
# 
# Uso:
#   ./deploy-local.sh           # Deploy entrambi i progetti
#   ./deploy-local.sh frontend  # Solo agenda_frontend (prenota)
#   ./deploy-local.sh backend   # Solo agenda_backend (gestionale)
#   ./deploy-local.sh api       # Solo agenda_core (API PHP)
#   ./deploy-local.sh all       # Tutto (frontend + backend + api)
# =============================================================================

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurazione
MAMP_HTDOCS="/Applications/MAMP/htdocs"
PROJECT_ROOT="/Users/dariolarosa/Documents/Romeo_lab/Agenda_Project"
API_BASE_URL="http://localhost:8888/api"

# Cartelle destinazione
FRONTEND_DEST="$MAMP_HTDOCS/prenota"
BACKEND_DEST="$MAMP_HTDOCS/gestionale"
API_DEST="$MAMP_HTDOCS/api"

# Funzione per stampare messaggi
print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verifica MAMP
check_mamp() {
    if [ ! -d "$MAMP_HTDOCS" ]; then
        print_error "MAMP htdocs non trovata: $MAMP_HTDOCS"
        exit 1
    fi
    print_success "MAMP htdocs trovata"
}

# Crea .htaccess per SPA routing
create_htaccess() {
    local dest=$1
    cat > "$dest/.htaccess" << 'EOF'
RewriteEngine On

# Se il file o directory richiesta esiste, servila direttamente
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d

# Altrimenti, reindirizza tutto a index.html
RewriteRule ^ index.html [L]
EOF
}

# Deploy agenda_frontend
deploy_frontend() {
    print_step "Deploying agenda_frontend (prenota)..."
    
    cd "$PROJECT_ROOT/agenda_frontend"
    
    # Build con base-href corretto per sottocartella
    print_step "Building Flutter web..."
    flutter build web --release --base-href=/prenota/ --dart-define=API_BASE_URL=$API_BASE_URL
    
    # Crea cartella se non esiste
    mkdir -p "$FRONTEND_DEST"
    
    # Pulisci e copia
    rm -rf "$FRONTEND_DEST"/*
    cp -r build/web/* "$FRONTEND_DEST/"
    
    # Crea .htaccess per SPA routing
    create_htaccess "$FRONTEND_DEST"
    
    print_success "agenda_frontend deployato su $FRONTEND_DEST"
    print_success "URL: http://localhost:8888/prenota/"
}

# Deploy agenda_backend
deploy_backend() {
    print_step "Deploying agenda_backend (gestionale)..."
    
    cd "$PROJECT_ROOT/agenda_backend"
    
    # Build con base-href corretto per sottocartella
    print_step "Building Flutter web..."
    flutter build web --release --base-href=/gestionale/ --dart-define=API_BASE_URL=$API_BASE_URL
    
    # Crea cartella se non esiste
    mkdir -p "$BACKEND_DEST"
    
    # Pulisci e copia
    rm -rf "$BACKEND_DEST"/*
    cp -r build/web/* "$BACKEND_DEST/"
    
    # Crea .htaccess per SPA routing
    create_htaccess "$BACKEND_DEST"
    
    print_success "agenda_backend deployato su $BACKEND_DEST"
    print_success "URL: http://localhost:8888/gestionale/"
}

# Deploy agenda_core (API)
deploy_api() {
    print_step "Deploying agenda_core (API)..."
    
    # Struttura identica a produzione:
    # api/
    # ├── public/     <- document root (index.php, .htaccess)
    # ├── src/
    # ├── vendor/
    # └── .env
    
    # Crea struttura cartelle
    mkdir -p "$API_DEST/public"
    
    # Copia public/ (index.php originale, .htaccess)
    print_step "Copiando file PHP..."
    cp "$PROJECT_ROOT/agenda_core/public/index.php" "$API_DEST/public/"
    cp "$PROJECT_ROOT/agenda_core/public/.htaccess" "$API_DEST/public/"
    
    # Copia src e vendor a livello superiore (come in produzione)
    rm -rf "$API_DEST/src"
    rm -rf "$API_DEST/vendor"
    cp -r "$PROJECT_ROOT/agenda_core/src" "$API_DEST/"
    cp -r "$PROJECT_ROOT/agenda_core/vendor" "$API_DEST/"
    
    # Copia .env nella root (come in produzione)
    if [ -f "$PROJECT_ROOT/agenda_core/.env.local" ]; then
        cp "$PROJECT_ROOT/agenda_core/.env.local" "$API_DEST/.env"
        print_success "Copiato .env.local come .env"
    elif [ ! -f "$API_DEST/.env" ]; then
        print_warning ".env non trovato! Crea $API_DEST/.env con le credenziali del database locale"
    fi
    
    # Crea .htaccess nella root per redirigere a public/index.php
    cat > "$API_DEST/.htaccess" << 'HTACCESSEOF'
RewriteEngine On

# Se il file esiste in public/, servilo
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{DOCUMENT_ROOT}/api/public%{REQUEST_URI} -f
RewriteRule ^(.*)$ public/$1 [L]

# Altrimenti, passa tutto a public/index.php
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ public/index.php [QSA,L]
HTACCESSEOF
    
    print_success "agenda_core deployato su $API_DEST"
    print_success "URL: http://localhost:8888/api/"
}

# Main
echo ""
echo "=========================================="
echo "  Deploy Locale su MAMP"
echo "=========================================="
echo ""

check_mamp

case "${1:-both}" in
    frontend|f)
        deploy_frontend
        ;;
    backend|b)
        deploy_backend
        ;;
    api|a)
        deploy_api
        ;;
    all)
        deploy_api
        deploy_frontend
        deploy_backend
        ;;
    both|"")
        deploy_frontend
        deploy_backend
        ;;
    *)
        echo "Uso: $0 [frontend|backend|api|all|both]"
        echo ""
        echo "  frontend (f) - Solo agenda_frontend (prenota)"
        echo "  backend (b)  - Solo agenda_backend (gestionale)"
        echo "  api (a)      - Solo agenda_core (API PHP)"
        echo "  all          - Tutti e tre i progetti"
        echo "  both         - Frontend + Backend (default)"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo -e "${GREEN}  Deploy completato!${NC}"
echo "=========================================="
echo ""
echo "URL locali:"
echo "  - Prenotazioni: http://localhost:8888/prenota/"
echo "  - Gestionale:   http://localhost:8888/gestionale/"
echo "  - API:          http://localhost:8888/api/"
echo ""
