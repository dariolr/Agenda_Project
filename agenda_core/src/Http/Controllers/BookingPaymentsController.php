<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BookingPaymentRepository;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Throwable;

final class BookingPaymentsController
{
    private const ALLOWED_TYPES = [
        'cash',
        'card',
        'discount',
        'voucher',
        'other',
    ];

    public function __construct(
        private readonly Connection $db,
        private readonly BookingRepository $bookingRepo,
        private readonly BookingPaymentRepository $bookingPaymentRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    public function show(Request $request): Response
    {
        $bookingId = (int) $request->getAttribute('booking_id');
        $booking = $this->bookingRepo->findById($bookingId);
        if ($booking === null) {
            return Response::notFound('Booking not found', $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, (int) $booking['business_id'], true)) {
            return Response::forbidden('You do not have access to this booking', $request->traceId);
        }

        $payment = $this->bookingPaymentRepo->findByBookingId($bookingId);
        if ($payment === null) {
            $payment = $this->buildEmptyPaymentPayload($bookingId, $booking);
        }

        return Response::success($this->formatPayload($payment));
    }

    public function upsert(Request $request): Response
    {
        $bookingId = (int) $request->getAttribute('booking_id');
        $booking = $this->bookingRepo->findById($bookingId);
        if ($booking === null) {
            return Response::notFound('Booking not found', $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, (int) $booking['business_id'], false)) {
            return Response::forbidden('You do not have access to this booking', $request->traceId);
        }

        $payload = $request->getBody() ?? [];
        $validationError = $this->validatePayload($payload);
        if ($validationError !== null) {
            return $validationError;
        }

        $userId = $request->userId();
        $lines = [];
        foreach (($payload['lines'] ?? []) as $line) {
            $lines[] = [
                'type' => (string) $line['type'],
                'amount_cents' => (int) $line['amount_cents'],
                'meta' => isset($line['meta_json']) && is_array($line['meta_json'])
                    ? $line['meta_json']
                    : (isset($line['meta']) && is_array($line['meta']) ? $line['meta'] : null),
            ];
        }

        try {
            $this->db->beginTransaction();
            if ($this->shouldRemovePayment($payload, $lines)) {
                $this->bookingPaymentRepo->deactivateActiveByBookingId($bookingId, $userId);
                $stored = $this->buildEmptyPaymentPayload($bookingId, $booking);
            } else {
                $stored = $this->bookingPaymentRepo->upsertByBooking([
                    'business_id' => (int) $booking['business_id'],
                    'location_id' => (int) $booking['location_id'],
                    'booking_id' => $bookingId,
                    'client_id' => isset($booking['client_id']) ? (int) $booking['client_id'] : null,
                    'currency' => (string) ($payload['currency'] ?? 'EUR'),
                    'total_due_cents' => (int) $payload['total_due_cents'],
                    'note' => $payload['note'] ?? null,
                    'updated_by_user_id' => $userId,
                ], $lines);
            }
            $this->db->commit();
        } catch (Throwable $e) {
            $this->db->rollback();
            return Response::serverError($e->getMessage(), $request->traceId);
        }

        return Response::success($this->formatPayload($stored));
    }

    private function validatePayload(array $payload): ?Response
    {
        $totalDueCents = $payload['total_due_cents'] ?? null;
        if (!is_int($totalDueCents) || $totalDueCents < 0) {
            return Response::validationError('total_due_cents must be an integer >= 0');
        }

        if (isset($payload['currency'])) {
            $currency = (string) $payload['currency'];
            if (!preg_match('/^[A-Z]{3}$/', $currency)) {
                return Response::validationError('currency must be a 3-letter ISO code');
            }
        }

        if (isset($payload['lines']) && !is_array($payload['lines'])) {
            return Response::validationError('lines must be an array');
        }

        foreach (($payload['lines'] ?? []) as $line) {
            if (!is_array($line)) {
                return Response::validationError('each payment line must be an object');
            }

            $type = (string) ($line['type'] ?? '');
            if (!in_array($type, self::ALLOWED_TYPES, true)) {
                return Response::validationError('invalid payment line type');
            }

            $amountCents = $line['amount_cents'] ?? null;
            if (!is_int($amountCents)) {
                return Response::validationError('amount_cents must be an integer');
            }

            if ($amountCents < 0) {
                return Response::validationError(
                    'amount_cents must be an integer >= 0 for this payment line type',
                );
            }

            if (isset($line['meta_json']) && !is_array($line['meta_json']) && $line['meta_json'] !== null) {
                return Response::validationError('meta_json must be an object or null');
            }
            if (isset($line['meta']) && !is_array($line['meta']) && $line['meta'] !== null) {
                return Response::validationError('meta must be an object or null');
            }
        }

        return null;
    }

    private function shouldRemovePayment(array $payload, array $lines): bool
    {
        $note = isset($payload['note']) ? trim((string) $payload['note']) : '';

        return ((int) ($payload['total_due_cents'] ?? 0)) <= 0
            && empty($lines)
            && $note === '';
    }

    private function buildEmptyPaymentPayload(int $bookingId, array $booking): array
    {
        return [
            'booking_id' => $bookingId,
            'client_id' => isset($booking['client_id']) ? (int) $booking['client_id'] : null,
            'currency' => 'EUR',
            'total_due_cents' => 0,
            'note' => null,
            'is_active' => false,
            'lines' => [],
        ];
    }

    private function formatPayload(array $payment): array
    {
        $lines = $payment['lines'] ?? [];

        $paidCents = 0;
        $discountCents = 0;

        foreach ($lines as $line) {
            $type = (string) ($line['type'] ?? '');
            $amount = (int) ($line['amount_cents'] ?? 0);
            if (in_array($type, ['cash', 'card', 'voucher', 'other'], true)) {
                $paidCents += $amount;
            } elseif ($type === 'discount') {
                $discountCents += $amount;
            }
        }

        return [
            'booking_id' => (int) $payment['booking_id'],
            'client_id' => isset($payment['client_id']) ? (int) $payment['client_id'] : null,
            'currency' => (string) ($payment['currency'] ?? 'EUR'),
            'total_due_cents' => (int) ($payment['total_due_cents'] ?? 0),
            'note' => $payment['note'] ?? null,
            'is_active' => (bool) ($payment['is_active'] ?? false),
            'lines' => array_map(
                static fn(array $line): array => [
                    'type' => (string) $line['type'],
                    'amount_cents' => (int) $line['amount_cents'],
                    'meta' => $line['meta'] ?? null,
                ],
                $lines
            ),
            'computed' => [
                'total_paid_cents' => $paidCents,
                'total_discount_cents' => $discountCents,
                'balance_cents' => (int) ($payment['total_due_cents'] ?? 0) - $paidCents - $discountCents,
            ],
        ];
    }

    private function hasBusinessAccess(Request $request, int $businessId, bool $allowReadOnly): bool
    {
        $userId = $request->userId();
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        if ($allowReadOnly) {
            $role = $this->businessUserRepo->getRole($userId, $businessId);
            if ($role === 'viewer') {
                return true;
            }
        }

        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_bookings', false);
    }
}
