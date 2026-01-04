<?php
require_once __DIR__ . '/vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

$pdo = new PDO(
    "mysql:host={$_ENV['DB_HOST']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD'],
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$BUSINESS_ID = 1;
$LOCATION_ID = 4;

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
}, file(__DIR__ . '/export_service_list_2026-01-01.csv'));

$header = array_shift($csv); // rimuovi header

// Filtra righe vuote e servizi senza Risorsa (colonna 8)
$services = array_filter($csv, function($row) {
    return !empty($row[0]) && !empty(trim($row[8]));
});

// Estrai categorie uniche in ordine di apparizione
$categories = [];
$categoryOrder = [];
foreach ($services as $row) {
    $cat = trim($row[6]);
    if (!empty($cat) && !in_array($cat, $categories)) {
        $categories[] = $cat;
        $categoryOrder[$cat] = count($categories) - 1;
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

// Cleanup
echo "\nCleanup in corso...\n";
$pdo->exec("DELETE FROM service_variants WHERE location_id = $LOCATION_ID");
$pdo->exec("DELETE FROM services WHERE business_id = $BUSINESS_ID");
$pdo->exec("DELETE FROM service_categories WHERE business_id = $BUSINESS_ID");
echo "Cleanup completato.\n";

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
    if (preg_match('/(\d+)m/', $str, $m)) return intval($m[1]);
    return 0;
}

// Inserisci servizi
echo "\nInserimento servizi...\n";
$stmtService = $pdo->prepare("INSERT INTO services (business_id, category_id, name, description, sort_order, is_active) VALUES (?, ?, ?, ?, ?, 1)");
$stmtVariant = $pdo->prepare("INSERT INTO service_variants (service_id, location_id, duration_minutes, processing_time, blocked_time, price, currency, color_hex, is_bookable_online, is_free, is_price_starting_from, is_active) VALUES (?, ?, ?, ?, 0, ?, '€', ?, ?, ?, ?, 1)");

$serviceCount = 0;
$variantCount = 0;

foreach ($services as $idx => $row) {
    $name = trim($row[0]);
    $price = floatval(str_replace(',', '.', $row[1]));
    $duration = parseDuration($row[2]);
    $processingTime = parseProcessingTime($row[3]);
    $description = trim($row[5]) ?: null;
    $category = trim($row[6]);
    $isBookableOnline = (trim($row[9]) === 'Abilitati') ? 1 : 0;
    
    // Check "- From" per prezzo a partire da
    $isPriceFrom = 0;
    if (preg_match('/\s*-\s*From$/i', $name)) {
        $isPriceFrom = 1;
        $name = preg_replace('/\s*-\s*From$/i', '', $name);
    }
    
    $isFree = ($price == 0) ? 1 : 0;
    $categoryId = $categoryIds[$category] ?? null;
    $colorHex = $categoryColorMap[$category] ?? '#BFD9FF';
    
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
