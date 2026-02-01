<?php
/**
 * Script di importazione staff da CSV Fresha
 * Assegna colori dalla palette ufficiale staff in ordine sequenziale
 * 
 * Usage: php import_staff.php
 */

require_once __DIR__ . '/../../vendor/autoload.php';

// Carica .env dalla root del progetto
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/../../');
$dotenv->load();

// Configurazione
const BUSINESS_ID = 5;
const LOCATION_ID = 5;
// CSV nella stessa directory dello script sul server
const CSV_FILE = 'employees_export.csv';

// Palette colori staff (36 colori, ordine dalla UI Flutter)
const STAFF_COLORS = [
    '#FFC400', // 0 - Giallo
    '#FFA000', // 1 - Amber
    '#FF6D00', // 2 - Arancione
    '#FF3D00', // 3 - Arancione scuro
    '#D50000', // 4 - Rosso
    '#B71C1C', // 5 - Rosso scuro
    '#F50057', // 6 - Magenta
    '#C51162', // 7 - Rosa
    '#AA00FF', // 8 - Viola
    '#6200EA', // 9 - Viola scuro
    '#304FFE', // 10 - Indaco
    '#1A237E', // 11 - Indaco scuro
    '#2962FF', // 12 - Blu
    '#1565C0', // 13 - Blu scuro
    '#0091EA', // 14 - Azzurro
    '#00B0FF', // 15 - Azzurro chiaro
    '#00B8D4', // 16 - Ciano
    '#00838F', // 17 - Ciano scuro
    '#00BFA5', // 18 - Teal
    '#00796B', // 19 - Teal scuro
    '#00C853', // 20 - Verde
    '#2E7D32', // 21 - Verde scuro
    '#76FF03', // 22 - Lime
    '#AEEA00', // 23 - Verde acido
    '#FF9100', // 24 - Arancione extra
    '#E65100', // 25 - Arancione bruciato
    '#AD1457', // 26 - Rosa scuro
    '#7B1FA2', // 27 - Viola extra
    '#3949AB', // 28 - Indaco extra
    '#00897B', // 29 - Teal extra
    '#43A047', // 30 - Verde extra
    '#558B2F', // 31 - Verde oliva
    '#01579B', // 32 - Blu navy
    '#006064', // 33 - Ciano scuro extra
    '#4E342E', // 34 - Marrone
    '#37474F', // 35 - Grigio blu
];

