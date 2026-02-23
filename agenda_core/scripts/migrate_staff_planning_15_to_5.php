#!/usr/bin/env php
<?php

declare(strict_types=1);

use Dotenv\Dotenv;

require __DIR__ . '/../vendor/autoload.php';

/**
 * Migrazione staff planning step 15 -> 5.
 *
 * Default: dry-run (nessuna scrittura DB).
 * Esegui realmente con: --execute
 *
 * Opzioni:
 *   --execute                  Applica le modifiche (altrimenti solo preview)
 *   --staff-id=ID              Limita ad uno staff specifico
 *   --business-id=ID           Limita ai planning dello staff di un business
 *   --location-id=ID           Limita ai planning dello staff di una location
 *   --help                     Mostra aiuto
 */

const OLD_STEP = 15;
const NEW_STEP = 5;

main($argv);

function main(array $argv): void
{
    $opts = parseArgs($argv);

    if ($opts['help']) {
        printHelp();
        return;
    }

    loadEnv();
    $pdo = buildPdo();

    $filters = buildFilters($opts);
    $rows = fetchTemplateRows($pdo, $filters);

    if (empty($rows)) {
        echo "[INFO] Nessun planning con passo " . OLD_STEP . " trovato per i filtri indicati.\n";
        return;
    }

    $updates = [];
    $planningIds = [];
    $changedTemplates = 0;
    $unchangedTemplates = 0;
    $oldTotalSlots = 0;
    $newTotalSlots = 0;

    foreach ($rows as $row) {
        $templateId = (int) $row['template_id'];
        $planningId = (int) $row['planning_id'];
        $staffId = (int) $row['staff_id'];
        $weekLabel = (string) $row['week_label'];
        $dayOfWeek = (int) $row['day_of_week'];

        $oldSlots = decodeSlots((string) $row['slots_json']);
        $newSlots = convertSlots15To5($oldSlots);

        $oldTotalSlots += count($oldSlots);
        $newTotalSlots += count($newSlots);

        if ($oldSlots !== $newSlots) {
            $changedTemplates++;
            $updates[] = [
                'template_id' => $templateId,
                'planning_id' => $planningId,
                'staff_id' => $staffId,
                'week_label' => $weekLabel,
                'day_of_week' => $dayOfWeek,
                'old_slots' => $oldSlots,
                'new_slots' => $newSlots,
            ];
        } else {
            $unchangedTemplates++;
        }

        $planningIds[$planningId] = true;
    }

    $planningCount = count($planningIds);
    $templatesCount = count($rows);

    echo "[INFO] Planning coinvolti: {$planningCount}\n";
    echo "[INFO] Planning aggiornati (planning_slot_minutes): {$planningCount}\n";
    echo "[INFO] Template (giorni) letti: {$templatesCount}\n";
    echo "[INFO] Template modificati: {$changedTemplates}\n";
    echo "[INFO] Template invariati: {$unchangedTemplates}\n";
    echo "[INFO] Slot totali old/new: {$oldTotalSlots} -> {$newTotalSlots}\n";
    echo "[INFO] Minuti totali old/new: " . ($oldTotalSlots * OLD_STEP) . " -> " . ($newTotalSlots * NEW_STEP) . "\n";

    printPreview($updates);

    if (!$opts['execute']) {
        echo "\n[DRY-RUN] Nessuna modifica applicata. Usa --execute per applicare.\n";
        return;
    }

    applyUpdates($pdo, $updates, array_keys($planningIds));
    echo "\n[OK] Migrazione completata: planning step " . OLD_STEP . " -> " . NEW_STEP . "\n";
}

function parseArgs(array $argv): array
{
    $opts = [
        'execute' => false,
        'help' => false,
        'staff_id' => null,
        'business_id' => null,
        'location_id' => null,
    ];

    foreach (array_slice($argv, 1) as $arg) {
        if ($arg === '--execute') {
            $opts['execute'] = true;
            continue;
        }
        if ($arg === '--help' || $arg === '-h') {
            $opts['help'] = true;
            continue;
        }
        if (str_starts_with($arg, '--staff-id=')) {
            $opts['staff_id'] = (int) substr($arg, strlen('--staff-id='));
            continue;
        }
        if (str_starts_with($arg, '--business-id=')) {
            $opts['business_id'] = (int) substr($arg, strlen('--business-id='));
            continue;
        }
        if (str_starts_with($arg, '--location-id=')) {
            $opts['location_id'] = (int) substr($arg, strlen('--location-id='));
            continue;
        }
        throw new InvalidArgumentException("Argomento non riconosciuto: {$arg}");
    }

    return $opts;
}

function printHelp(): void
{
    echo <<<TXT
Migrazione planning staff 15 -> 5

Uso:
  php scripts/migrate_staff_planning_15_to_5.php [opzioni]

Opzioni:
  --execute                  Applica le modifiche (default: dry-run)
  --staff-id=ID              Limita a uno staff
  --business-id=ID           Limita agli staff di un business
  --location-id=ID           Limita agli staff di una location
  --help                     Mostra questo aiuto

Esempi:
  php scripts/migrate_staff_planning_15_to_5.php
  php scripts/migrate_staff_planning_15_to_5.php --execute
  php scripts/migrate_staff_planning_15_to_5.php --location-id=14 --execute

TXT;
}

function loadEnv(): void
{
    $dotenv = Dotenv::createImmutable(__DIR__ . '/..');
    $dotenv->safeLoad();
}

