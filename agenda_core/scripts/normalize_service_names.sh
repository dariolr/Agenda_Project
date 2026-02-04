#!/bin/zsh
# =============================================================================
# Script di normalizzazione nomi servizi e package in PRODUZIONE
# =============================================================================
#
# Esegue:
# 1. Servizi: Title Case (prima lettera maiuscola per ogni parola)
# 2. Package: Title Case (prima lettera maiuscola per ogni parola)
# 3. Normalizza "piega+colore" → "Piega + Colore" (spazi attorno al +)
#
# NOTE: Le categorie NON vengono modificate
#
# USO:
#   ./normalize_service_names.sh [--dry-run]
#
# =============================================================================

set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurazione
REMOTE_HOST="romeolab"
REMOTE_BASE="www/api.romeolab.it"

# Parsing argomenti
DRY_RUN=false
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            echo "Uso: $0 [--dry-run]"
            echo ""
            echo "Opzioni:"
            echo "  --dry-run    Mostra le query senza eseguirle"
            exit 0
            ;;
    esac
done

echo ""
echo "=========================================="
echo "  NORMALIZZAZIONE NOMI SERVIZI E PACKAGE"
echo "=========================================="
echo ""

if $DRY_RUN; then
    echo "${YELLOW}[DRY-RUN] Nessuna modifica verrà eseguita${NC}"
    echo ""
fi

# Crea script PHP temporaneo
PHP_SCRIPT=$(cat << 'PHPCODE'
<?php
/**
 * Normalizzazione nomi servizi e categorie
 */

require_once __DIR__ . '/vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

$dryRun = in_array('--dry-run', $argv);

try {
    $dsn = sprintf(
        'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
        $_ENV['DB_HOST'],
        $_ENV['DB_PORT'] ?? '3306',
        $_ENV['DB_DATABASE']
    );
    $pdo = new PDO($dsn, $_ENV['DB_USERNAME'], $_ENV['DB_PASSWORD'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    echo "Connessione DB OK\n\n";

    // Funzione per Title Case con gestione del +
    function titleCase(string $str): string {
        // Prima normalizza spazi attorno a + e -
        $str = preg_replace('/\s*\+\s*/', ' + ', $str);
        $str = preg_replace('/\s*-\s*/', ' - ', $str);
        
        // Rimuovi spazi multipli
        $str = preg_replace('/\s+/', ' ', trim($str));
        
        // Title case: prima lettera maiuscola di ogni parola
        $words = explode(' ', $str);
        $result = [];
        foreach ($words as $word) {
            if ($word === '+' || $word === '-' || $word === '&') {
                $result[] = $word;
            } else {
                $result[] = mb_convert_case($word, MB_CASE_TITLE, 'UTF-8');
            }
        }
        return implode(' ', $result);
    }

    // ========================================
    // SERVIZI → Title Case
    // ========================================
    echo "\n=== SERVIZI (→ Title Case) ===\n";
    
    $stmt = $pdo->query('SELECT id, name FROM services ORDER BY id');
    $services = $stmt->fetchAll();
    
    $svcUpdated = 0;
    foreach ($services as $svc) {
        $oldName = $svc['name'];
        $newName = titleCase($oldName);
        
        if ($oldName !== $newName) {
            echo "  [{$svc['id']}] \"{$oldName}\" → \"{$newName}\"\n";
            
            if (!$dryRun) {
                $update = $pdo->prepare('UPDATE services SET name = ? WHERE id = ?');
                $update->execute([$newName, $svc['id']]);
            }
            $svcUpdated++;
        }
    }
    
    if ($svcUpdated === 0) {
        echo "  Nessun servizio da aggiornare\n";
    } else {
        echo "\n  Servizi aggiornati: {$svcUpdated}\n";
    }

    // ========================================
    // PACKAGE → Title Case
    // ========================================
    echo "\n=== PACKAGE (→ Title Case) ===\n";
    
    $stmt = $pdo->query('SELECT id, name FROM service_packages ORDER BY id');
    $packages = $stmt->fetchAll();
    
    $pkgUpdated = 0;
    foreach ($packages as $pkg) {
        $oldName = $pkg['name'];
        $newName = titleCase($oldName);
        
        if ($oldName !== $newName) {
            echo "  [{$pkg['id']}] \"{$oldName}\" → \"{$newName}\"\n";
            
            if (!$dryRun) {
                $update = $pdo->prepare('UPDATE service_packages SET name = ? WHERE id = ?');
                $update->execute([$newName, $pkg['id']]);
            }
            $pkgUpdated++;
        }
    }
    
    if ($pkgUpdated === 0) {
        echo "  Nessun package da aggiornare\n";
    } else {
        echo "\n  Package aggiornati: {$pkgUpdated}\n";
    }

    // ========================================
    // RIEPILOGO
    // ========================================
    echo "\n=== RIEPILOGO ===\n";
    echo "Servizi aggiornati: {$svcUpdated}\n";
    echo "Package aggiornati: {$pkgUpdated}\n";
    
    if ($dryRun) {
        echo "\n[DRY-RUN] Nessuna modifica effettuata.\n";
    } else {
        echo "\nNormalizzazione completata!\n";
    }

} catch (Exception $e) {
    echo "ERRORE: " . $e->getMessage() . "\n";
    exit(1);
}
PHPCODE
)

# Copia lo script PHP sul server e eseguilo
echo "${BLUE}[INFO]${NC} Creazione script PHP temporaneo..."

if $DRY_RUN; then
    echo "$PHP_SCRIPT" | ssh ${REMOTE_HOST} "cat > ${REMOTE_BASE}/normalize_names_temp.php && cd ${REMOTE_BASE} && php normalize_names_temp.php --dry-run && rm normalize_names_temp.php"
else
    echo "$PHP_SCRIPT" | ssh ${REMOTE_HOST} "cat > ${REMOTE_BASE}/normalize_names_temp.php && cd ${REMOTE_BASE} && php normalize_names_temp.php && rm normalize_names_temp.php"
fi

echo ""
echo "=========================================="
echo "${GREEN}  COMPLETATO${NC}"
echo "=========================================="
