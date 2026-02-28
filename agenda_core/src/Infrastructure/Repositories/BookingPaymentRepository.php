<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Support\Json;
use PDO;

final class BookingPaymentRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function findByBookingId(int $bookingId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, location_id, booking_id, client_id, currency, total_due_cents, note, is_active, updated_by_user_id
             FROM booking_payments
             WHERE booking_id = ? AND is_active = 1
             ORDER BY id DESC
             LIMIT 1'
        );
        $stmt->execute([$bookingId]);
        $header = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$header) {
            return null;
        }

        $linesStmt = $this->db->getPdo()->prepare(
            'SELECT type, amount_cents, meta_json
             FROM booking_payment_lines
             WHERE booking_payment_id = ?
             ORDER BY id ASC'
        );
        $linesStmt->execute([(int) $header['id']]);
        $lines = $linesStmt->fetchAll(PDO::FETCH_ASSOC);

        return [
            'id' => (int) $header['id'],
            'business_id' => (int) $header['business_id'],
            'location_id' => (int) $header['location_id'],
            'booking_id' => (int) $header['booking_id'],
            'client_id' => isset($header['client_id']) ? (int) $header['client_id'] : null,
            'currency' => (string) $header['currency'],
            'total_due_cents' => (int) $header['total_due_cents'],
            'note' => $header['note'],
            'is_active' => (bool) ((int) ($header['is_active'] ?? 0)),
            'updated_by_user_id' => isset($header['updated_by_user_id']) ? (int) $header['updated_by_user_id'] : null,
            'lines' => array_map(
                static function (array $line): array {
                    return [
                        'type' => (string) $line['type'],
                        'amount_cents' => (int) $line['amount_cents'],
                        'meta' => $line['meta_json'] !== null ? Json::decodeAssoc((string) $line['meta_json']) : null,
                    ];
                },
                $lines
            ),
        ];
    }

    public function upsertByBooking(array $header, array $lines): array
    {
        $pdo = $this->db->getPdo();

        $this->deactivateActiveByBookingId(
            (int) $header['booking_id'],
            $header['updated_by_user_id'] ?? null,
        );

        $stmt = $pdo->prepare(
            'INSERT INTO booking_payments
                (business_id, location_id, booking_id, client_id, currency, total_due_cents, note, is_active, updated_by_user_id)
             VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)'
        );
        $stmt->execute([
            $header['business_id'],
            $header['location_id'],
            $header['booking_id'],
            $header['client_id'] ?? null,
            $header['currency'],
            $header['total_due_cents'],
            $header['note'] ?? null,
            $header['updated_by_user_id'] ?? null,
        ]);
        $paymentId = (int) $pdo->lastInsertId();

        if (!empty($lines)) {
            $insertStmt = $pdo->prepare(
                'INSERT INTO booking_payment_lines
                    (booking_payment_id, type, amount_cents, meta_json, created_by_user_id)
                 VALUES (?, ?, ?, ?, ?)'
            );

            foreach ($lines as $line) {
                $insertStmt->execute([
                    $paymentId,
                    $line['type'],
                    $line['amount_cents'],
                    isset($line['meta']) && is_array($line['meta']) ? Json::encode($line['meta']) : null,
                    $header['updated_by_user_id'] ?? null,
                ]);
            }
        }

        return $this->findByBookingId((int) $header['booking_id']) ?? [
            'id' => $paymentId,
            'business_id' => (int) $header['business_id'],
            'location_id' => (int) $header['location_id'],
            'booking_id' => (int) $header['booking_id'],
            'client_id' => isset($header['client_id']) ? (int) $header['client_id'] : null,
            'currency' => (string) $header['currency'],
            'total_due_cents' => (int) $header['total_due_cents'],
            'note' => $header['note'] ?? null,
            'is_active' => true,
            'updated_by_user_id' => $header['updated_by_user_id'] ?? null,
            'lines' => $lines,
        ];
    }

    public function deactivateActiveByBookingId(
        int $bookingId,
        ?int $updatedByUserId = null,
    ): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE booking_payments
             SET is_active = 0, updated_by_user_id = ?, updated_at = CURRENT_TIMESTAMP
             WHERE booking_id = ? AND is_active = 1'
        );
        $stmt->execute([$updatedByUserId, $bookingId]);
    }

}
