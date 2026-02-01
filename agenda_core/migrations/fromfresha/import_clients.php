<?php
/**
 * Script di importazione clienti da CSV Fresha
 * 
 * Usage: php import_clients.php
 */

require_once __DIR__ . '/../../vendor/autoload.php';

// Carica .env dalla root del progetto
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/../../');
$dotenv->load();

// Configurazione
const BUSINESS_ID = 5;
const CSV_FILE = 'export_customer_list.csv';
const SKIP_BLOCKED = false; // Se true, salta i clienti bloccati. Se false, li importa come is_archived=1

try {
    // Connessione DB
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
    
    // Leggi CSV
    $csvPath = __DIR__ . '/' . CSV_FILE;
    if (!file_exists($csvPath)) {
        throw new Exception("File CSV non trovato: " . CSV_FILE);
    }
    
    $handle = fopen($csvPath, 'r');
    $headers = fgetcsv($handle); // Prima riga = headers
    
    // Rimuovi BOM se presente
    if (isset($headers[0])) {
        $headers[0] = preg_replace('/^\xEF\xBB\xBF/', '', $headers[0]);
    }
    
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
    $colClientId = findColumn($headers, ['Client ID', 'ID cliente']);
    $colFirstName = findColumn($headers, ['First Name', 'Nome']);
    $colLastName = findColumn($headers, ['Last Name', 'Cognome']);
    $colEmail = findColumn($headers, ['Email']);
    $colMobile = findColumn($headers, ['Mobile Number', 'Numero di cellulare']);
    $colTelephone = findColumn($headers, ['Telephone', 'Telefono']);
    $colGender = findColumn($headers, ['Gender', 'Sesso']);
    $colBirthDate = findColumn($headers, ['Date of Birth', 'Data di nascita']);
    $colCity = findColumn($headers, ['City', 'Città']);
    $colNote = findColumn($headers, ['Note', 'Notes']);
    $colBlocked = findColumn($headers, ['Blocked', 'Bloccato']);
    $colAdded = findColumn($headers, ['Added', 'Aggiunto']);
    
    if ($colFirstName === false || $colLastName === false) {
        throw new Exception("Colonne obbligatorie (First Name/Nome, Last Name/Cognome) non trovate nel CSV");
    }
    
    // Raccogli clienti da importare
    $clientsToImport = [];
    $skippedBlocked = 0;
    $skippedNoName = 0;
    
    while (($row = fgetcsv($handle)) !== false) {
        $firstName = trim($row[$colFirstName] ?? '');
        $lastName = trim($row[$colLastName] ?? '');
        $blockedValue = strtolower(trim($row[$colBlocked] ?? ''));
        $blocked = in_array($blockedValue, ['yes', 'sì', 'si']);
        
        // Salta righe senza nome
        if (empty($firstName) && empty($lastName)) {
            $skippedNoName++;
            continue;
        }
        
        // Gestione clienti bloccati
        if ($blocked && SKIP_BLOCKED) {
            $skippedBlocked++;
            continue;
        }
        
        // Normalizza telefono (rimuovi spazi)
        $phone = trim($row[$colMobile] ?? '');
        if (empty($phone)) {
            $phone = trim($row[$colTelephone] ?? '');
        }
        $phone = preg_replace('/\s+/', '', $phone);
        
        // Aggiungi + se inizia con numero
        if (!empty($phone) && preg_match('/^\d/', $phone)) {
            $phone = '+' . $phone;
        }
        
        // Normalizza data nascita (formato YYYY-MM-DD)
        $birthDate = null;
        $rawBirthDate = trim($row[$colBirthDate] ?? '');
        if (!empty($rawBirthDate)) {
            $parsed = date_create($rawBirthDate);
            if ($parsed) {
                $birthDate = $parsed->format('Y-m-d');
            }
        }
        
        // Normalizza data aggiunta
        $createdAt = null;
        $rawAdded = trim($row[$colAdded] ?? '');
        if (!empty($rawAdded)) {
            $parsed = date_create($rawAdded);
            if ($parsed) {
                $createdAt = $parsed->format('Y-m-d H:i:s');
            }
        }
        
        $clientsToImport[] = [
            'fresha_id' => trim($row[$colClientId] ?? ''),
            'first_name' => $firstName,
            'last_name' => $lastName,
            'email' => strtolower(trim($row[$colEmail] ?? '')) ?: null,
            'phone' => $phone ?: null,
            'gender' => trim($row[$colGender] ?? '') ?: null,
            'birth_date' => $birthDate,
            'city' => trim($row[$colCity] ?? '') ?: null,
            'notes' => trim($row[$colNote] ?? '') ?: null,
            'is_archived' => $blocked ? 1 : 0,
            'created_at' => $createdAt,
        ];
    }
    fclose($handle);
    
    echo "Clienti da importare: " . count($clientsToImport) . "\n";
    if ($skippedBlocked > 0) {
        echo "Clienti bloccati saltati: $skippedBlocked\n";
    }
    if ($skippedNoName > 0) {
        echo "Righe senza nome saltate: $skippedNoName\n";
    }
    echo "\n";
    
    // Verifica duplicati email nel DB esistente
    $existingEmails = [];
    $stmt = $pdo->prepare("SELECT email FROM clients WHERE business_id = ? AND email IS NOT NULL");
    $stmt->execute([BUSINESS_ID]);
    while ($row = $stmt->fetch()) {
        $existingEmails[strtolower($row['email'])] = true;
    }
    echo "Email già presenti nel DB: " . count($existingEmails) . "\n\n";
    
    // Inserimento clienti
    $insertStmt = $pdo->prepare("
        INSERT INTO clients (business_id, first_name, last_name, email, phone, gender, birth_date, city, notes, is_archived, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ");
    
    $inserted = 0;
    $skippedDuplicate = 0;
    
    foreach ($clientsToImport as $client) {
        // Salta se email già esistente
        if (!empty($client['email']) && isset($existingEmails[strtolower($client['email'])])) {
            $skippedDuplicate++;
            continue;
        }
        
        $insertStmt->execute([
            BUSINESS_ID,
            $client['first_name'],
            $client['last_name'],
            $client['email'],
            $client['phone'],
            $client['gender'],
            $client['birth_date'],
            $client['city'],
            $client['notes'],
            $client['is_archived'],
            $client['created_at'] ?? date('Y-m-d H:i:s'),
        ]);
        
        $inserted++;
        
        // Aggiungi email alla lista per evitare duplicati interni al CSV
        if (!empty($client['email'])) {
            $existingEmails[strtolower($client['email'])] = true;
        }
    }
    
    echo "\n=== REPORT FINALE ===\n";
    echo "Clienti inseriti: $inserted\n";
    echo "Duplicati email saltati: $skippedDuplicate\n";
    echo "Business ID: " . BUSINESS_ID . "\n";
    echo "=====================\n";
    
} catch (Exception $e) {
    echo "ERRORE: " . $e->getMessage() . "\n";
    exit(1);
}