try {
    // Connessione DB
    $pdo = new PDO(
        "mysql:host={$_ENV['DB_HOST']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
        $_ENV['DB_USERNAME'],
        $_ENV['DB_PASSWORD'],
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    
    echo "Connessione DB OK\n\n";
    
    // Leggi CSV
    $csvPath = __DIR__ . '/' . CSV_FILE;
    if (!file_exists($csvPath)) {
        throw new Exception("File CSV non trovato: " . CSV_FILE);
    }
    
    $handle = fopen($csvPath, 'r');
    $headers = fgetcsv($handle); // Prima riga = headers
    
    echo "Headers CSV: " . implode(', ', $headers) . "\n\n";
    
    // Funzione helper per cercare colonne con nomi alternativi (IT/EN)
    function findColumn(array $headers, array $names): int|false {
        foreach ($names as $name) {
            $idx = array_search($name, $headers);
            if ($idx !== false) return $idx;
        }
        return false;
    }
    
    // Trova indici colonne (supporta IT e EN)
    $colFirstName = findColumn($headers, ['First Name', 'Nome']);
    $colLastName = findColumn($headers, ['Last Name', 'Cognome']);
    $colEmail = findColumn($headers, ['Email']);
    $colStatus = findColumn($headers, ['Status', 'Stato']);
    $colAppointments = findColumn($headers, ['Appointments', 'Appuntamenti']);
    $colJobTitle = findColumn($headers, ['Job Title', 'Posizione lavorativa']);
    
    if ($colFirstName === false || $colStatus === false || $colAppointments === false) {
        throw new Exception("Colonne obbligatorie non trovate nel CSV");
    }
    
    // Raccogli staff da importare
    $staffToImport = [];
    while (($row = fgetcsv($handle)) !== false) {
        $status = trim($row[$colStatus] ?? '');
        $appointments = trim($row[$colAppointments] ?? '');
        
        // Filtra: solo Active/Attivo + Enabled/Abilitati
        $isActive = in_array($status, ['Active', 'Attivo']);
        $isEnabled = in_array($appointments, ['Enabled', 'Abilitati']);
        if (!$isActive || !$isEnabled) {
            continue;
        }
        
        $staffToImport[] = [
            'first_name' => trim($row[$colFirstName] ?? ''),
            'last_name' => trim($row[$colLastName] ?? ''),
            'email' => trim($row[$colEmail] ?? ''),
            'job_title' => trim($row[$colJobTitle] ?? ''),
        ];
    }
    fclose($handle);
    
    echo "Staff da importare: " . count($staffToImport) . "\n";
    foreach ($staffToImport as $i => $s) {
        $color = STAFF_COLORS[$i % count(STAFF_COLORS)];
        echo "  $i. {$s['first_name']} {$s['last_name']} → $color\n";
    }
    echo "\n";
    
    if (empty($staffToImport)) {
        echo "Nessuno staff da importare.\n";
        exit(0);
    }
    
    // Inizia transazione
    $pdo->beginTransaction();
    
    // GESTISCE staff esistenti per il business
    // Staff con booking esistenti: soft delete (is_active=0, is_bookable_online=0)
    // Staff senza booking: elimina fisicamente
    $stmt = $pdo->query("SELECT id FROM staff WHERE business_id = " . BUSINESS_ID);
    $existingStaffIds = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    if (!empty($existingStaffIds)) {
        $idList = implode(',', $existingStaffIds);
        echo "Gestione staff esistenti (ID: $idList)...\n";
        
        // Trova staff con booking (non eliminabili)
        $stmt = $pdo->query("SELECT DISTINCT staff_id FROM booking_items WHERE staff_id IN ($idList)");
        $staffWithBookings = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        // Staff eliminabili (senza booking)
        $staffToDelete = array_diff($existingStaffIds, $staffWithBookings);
        
        // Elimina associazioni per TUTTI
        $pdo->exec("DELETE FROM staff_locations WHERE staff_id IN ($idList)");
        $pdo->exec("DELETE FROM staff_services WHERE staff_id IN ($idList)");
        
        // Soft delete per staff con booking
        if (!empty($staffWithBookings)) {
            $softDeleteIds = implode(',', $staffWithBookings);
            $pdo->exec("UPDATE staff SET is_active = 0, is_bookable_online = 0 WHERE id IN ($softDeleteIds)");
            echo "  Disattivati (soft delete): " . count($staffWithBookings) . " staff con booking esistenti\n";
        }
        
        // Hard delete per staff senza booking
        if (!empty($staffToDelete)) {
            $deleteIds = implode(',', $staffToDelete);
            $deleted = $pdo->exec("DELETE FROM staff WHERE id IN ($deleteIds)");
            echo "  Eliminati fisicamente: $deleted staff senza booking\n";
        }
        echo "\n";
    }
    
    // Prepara statements
    // sort_order parte da 0 (DB vuoto dopo eliminazione)
    // is_default = 1 solo per il primo staff
    
    $insertStaff = $pdo->prepare("
        INSERT INTO staff (business_id, name, surname, color_hex, avatar_url, sort_order, is_default, is_bookable_online, is_active, created_at, updated_at)
        VALUES (:business_id, :name, :surname, :color_hex, NULL, :sort_order, :is_default, :is_bookable_online, 1, NOW(), NOW())
    ");
    
    $insertStaffLocation = $pdo->prepare("
        INSERT INTO staff_locations (staff_id, location_id)
        VALUES (:staff_id, :location_id)
    ");
    
    $staffInserted = 0;
    
    foreach ($staffToImport as $index => $staff) {
        $sortOrder = $index;  // Parte da 0 (DB vuoto dopo eliminazione)
        $isDefault = ($index === 0) ? 1 : 0;  // Primo staff è default
        $colorHex = STAFF_COLORS[$index % count(STAFF_COLORS)];
        
        $insertStaff->execute([
            'business_id' => BUSINESS_ID,
            'name' => $staff['first_name'],
            'surname' => $staff['last_name'],
            'color_hex' => $colorHex,
            'sort_order' => $sortOrder,
            'is_default' => $isDefault,
            'is_bookable_online' => 1,
        ]);
        
        $staffId = $pdo->lastInsertId();
        
        // Associa a location
        $insertStaffLocation->execute([
            'staff_id' => $staffId,
            'location_id' => LOCATION_ID,
        ]);
        
        $staffInserted++;
        echo "Inserito: {$staff['first_name']} {$staff['last_name']} (ID: $staffId, colore: $colorHex)\n";
    }
    
    $pdo->commit();
    
    echo "\n=== REPORT FINALE ===\n";
    echo "Staff inseriti: $staffInserted\n";
    echo "Location associata: " . LOCATION_ID . "\n";
    
} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo "ERRORE: " . $e->getMessage() . "\n";
    exit(1);
}
