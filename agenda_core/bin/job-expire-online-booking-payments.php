<?php

declare(strict_types=1);

require_once __DIR__ . '/../vendor/autoload.php';

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Environment\EnvironmentConfig;
use Agenda\Infrastructure\Repositories\OnlinePayments\OnlineBookingPaymentRepository;
use Dotenv\Dotenv;

Dotenv::createImmutable(__DIR__ . '/..')->safeLoad();
EnvironmentConfig::bootstrap();

$db = new Connection();
$repo = new OnlineBookingPaymentRepository($db);
$limit = isset($argv[1]) && ctype_digit((string) $argv[1]) ? max(1, (int) $argv[1]) : 100;
$expired = $repo->findExpiredPending($limit);
$processed = 0;

foreach ($expired as $payment) {
    $pdo = $db->getPdo();
    $pdo->beginTransaction();
    try {
        $repo->markExpired($payment->id, ['expired_by' => 'job-expire-online-booking-payments']);
        if ($payment->bookingId !== null) {
            $stmt = $pdo->prepare("UPDATE bookings SET status = 'cancelled', updated_at = NOW() WHERE id = ? AND status = 'pending_payment'");
            $stmt->execute([$payment->bookingId]);
        }
        $pdo->commit();
        $processed++;
    } catch (Throwable $e) {
        $pdo->rollBack();
        fwrite(STDERR, 'Failed expiring payment #' . $payment->id . ': ' . $e->getMessage() . PHP_EOL);
    }
}

fwrite(STDOUT, 'Expired online booking payments: ' . $processed . PHP_EOL);