function buildPdo(): PDO
{
    $host = $_ENV['DB_HOST'] ?? '127.0.0.1';
    $db = $_ENV['DB_DATABASE'] ?? null;
    $user = $_ENV['DB_USERNAME'] ?? null;
    $pass = $_ENV['DB_PASSWORD'] ?? null;
    $port = (string) ($_ENV['DB_PORT'] ?? '3306');

    if ($db === null || $user === null || $pass === null) {
        throw new RuntimeException('Variabili DB mancanti: DB_DATABASE, DB_USERNAME, DB_PASSWORD');
    }

    $dsn = "mysql:host={$host};port={$port};dbname={$db};charset=utf8mb4";

    return new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
}

function buildFilters(array $opts): array
{
    $where = ['sp.planning_slot_minutes = :old_step'];
    $params = ['old_step' => OLD_STEP];

    if ($opts['staff_id'] !== null && $opts['staff_id'] > 0) {
        $where[] = 'sp.staff_id = :staff_id';
        $params['staff_id'] = $opts['staff_id'];
    }
    if ($opts['business_id'] !== null && $opts['business_id'] > 0) {
        $where[] = 's.business_id = :business_id';
        $params['business_id'] = $opts['business_id'];
    }
    if ($opts['location_id'] !== null && $opts['location_id'] > 0) {
        $where[] = 'EXISTS (
            SELECT 1
            FROM staff_locations sl
            WHERE sl.staff_id = sp.staff_id
              AND sl.location_id = :location_id
        )';
        $params['location_id'] = $opts['location_id'];
    }

    return ['where' => $where, 'params' => $params];
}

/**
 * @return array<int, array<string,mixed>>
 */
function fetchTemplateRows(PDO $pdo, array $filters): array
{
    $whereSql = implode(' AND ', $filters['where']);

    $sql = <<<SQL
SELECT
    t.id AS template_id,
    t.staff_planning_id AS planning_id,
    sp.staff_id AS staff_id,
    t.week_label AS week_label,
    t.day_of_week AS day_of_week,
    t.slots AS slots_json
FROM staff_planning_week_template t
INNER JOIN staff_planning sp ON sp.id = t.staff_planning_id
INNER JOIN staff s ON s.id = sp.staff_id
WHERE {$whereSql}
ORDER BY sp.staff_id, sp.id, t.week_label, t.day_of_week
SQL;

    $stmt = $pdo->prepare($sql);
    foreach ($filters['params'] as $k => $v) {
        $stmt->bindValue(':' . $k, $v, PDO::PARAM_INT);
    }
    $stmt->execute();
    return $stmt->fetchAll();
}

/**
 * @return array<int>
 */
function decodeSlots(string $json): array
{
    $decoded = json_decode($json, true);
    if (!is_array($decoded)) {
        return [];
    }

    $slots = [];
    foreach ($decoded as $v) {
        if (is_int($v) || is_float($v) || (is_string($v) && is_numeric($v))) {
            $slots[] = (int) $v;
        }
    }

    $slots = array_values(array_unique($slots));
    sort($slots);
    return $slots;
}

/**
 * Conversione esatta 15->5, preservando gli intervalli orari.
 *
 * @param array<int> $oldSlots
 * @return array<int>
 */
function convertSlots15To5(array $oldSlots): array
{
    $newSlots = [];

    foreach ($oldSlots as $slot) {
        if ($slot < 0) {
            continue;
        }
        $startMinute = $slot * OLD_STEP;
        $endMinute = $startMinute + OLD_STEP; // end esclusivo

        $startNew = intdiv($startMinute, NEW_STEP);
        $endNewExclusive = intdiv($endMinute, NEW_STEP);

        for ($i = $startNew; $i < $endNewExclusive; $i++) {
            $newSlots[$i] = true;
        }
    }

    $result = array_map('intval', array_keys($newSlots));
    sort($result);
    return $result;
}

/**
 * @param array<int, array<string,mixed>> $updates
 */
function printPreview(array $updates): void
{
    if (empty($updates)) {
        echo "[INFO] Nessun template richiede conversione.\n";
        return;
    }

    $maxRows = 10;
    echo "\n[PREVIEW] Prime " . min($maxRows, count($updates)) . " conversioni:\n";
    for ($i = 0; $i < min($maxRows, count($updates)); $i++) {
        $u = $updates[$i];
        $oldCount = count($u['old_slots']);
        $newCount = count($u['new_slots']);
        echo sprintf(
            "- staff=%d planning=%d tpl=%d week=%s day=%d slots %d -> %d\n",
            $u['staff_id'],
            $u['planning_id'],
            $u['template_id'],
            $u['week_label'],
            $u['day_of_week'],
            $oldCount,
            $newCount
        );
    }
}

/**
 * @param array<int, array<string,mixed>> $updates
 * @param array<int> $planningIds
 */
function applyUpdates(PDO $pdo, array $updates, array $planningIds): void
{
    if (empty($planningIds)) {
        return;
    }

    $pdo->beginTransaction();
    try {
        $updateTpl = $pdo->prepare(
            'UPDATE staff_planning_week_template SET slots = :slots WHERE id = :id'
        );

        foreach ($updates as $u) {
            $updateTpl->bindValue(':slots', json_encode($u['new_slots'], JSON_UNESCAPED_UNICODE));
            $updateTpl->bindValue(':id', (int) $u['template_id'], PDO::PARAM_INT);
            $updateTpl->execute();
        }

        $in = implode(',', array_fill(0, count($planningIds), '?'));
        $updatePlanning = $pdo->prepare(
            "UPDATE staff_planning SET planning_slot_minutes = ?, updated_at = CURRENT_TIMESTAMP WHERE id IN ($in)"
        );
        $idx = 1;
        $updatePlanning->bindValue($idx++, NEW_STEP, PDO::PARAM_INT);
        foreach ($planningIds as $planningId) {
            $updatePlanning->bindValue($idx++, (int) $planningId, PDO::PARAM_INT);
        }
        $updatePlanning->execute();

        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        throw $e;
    }
}
