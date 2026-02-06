<?php
/**
 * Script di importazione servizi da CSV Fresha
 * 
 * Usage: php import_services.php
 */

$rootDir = __DIR__ . '/../../';
require_once $rootDir . 'vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable($rootDir);
$dotenv->load();

// Carica configurazione centralizzata
$config = require __DIR__ . '/config.php';
$BUSINESS_ID = $config['business_id'];
$LOCATION_ID = $config['location_id'];
$CSV_FILE = $config['csv_services'];
$DRY_RUN = $config['dry_run'];
$CLEAR_EXISTING = $config['clear_existing_data'] ?? false;

echo "=== IMPORTAZIONE SERVIZI FRESHA ===\n";
echo "Business ID: {$BUSINESS_ID}\n";
echo "Location ID: {$LOCATION_ID}\n";
echo "File CSV: {$CSV_FILE}\n";
echo "Dry run: " . ($DRY_RUN ? 'Sì' : 'No') . "\n";
echo "Pulisci dati esistenti: " . ($CLEAR_EXISTING ? 'Sì' : 'No') . "\n";
echo "===================================\n\n";

$port = $_ENV['DB_PORT'] ?? 3306;
$host = $_ENV['DB_HOST'] === 'localhost' ? '127.0.0.1' : $_ENV['DB_HOST'];
$pdo = new PDO(
    "mysql:host={$host};port={$port};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD'],
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

// Colori per categoria (palette ufficiale)
$CATEGORY_COLORS = [
    '#FFCDD2', // Reds
    '#FFD6B3', // Oranges
    '#FFF0B3', // Yellows
    '#EAF2B3', // Yellow-greens
    '#CDECCF', // Greens
    '#BFE8E0', // Teals
    '#BDEFF4', // Cyans
    '#BFD9FF', // Blues
    '#C7D0FF', // Indigos
    '#DCC9FF', // Purples
    '#FFC7E3', // Pinks
];

// Leggi CSV
$csv = array_map(function($line) {
    return str_getcsv($line);
}, file(__DIR__ . '/' . $CSV_FILE));

$header = array_shift($csv); // rimuovi header

// Filtra righe vuote e servizi senza Risorsa (colonna 8)
$services = array_filter($csv, function($row) {
    return !empty($row[0]) && isset($row[8]) && !empty(trim($row[8] ?? ''));
});

// Estrai categorie uniche in ordine di apparizione
// Mappa: nome originale CSV -> nome formattato MAIUSCOLO
$categories = [];        // nomi formattati (MAIUSCOLO)
$categoryOriginal = [];  // mappa originale -> formattato
$categoryOrder = [];
foreach ($services as $row) {
    $catOriginal = trim($row[6]);
    $catFormatted = formatCategoryName($catOriginal);
    if (!empty($catOriginal) && !in_array($catFormatted, $categories)) {
        $categories[] = $catFormatted;
        $categoryOrder[$catFormatted] = count($categories) - 1;
    }
    // Mappa sempre l'originale al formattato per lookup successivo
    if (!empty($catOriginal)) {
        $categoryOriginal[$catOriginal] = $catFormatted;
    }
}

echo "Categorie trovate: " . count($categories) . "\n";
print_r($categories);

// Mappa categoria -> colore
$categoryColorMap = [];
foreach ($categories as $idx => $cat) {
    $categoryColorMap[$cat] = $CATEGORY_COLORS[$idx % count($CATEGORY_COLORS)];
}

echo "\nMappa colori:\n";
print_r($categoryColorMap);

// Cleanup (solo se richiesto)
if ($CLEAR_EXISTING && !$DRY_RUN) {
    echo "\nCleanup in corso...\n";
    // Prima elimina booking_items che referenziano service_variants (ignora se tabella non esiste)
    try {
        $pdo->exec("DELETE bi FROM booking_items bi 
                    JOIN service_variants sv ON bi.service_variant_id = sv.id 
                    WHERE sv.location_id = $LOCATION_ID");
    } catch (PDOException $e) {
        echo "  (booking_items skipped)\n";
    }
    $pdo->exec("DELETE FROM service_variants WHERE location_id = $LOCATION_ID");
    $pdo->exec("DELETE FROM services WHERE business_id = $BUSINESS_ID");
    $pdo->exec("DELETE FROM service_categories WHERE business_id = $BUSINESS_ID");
    echo "Cleanup completato.\n";
}

// Inserisci categorie
echo "\nInserimento categorie...\n";
$categoryIds = [];
$stmt = $pdo->prepare("INSERT INTO service_categories (business_id, name, sort_order) VALUES (?, ?, ?)");
foreach ($categories as $idx => $cat) {
    $stmt->execute([$BUSINESS_ID, $cat, $idx]);
    $categoryIds[$cat] = $pdo->lastInsertId();
    echo "  - $cat (ID: {$categoryIds[$cat]})\n";
}

// Funzione per convertire durata
function parseDuration($str) {
    $minutes = 0;
    if (preg_match('/(\d+)h/', $str, $m)) $minutes += intval($m[1]) * 60;
    if (preg_match('/(\d+)m/', $str, $m)) $minutes += intval($m[1]);
    return $minutes ?: 30; // default 30 min
}

// Funzione per estrarre tempo supplementare
function parseProcessingTime($str) {
    $minutes = 0;
    if (preg_match('/(\d+)h/', $str, $m)) $minutes += intval($m[1]) * 60;
    if (preg_match('/(\d+)m/', $str, $m)) $minutes += intval($m[1]);
    return $minutes;
}

// Funzione per formattare categoria (MAIUSCOLO)
function formatCategoryName($name) {
    return mb_strtoupper(trim($name), 'UTF-8');
}

// Funzione per formattare nome servizio (Capitalizzato)
// Prima aggiunge spazi intorno al + se mancanti, poi capitalizza ogni parola
function formatServiceName($name) {
    $name = trim($name);
    // Aggiungi spazio prima del + se manca (ma non se già presente)
    $name = preg_replace('/(?<!\s)\+/', ' +', $name);
    // Aggiungi spazio dopo il + se manca (ma non se già presente)
    $name = preg_replace('/\+(?!\s)/', '+ ', $name);
    // Capitalizza ogni parola
    return mb_convert_case($name, MB_CASE_TITLE, 'UTF-8');
}

// Inserisci servizi
echo "\nInserimento servizi...\n";
$stmtService = $pdo->prepare("INSERT INTO services (business_id, category_id, name, description, sort_order, is_active) VALUES (?, ?, ?, ?, ?, 1)");
$stmtVariant = $pdo->prepare("INSERT INTO service_variants (service_id, location_id, duration_minutes, processing_time, blocked_time, price, currency, color_hex, is_bookable_online, is_free, is_price_starting_from, is_active) VALUES (?, ?, ?, ?, 0, ?, '€', ?, ?, ?, ?, 1)");

$serviceCount = 0;
$variantCount = 0;

foreach ($services as $idx => $row) {
    $nameRaw = trim($row[0]);
    $price = floatval(str_replace(',', '.', $row[1]));
    $duration = parseDuration($row[2]);
    $processingTime = parseProcessingTime($row[3]);
    $description = trim($row[5]) ?: null;
    $categoryOriginalName = trim($row[6]);
    $isBookableOnline = (trim($row[9]) === 'Abilitati') ? 1 : 0;
    
    // Check "- From" per prezzo a partire da (prima della formattazione)
    $isPriceFrom = 0;
    if (preg_match('/\s*-\s*From$/i', $nameRaw)) {
        $isPriceFrom = 1;
        $nameRaw = preg_replace('/\s*-\s*From$/i', '', $nameRaw);
    }
    
    // Formatta nome servizio (spazi intorno a + e capitalizzazione)
    $name = formatServiceName($nameRaw);
    
    $isFree = ($price == 0) ? 1 : 0;
    // Usa la mappa originale -> formattato per trovare la categoria
    $categoryFormatted = $categoryOriginal[$categoryOriginalName] ?? null;
    $categoryId = $categoryFormatted ? ($categoryIds[$categoryFormatted] ?? null) : null;
    $colorHex = $categoryFormatted ? ($categoryColorMap[$categoryFormatted] ?? '#BFD9FF') : '#BFD9FF';
    
    // Inserisci servizio
    $stmtService->execute([$BUSINESS_ID, $categoryId, $name, $description, $idx]);
    $serviceId = $pdo->lastInsertId();
    $serviceCount++;
    
    // Inserisci variante
    $stmtVariant->execute([
        $serviceId,
        $LOCATION_ID,
        $duration,
        $processingTime,
        $price,
        $colorHex,
        $isBookableOnline,
        $isFree,
        $isPriceFrom
    ]);
    $variantCount++;
    
    echo "  [$serviceCount] $name - $duration min - EUR $price - $colorHex\n";
}

echo "\n=== REPORT FINALE ===\n";
echo "Categorie inserite: " . count($categories) . "\n";
echo "Servizi inseriti: $serviceCount\n";
echo "Varianti inserite: $variantCount\n";
echo "=====================\n";
