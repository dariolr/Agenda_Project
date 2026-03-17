<?php
/**
 * Script per duplicare gli staff di una location in un'altra dello stesso business.
 * 
 * Crea NUOVI record staff (copie) e li associa alla target location.
 * Utile quando si vogliono orari di lavoro diversi per sede.
 * 
 * Uso:
 *   php duplicate_staff_to_location.php
 * 
 * Configurare SOURCE_LOCATION_ID e TARGET_LOCATION_ID prima di eseguire.
 */

require_once __DIR__ . '/../../vendor/autoload.php';

// ============================================
// CONFIGURAZIONE
// ============================================
$SOURCE_LOCATION_ID = 8;   // Location da cui copiare
$TARGET_LOCATION_ID = 7;   // Location in cui creare copie
$DRY_RUN = false;         // true = solo anteprima, false = esegue
$NAME_SUFFIX = '';        // Suffisso da aggiungere al nome (es. " - P.Roma")
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
    die("Errore: Le location appartengono a business diversi!\n");
}

$businessId = $sourceLocation['business_id'];

echo "===========================================\n";
echo "  DUPLICA STAFF PER NUOVA LOCATION\n";
echo "===========================================\n\n";
echo "Business ID: {$businessId}\n";
echo "Source: {$sourceLocation['name']} (ID: $SOURCE_LOCATION_ID)\n";
echo "Target: {$targetLocation['name']} (ID: $TARGET_LOCATION_ID)\n";
echo "Suffisso nome: " . ($NAME_SUFFIX ?: "(nessuno)") . "\n";
echo "Modalità: " . ($DRY_RUN ? "DRY RUN (anteprima)" : "ESECUZIONE REALE") . "\n\n";

// Leggi tutti gli staff associati alla source location
$stmt = $pdo->prepare("
    SELECT s.*
    FROM staff s
    JOIN staff_locations sl ON s.id = sl.staff_id
    WHERE sl.location_id = ? AND s.business_id = ?
    ORDER BY s.sort_order, s.name
");
$stmt->execute([$SOURCE_LOCATION_ID, $businessId]);
$sourceStaff = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (empty($sourceStaff)) {
    die("Nessuno staff trovato associato alla location source (ID: $SOURCE_LOCATION_ID)\n");
}

echo "Trovati " . count($sourceStaff) . " staff nella location source.\n\n";

// Verifica quali nomi esistono già nella target location (per evitare duplicati di nome)
$stmt = $pdo->prepare("
    SELECT s.name, s.surname
    FROM staff s
    JOIN staff_locations sl ON s.id = sl.staff_id
    WHERE sl.location_id = ? AND s.business_id = ?
");
$stmt->execute([$TARGET_LOCATION_ID, $businessId]);
$existingNames = [];
foreach ($stmt->fetchAll() as $row) {
    $existingNames[] = strtolower(trim($row['name'] . ' ' . $row['surname']));
}

$toDuplicate = [];
$skipped = [];

foreach ($sourceStaff as $staff) {
    $newName = $staff['name'] . $NAME_SUFFIX;
    $fullName = strtolower(trim($newName . ' ' . $staff['surname']));
    
    if (in_array($fullName, $existingNames)) {
        $skipped[] = $staff;
    } else {
        $staff['new_name'] = $newName;
        $toDuplicate[] = $staff;
    }
}

echo "Da duplicare: " . count($toDuplicate) . "\n";
echo "Già esistenti (saltati): " . count($skipped) . "\n\n";

if (!empty($skipped)) {
    echo "--- Staff già esistenti nella target location ---\n";
    foreach ($skipped as $staff) {
        $fullName = trim($staff['name'] . ' ' . $staff['surname']);
        echo "  - {$fullName}\n";
    }
    echo "\n";
}

if (empty($toDuplicate)) {
    echo "Nessuno staff da duplicare. La target location ha già tutti gli staff.\n";
    exit(0);
}

echo "--- Staff da duplicare ---\n";
foreach ($toDuplicate as $staff) {
    $oldName = trim($staff['name'] . ' ' . $staff['surname']);
    $newName = trim($staff['new_name'] . ' ' . $staff['surname']);
    echo "  - {$oldName} → {$newName}\n";
}
echo "\n";

if ($DRY_RUN) {
    echo "=== DRY RUN: Nessuna modifica effettuata ===\n";
    exit(0);
}

// Conferma
echo "Procedere con la duplicazione? (y/N): ";
$handle = fopen("php://stdin", "r");
$input = trim(fgets($handle));
fclose($handle);

if (strtolower($input) !== 'y') {
    echo "Operazione annullata.\n";
    exit(0);
}

// Inserimento
$insertStaffStmt = $pdo->prepare("
    INSERT INTO staff 
    (business_id, name, surname, color_hex, avatar_url, sort_order, is_default, is_bookable_online, is_active)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
");

$insertLocationStmt = $pdo->prepare("
    INSERT INTO staff_locations (staff_id, location_id) VALUES (?, ?)
");

$insertServiceStmt = $pdo->prepare("
    INSERT INTO staff_services (staff_id, service_id) VALUES (?, ?)
");

$getServicesStmt = $pdo->prepare("
    SELECT service_id FROM staff_services WHERE staff_id = ?
");

$inserted = 0;
$errors = 0;

foreach ($toDuplicate as $staff) {
    $oldName = trim($staff['name'] . ' ' . $staff['surname']);
    $newName = trim($staff['new_name'] . ' ' . $staff['surname']);
    
    try {
        $pdo->beginTransaction();
        
        // Crea nuovo staff
        $insertStaffStmt->execute([
            $businessId,
            $staff['new_name'],
            $staff['surname'],
            $staff['color_hex'],
            $staff['avatar_url'],
            $staff['sort_order'],
            0, // is_default = false per le copie
            $staff['is_bookable_online'],
            $staff['is_active']
        ]);
        
        $newStaffId = (int) $pdo->lastInsertId();
        
        // Associa alla target location
        $insertLocationStmt->execute([$newStaffId, $TARGET_LOCATION_ID]);
        
        // Copia associazioni servizi
        $getServicesStmt->execute([$staff['id']]);
        $serviceIds = $getServicesStmt->fetchAll(PDO::FETCH_COLUMN);
        foreach ($serviceIds as $serviceId) {
            $insertServiceStmt->execute([$newStaffId, $serviceId]);
        }
        
        $pdo->commit();
        
        $inserted++;
        $serviceCount = count($serviceIds);
        echo "  ✓ {$newName} (ID: {$newStaffId}, {$serviceCount} servizi)\n";
        
    } catch (PDOException $e) {
        $pdo->rollBack();
        $errors++;
        echo "  ✗ {$oldName}: " . $e->getMessage() . "\n";
    }
}

echo "\n===========================================\n";
echo "  REPORT FINALE\n";
echo "===========================================\n";
echo "Duplicati: $inserted\n";
echo "Errori: $errors\n";
echo "Saltati (già esistenti): " . count($skipped) . "\n";
echo "\nNOTA: Il planning (orari di lavoro) NON viene copiato.\n";
echo "Dovrai configurare manualmente gli orari per i nuovi staff.\n";
