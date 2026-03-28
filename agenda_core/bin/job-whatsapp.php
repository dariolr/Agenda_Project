#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * WhatsApp Outbox Worker
 *
 * Processes queued WhatsApp outbox messages.
 *
 * Cron example:
 * * * * * cd /path/to/agenda_core && /usr/bin/php bin/job-whatsapp.php --batch=100 >> logs/whatsapp-worker.log 2>&1
 *
 * Options:
 *   --batch=N        Max queued messages to process (default: 100, max: 500)
 *   --business=ID    Restrict to a specific business_id
 *   --dry-run        Do not persist status changes
 *   --verbose        Print detailed output
 *   --help           Show help
 */

require_once __DIR__ . '/../vendor/autoload.php';

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\WhatsappRepository;
use Dotenv\Dotenv;

$options = getopt('', ['batch::', 'business::', 'dry-run', 'verbose', 'help']);

if (isset($options['help'])) {
    echo <<<HELP
WhatsApp Outbox Worker

Usage: php bin/job-whatsapp.php [options]

Options:
  --batch=N        Max queued messages to process (default: 100, max: 500)
  --business=ID    Restrict to one business_id
  --dry-run        Do not persist status changes
  --verbose        Print detailed output
  --help           Show this help

HELP;
    exit(0);
}

$batch = isset($options['batch']) ? max(1, min(500, (int) $options['batch'])) : 100;
$businessFilter = isset($options['business']) ? (int) $options['business'] : null;
$dryRun = isset($options['dry-run']);
$verbose = isset($options['verbose']);

$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->safeLoad();

try {
    $db = new Connection();
    $repo = new WhatsappRepository($db);
    $pdo = $db->getPdo();
} catch (\Throwable $e) {
    fwrite(STDERR, "[whatsapp-worker] bootstrap error: {$e->getMessage()}\n");
    exit(1);
}

/**
 * @return list<array{id:int,business_id:int,location_id:?int,whatsapp_config_id:?int,max_attempts:int,attempts:int,scheduled_at:?string}>
 */
function fetchQueued(\PDO $pdo, int $batch, ?int $businessId): array
{
    $params = [];
    $where = 'status = "queued" AND (scheduled_at IS NULL OR scheduled_at <= NOW())';
    if ($businessId !== null && $businessId > 0) {
        $where .= ' AND business_id = ?';
        $params[] = $businessId;
    }

    $sql = "SELECT id, business_id, location_id, whatsapp_config_id, max_attempts, attempts, scheduled_at
            FROM whatsapp_outbox
            WHERE {$where}
            ORDER BY id ASC
            LIMIT {$batch}";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    /** @var list<array{id:int,business_id:int,location_id:?int,whatsapp_config_id:?int,max_attempts:int,attempts:int,scheduled_at:?string}> $rows */
    $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);
    return $rows;
}

function providerMessageId(int $outboxId): string
{
    return 'wa_worker_' . $outboxId . '_' . bin2hex(random_bytes(6));
}

if ($verbose) {
    echo "[whatsapp-worker] started\n";
    echo "[whatsapp-worker] batch={$batch} dry-run=" . ($dryRun ? 'yes' : 'no') . "\n";
    if ($businessFilter !== null && $businessFilter > 0) {
        echo "[whatsapp-worker] business filter={$businessFilter}\n";
    }
}

$queued = [];
try {
    $queued = fetchQueued($pdo, $batch, $businessFilter);
} catch (\Throwable $e) {
    fwrite(STDERR, "[whatsapp-worker] failed to read whatsapp_outbox: {$e->getMessage()}\n");
    exit(1);
}
$total = count($queued);

if ($total === 0) {
    if ($verbose) {
        echo "[whatsapp-worker] no queued messages\n";
    }
    exit(0);
}

if ($verbose) {
    echo "[whatsapp-worker] processing {$total} queued message(s)\n";
}

$processed = 0;
$sent = 0;
$failed = 0;
$skipped = 0;
$errors = 0;

foreach ($queued as $row) {
    $processed++;

    $id = (int) $row['id'];
    $businessId = (int) $row['business_id'];
    $configId = isset($row['whatsapp_config_id']) ? (int) $row['whatsapp_config_id'] : null;
    $maxAttempts = max(1, (int) ($row['max_attempts'] ?? 3));
    $attempts = (int) ($row['attempts'] ?? 0);

    if ($verbose) {
        echo "[{$id}] business={$businessId} attempts={$attempts}/{$maxAttempts} ";
    }

    try {
        if ($attempts >= $maxAttempts) {
            if ($dryRun) {
                if ($verbose) {
                    echo "DRY-RUN FAIL(max attempts)\n";
                }
            } else {
                $repo->updateOutboxStatus(
                    $businessId,
                    $id,
                    'failed',
                    'max_attempts_reached'
                );
                if ($verbose) {
                    echo "FAILED(max attempts)\n";
                }
            }
            $failed++;
            continue;
        }

        if ($configId === null || $configId <= 0) {
            if ($dryRun) {
                if ($verbose) {
                    echo "DRY-RUN FAIL(missing config)\n";
                }
            } else {
                $repo->updateOutboxStatus(
                    $businessId,
                    $id,
                    'failed',
                    'missing_whatsapp_config'
                );
                if ($verbose) {
                    echo "FAILED(missing config)\n";
                }
            }
            $failed++;
            continue;
        }

        $config = $repo->findConfigById($businessId, $configId);
        if ($config === null) {
            if ($dryRun) {
                if ($verbose) {
                    echo "DRY-RUN FAIL(config not found)\n";
                }
            } else {
                $repo->updateOutboxStatus(
                    $businessId,
                    $id,
                    'failed',
                    'config_not_found'
                );
                if ($verbose) {
                    echo "FAILED(config not found)\n";
                }
            }
            $failed++;
            continue;
        }

        $status = strtolower((string) ($config['status'] ?? 'inactive'));
        if ($status !== 'active') {
            if ($dryRun) {
                if ($verbose) {
                    echo "DRY-RUN SKIP(config {$status})\n";
                }
            } else {
                $repo->updateOutboxStatus(
                    $businessId,
                    $id,
                    'failed',
                    'whatsapp_config_not_active'
                );
                if ($verbose) {
                    echo "FAILED(config {$status})\n";
                }
            }
            $failed++;
            continue;
        }

        if ($dryRun) {
            if ($verbose) {
                echo "DRY-RUN SENT\n";
            }
            $sent++;
            continue;
        }

        // NOTE: current backend flow simulates provider send and marks "sent".
        $repo->markOutboxSent($businessId, $id, providerMessageId($id));
        if ($verbose) {
            echo "SENT\n";
        }
        $sent++;
    } catch (\Throwable $e) {
        $errors++;
        if (!$dryRun) {
            try {
                $repo->updateOutboxStatus(
                    $businessId,
                    $id,
                    'failed',
                    'worker_error: ' . mb_substr($e->getMessage(), 0, 500)
                );
            } catch (\Throwable) {
                // Ignore secondary failure in worker loop.
            }
        }

        if ($verbose) {
            echo "ERROR(" . $e->getMessage() . ")\n";
        }
    }
}

echo sprintf(
    "[whatsapp-worker] done processed=%d sent=%d failed=%d skipped=%d errors=%d dry-run=%s\n",
    $processed,
    $sent,
    $failed,
    $skipped,
    $errors,
    $dryRun ? 'yes' : 'no'
);

exit($errors > 0 ? 1 : 0);
