<?php
/**
 * Script per copiare i service_variants da una location ad un'altra dello stesso business.
 * 
 * Uso:
 *   php copy_services_to_location.php
 * 
 * Configurare SOURCE_LOCATION_ID e TARGET_LOCATION_ID prima di eseguire.
 */

require_once __DIR__ . '/../../vendor/autoload.php';

// ============================================
// CONFIGURAZIONE
// ============================================
$SOURCE_LOCATION_ID = 8;   // Location da cui copiare
$TARGET_LOCATION_ID = 7;   // Location in cui copiare
$DRY_RUN = false;         // true = solo anteprima, false = esegue
// ============================================

// Carica .env
$envPath = __DIR__ . '/../../.env';
if (!file_exists($envPath)) {
    die("File .env non trovato in: $envPath\n");
}

$envContent = file_get_contents($envPath);
foreach (explode("\n", $envContent) as $line) {
    $line = trim($line);
    if ($line && strpos($line, '=') !== false && $line[0] !== '#') {
        [$key, $value] = explode('=', $line, 2);
        // Rimuovi virgolette se presenti
        $value = trim($value, '"\'');
        $_ENV[$key] = $value;
    }
}

// Connessione DB diretta
$host = $_ENV['DB_HOST'] ?? 'localhost';
$port = $_ENV['DB_PORT'] ?? '3306';
$database = $_ENV['DB_DATABASE'] ?? 'agenda_core';
$username = $_ENV['DB_USERNAME'] ?? 'root';
$password = $_ENV['DB_PASSWORD'] ?? '';

$dsn = "mysql:host={$host};port={$port};dbname={$database};charset=utf8mb4";

try {
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    die("Errore connessione DB: " . $e->getMessage() . "\n");
}

// Verifica che le location appartengano allo stesso business
$stmt = $pdo->prepare("SELECT id, business_id, name FROM locations WHERE id IN (?, ?)");
$stmt->execute([$SOURCE_LOCATION_ID, $TARGET_LOCATION_ID]);
$locations = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (count($locations) !== 2) {
    die("Errore: Una o entrambe le location non esistono.\n");
}

$locationMap = [];
foreach ($locations as $loc) {
    $locationMap[$loc['id']] = $loc;
}

$sourceLocation = $locationMap[$SOURCE_LOCATION_ID] ?? null;
$targetLocation = $locationMap[$TARGET_LOCATION_ID] ?? null;

if (!$sourceLocation || !$targetLocation) {
    die("Errore: Location source o target non trovata.\n");
}

if ($sourceLocation['business_id'] !== $targetLocation['business_id']) {
    die("Errore: Le location appartengono a business diversi!\n" .
        "  Source (ID {$SOURCE_LOCATION_ID}): business_id = {$sourceLocation['business_id']}\n" .
        "  Target (ID {$TARGET_LOCATION_ID}): business_id = {$targetLocation['business_id']}\n");
}

echo "===========================================\n";
echo "  COPIA SERVIZI TRA LOCATION\n";
echo "===========================================\n\n";
echo "Business ID: {$sourceLocation['business_id']}\n";
echo "Source: {$sourceLocation['name']} (ID: $SOURCE_LOCATION_ID)\n";
echo "Target: {$targetLocation['name']} (ID: $TARGET_LOCATION_ID)\n";
echo "Modalità: " . ($DRY_RUN ? "DRY RUN (anteprima)" : "ESECUZIONE REALE") . "\n\n";

// Leggi tutti i service_variants dalla source location
$stmt = $pdo->prepare("
    SELECT sv.*, s.name as service_name, sc.name as category_name
    FROM service_variants sv
    JOIN services s ON sv.service_id = s.id
    LEFT JOIN service_categories sc ON s.category_id = sc.id
    WHERE sv.location_id = ?
    ORDER BY sc.sort_order, s.sort_order
");
$stmt->execute([$SOURCE_LOCATION_ID]);
$sourceVariants = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (empty($sourceVariants)) {
    die("Nessun service_variant trovato nella location source (ID: $SOURCE_LOCATION_ID)\n");
}

echo "Trovati " . count($sourceVariants) . " service_variants nella location source.\n\n";

// Verifica quali esistono già nella target location
$stmt = $pdo->prepare("SELECT service_id FROM service_variants WHERE location_id = ?");
$stmt->execute([$TARGET_LOCATION_ID]);
$existingServiceIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

$toInsert = [];
$skipped = [];

foreach ($sourceVariants as $sv) {
    if (in_array($sv['service_id'], $existingServiceIds)) {
        $skipped[] = $sv;
    } else {
        $toInsert[] = $sv;
    }
}

echo "Da inserire: " . count($toInsert) . "\n";
echo "Già esistenti (saltati): " . count($skipped) . "\n\n";

if (!empty($skipped)) {
    echo "--- Servizi già esistenti nella target location ---\n";
    foreach ($skipped as $sv) {
        echo "  - [{$sv['category_name']}] {$sv['service_name']}\n";
    }
    echo "\n";
}

if (empty($toInsert)) {
    echo "Nessun servizio da inserire. La target location ha già tutti i servizi.\n";
    exit(0);
}

echo "--- Servizi da copiare ---\n";
foreach ($toInsert as $sv) {
    $price = $sv['is_free'] ? 'GRATIS' : '€' . number_format($sv['price'], 2);
    echo "  - [{$sv['category_name']}] {$sv['service_name']} ({$sv['duration_minutes']} min, $price)\n";
}
echo "\n";

if ($DRY_RUN) {
    echo "=== DRY RUN: Nessuna modifica effettuata ===\n";
    exit(0);
}

// Conferma
echo "Procedere con l'inserimento? (y/N): ";
$handle = fopen("php://stdin", "r");
$input = trim(fgets($handle));
fclose($handle);

if (strtolower($input) !== 'y') {
    echo "Operazione annullata.\n";
    exit(0);
}

// Inserimento
$insertStmt = $pdo->prepare("
    INSERT INTO service_variants 
    (service_id, location_id, duration_minutes, processing_time, blocked_time, 
     price, currency, color_hex, is_bookable_online, is_free, is_price_starting_from, is_active)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
");

$inserted = 0;
$errors = 0;

foreach ($toInsert as $sv) {
    try {
        $insertStmt->execute([
            $sv['service_id'],
            $TARGET_LOCATION_ID,
            $sv['duration_minutes'],
            $sv['processing_time'],
            $sv['blocked_time'],
            $sv['price'],
            $sv['currency'],
            $sv['color_hex'],
            $sv['is_bookable_online'],
            $sv['is_free'],
            $sv['is_price_starting_from'],
            $sv['is_active']
        ]);
        $inserted++;
        echo "  ✓ {$sv['service_name']}\n";
    } catch (PDOException $e) {
        $errors++;
        echo "  ✗ {$sv['service_name']}: " . $e->getMessage() . "\n";
    }
}

echo "\n===========================================\n";
echo "  REPORT FINALE\n";
echo "===========================================\n";
echo "Inseriti: $inserted\n";
echo "Errori: $errors\n";
echo "Saltati (già esistenti): " . count($skipped) . "\n";
