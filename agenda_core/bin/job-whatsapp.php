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
use Agenda\Infrastructure\Repositories\BusinessWhatsappSettingsRepository;
use Agenda\Infrastructure\Repositories\WhatsappRepository;
use Agenda\Infrastructure\Security\TokenCipher;
use Agenda\Infrastructure\Support\Json;
use Agenda\Infrastructure\Whatsapp\MetaWhatsAppCloudApiClient;
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
    $settingsRepo = new BusinessWhatsappSettingsRepository($db);
    $pdo = $db->getPdo();
} catch (\Throwable $e) {
    fwrite(STDERR, "[whatsapp-worker] bootstrap error: {$e->getMessage()}\n");
    exit(1);
}

/**
 * @return list<array<string,mixed>>
 */
function fetchQueued(\PDO $pdo, int $batch, ?int $businessId): array
{
    $params = [];
    $where = 'status = "queued" AND (scheduled_at IS NULL OR scheduled_at <= NOW())';
    if ($businessId !== null && $businessId > 0) {
        $where .= ' AND business_id = ?';
        $params[] = $businessId;
    }

    $sql = "SELECT id, business_id, location_id, whatsapp_config_id, booking_id, class_booking_id, client_id,
                   recipient_phone, recipient_phone_e164, template_name, template_language,
                   template_payload, template_variables_json, message_type, max_attempts, attempts, scheduled_at
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

function fetchApprovedTemplate(\PDO $pdo, int $businessId, string $templateName, string $language): ?array
{
    $stmt = $pdo->prepare(
        'SELECT id, template_name, variables_schema_json
         FROM whatsapp_templates
         WHERE (business_id = ? OR business_id IS NULL)
           AND template_name = ?
           AND language_code IN (?, "it")
           AND status = "approved"
         ORDER BY business_id IS NULL ASC, id DESC
         LIMIT 1'
    );
    $stmt->execute([$businessId, $templateName, $language]);
    $row = $stmt->fetch(\PDO::FETCH_ASSOC);

    return is_array($row) ? $row : null;
}

function hasOptIn(\PDO $pdo, int $businessId, ?int $clientId, string $phone): bool
{
    if ($clientId === null || $clientId <= 0) {
        return false;
    }
    $stmt = $pdo->prepare(
        'SELECT 1
         FROM whatsapp_client_optins
         WHERE business_id = ?
           AND client_id = ?
           AND (opted_in = 1 OR opt_in = 1)
           AND (phone_e164 IS NULL OR phone_e164 = "" OR phone_e164 = ?)
           AND revoked_at IS NULL
         LIMIT 1'
    );
    $stmt->execute([$businessId, $clientId, $phone]);
    return $stmt->fetchColumn() !== false;
}

function templateVariables(array $row, ?array $template = null): array
{
    $raw = $row['template_variables_json'] ?? $row['template_payload'] ?? null;
    $variables = [];
    if (is_string($raw) && $raw !== '') {
        $decoded = Json::decodeAssoc($raw);
        $variables = is_array($decoded) ? $decoded : [];
    }

    $schemaRaw = $template['variables_schema_json'] ?? null;
    if (!is_string($schemaRaw) || trim($schemaRaw) === '') {
        return $variables;
    }

    $schema = Json::decodeAssoc($schemaRaw);
    if (!is_array($schema)) {
        return $variables;
    }

    $bodyKeys = $schema['body'] ?? $schema['body_variables'] ?? [];
    $body = [];
    if (is_array($bodyKeys)) {
        foreach ($bodyKeys as $key) {
            if (is_scalar($key)) {
                $body[] = (string) ($variables[(string) $key] ?? '');
            }
        }
    }

    $buttonKey = $schema['button_url'] ?? $schema['button_url_variable'] ?? null;
    $buttonUrl = is_scalar($buttonKey) ? (string) ($variables[(string) $buttonKey] ?? '') : '';

    $buttonMode = (string) ($schema['button_url_mode'] ?? 'full_url');
    if ($buttonUrl !== '' && $buttonMode === 'path') {
        $parts = parse_url($buttonUrl);
        if (is_array($parts) && isset($parts['path'])) {
            $buttonUrl = (string) $parts['path'] . (isset($parts['query']) ? '?' . $parts['query'] : '');
            $buttonUrl = ltrim($buttonUrl, '/');
        }
    }

    $formatted = [];
    if ($body !== []) {
        $formatted['__body'] = $body;
    }
    if ($buttonUrl !== '') {
        $formatted['__button_url'] = $buttonUrl;
    }

    return $formatted !== [] ? $formatted : $variables;
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
$workerEnabled = in_array(strtolower((string) ($_ENV['WHATSAPP_WORKER_ENABLED'] ?? getenv('WHATSAPP_WORKER_ENABLED') ?? 'true')), ['1', 'true', 'yes', 'on'], true);
$realSendEnabled = in_array(strtolower((string) ($_ENV['WHATSAPP_REAL_SEND_ENABLED'] ?? getenv('WHATSAPP_REAL_SEND_ENABLED') ?? 'false')), ['1', 'true', 'yes', 'on'], true);
$appEnv = strtolower((string) ($_ENV['APP_ENV'] ?? getenv('APP_ENV') ?? 'local'));

if (!$workerEnabled) {
    echo "[whatsapp-worker] disabled\n";
    exit(0);
}

foreach ($queued as $row) {
    $processed++;

    $id = (int) $row['id'];
    $businessId = (int) $row['business_id'];
    $configId = isset($row['whatsapp_config_id']) ? (int) $row['whatsapp_config_id'] : null;
    $clientId = isset($row['client_id']) ? (int) $row['client_id'] : null;
    $recipientPhone = trim((string) ($row['recipient_phone_e164'] ?? $row['recipient_phone'] ?? ''));
    $templateName = trim((string) ($row['template_name'] ?? ''));
    $templateLanguage = trim((string) ($row['template_language'] ?? 'it'));
    $maxAttempts = max(1, (int) ($row['max_attempts'] ?? 3));
    $attempts = (int) ($row['attempts'] ?? 0);

    if ($verbose) {
        echo "[{$id}] business={$businessId} attempts={$attempts}/{$maxAttempts} ";
    }

    try {
        $settings = $settingsRepo->findByBusinessId($businessId);
        if (((int) ($settings['whatsapp_enabled'] ?? 0)) !== 1) {
            if (!$dryRun) {
                $repo->updateOutboxStatus($businessId, $id, 'failed', 'whatsapp_not_enabled');
            }
            $failed++;
            if ($verbose) {
                echo "FAILED(feature disabled)\n";
            }
            continue;
        }
        if (((int) ($settings['messages_enabled'] ?? 0)) !== 1) {
            if (!$dryRun) {
                $repo->updateOutboxStatus($businessId, $id, 'failed', 'whatsapp_messages_disabled');
            }
            $failed++;
            if ($verbose) {
                echo "FAILED(messages disabled)\n";
            }
            continue;
        }

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

        if (!preg_match('/^\+[1-9]\d{7,14}$/', $recipientPhone)) {
            if (!$dryRun) {
                $repo->updateOutboxStatus($businessId, $id, 'failed', 'invalid_whatsapp_phone');
            }
            $failed++;
            if ($verbose) {
                echo "FAILED(invalid phone)\n";
            }
            continue;
        }

        if (!hasOptIn($pdo, $businessId, $clientId, $recipientPhone)) {
            if (!$dryRun) {
                $repo->updateOutboxStatus($businessId, $id, 'failed', 'whatsapp_optin_required');
            }
            $failed++;
            if ($verbose) {
                echo "FAILED(opt-in required)\n";
            }
            continue;
        }

        $template = fetchApprovedTemplate($pdo, $businessId, $templateName, $templateLanguage);
        if ($template === null) {
            if (!$dryRun) {
                $repo->updateOutboxStatus($businessId, $id, 'failed', 'whatsapp_template_not_approved');
            }
            $failed++;
            if ($verbose) {
                echo "FAILED(template not approved)\n";
            }
            continue;
        }

        if ($dryRun) {
            if ($verbose) {
                echo "DRY-RUN SENT\n";
            }
            $sent++;
            continue;
        }

        if ($appEnv === 'demo' || !$realSendEnabled) {
            $repo->updateOutboxStatus(
                $businessId,
                $id,
                'skipped',
                $appEnv === 'demo' ? 'whatsapp_demo_real_send_blocked' : 'whatsapp_real_send_disabled'
            );
            if ($verbose) {
                echo "SKIPPED(real send disabled)\n";
            }
            $skipped++;
            continue;
        }

        $metaClient = new MetaWhatsAppCloudApiClient(new TokenCipher());
        $result = $metaClient->sendTemplateMessage(
            $config,
            $recipientPhone,
            $templateName,
            $templateLanguage,
            templateVariables($row, $template)
        );
        if (!$result['success']) {
            $attemptsAfter = $attempts + 1;
            $isRetryable = in_array((string) ($result['error_code'] ?? ''), ['429', '500', '502', '503', '504'], true);
            $repo->markOutboxSendFailure(
                $businessId,
                $id,
                ($isRetryable && $attemptsAfter < $maxAttempts) ? 'queued' : 'failed',
                (string) ($result['error_code'] ?? 'meta_send_failed'),
                (string) ($result['error_message'] ?? $result['error_code'] ?? 'meta_send_failed'),
                ($isRetryable && $attemptsAfter < $maxAttempts)
                    ? (new DateTimeImmutable('+' . min(60, 5 * $attemptsAfter) . ' minutes'))->format('Y-m-d H:i:s')
                    : null
            );
            if ($verbose) {
                echo ($isRetryable ? "RETRY" : "FAILED") . "(meta send)\n";
            }
            if ($isRetryable && $attemptsAfter < $maxAttempts) {
                $skipped++;
            } else {
                $failed++;
            }
            continue;
        }

        $repo->markOutboxSent($businessId, $id, $result['provider_message_id'] ?? providerMessageId($id));
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
