<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class BookingNotificationsController
{
    public function __construct(
        private readonly NotificationRepository $notificationRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    private function hasBusinessAccess(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin((int) $userId)) {
            return true;
        }

        return $this->businessUserRepo->hasAccess(
            (int) $userId,
            $businessId,
            false
        );
    }

    /**
     * GET /v1/businesses/{business_id}/booking-notifications
     */
    public function index(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');

        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        $filters = [];

        if ($request->queryParam('search') !== null) {
            $filters['search'] = trim((string) $request->queryParam('search'));
        }

        if ($request->queryParam('status') !== null) {
            $statusParam = (string) $request->queryParam('status');
            $filters['status'] = strpos($statusParam, ',') !== false
                ? array_values(array_filter(array_map('trim', explode(',', $statusParam))))
                : $statusParam;
        }

        if ($request->queryParam('channel') !== null) {
            $channelParam = (string) $request->queryParam('channel');
            $filters['channel'] = strpos($channelParam, ',') !== false
                ? array_values(array_filter(array_map('trim', explode(',', $channelParam))))
                : $channelParam;
        }

        if ($request->queryParam('start_date') !== null) {
            $filters['start_date'] = (string) $request->queryParam('start_date');
        }

        if ($request->queryParam('end_date') !== null) {
            $filters['end_date'] = (string) $request->queryParam('end_date');
        }

        if ($request->queryParam('sort_by') !== null) {
            $filters['sort_by'] = (string) $request->queryParam('sort_by');
        }

        if ($request->queryParam('sort_order') !== null) {
            $filters['sort_order'] = (string) $request->queryParam('sort_order');
        }

        $limit = min(100, max(1, (int) ($request->queryParam('limit') ?? 50)));
        $offset = max(0, (int) ($request->queryParam('offset') ?? 0));

        $result = $this->notificationRepo->findBookingNotificationsWithFilters(
            $businessId,
            $filters,
            $limit,
            $offset
        );

        $formatted = array_map(
            fn(array $item) => $this->formatNotificationForList($item),
            $result['notifications']
        );

        return Response::success([
            'notifications' => $formatted,
            'total' => $result['total'],
            'limit' => $limit,
            'offset' => $offset,
        ]);
    }

    /**
     * @param array<string, mixed> $item
     * @return array<string, mixed>
     */
    private function formatNotificationForList(array $item): array
    {
        $clientName = $item['booking_client_name'] ?? null;
        if (empty($clientName)) {
            $first = trim((string) ($item['client_first_name'] ?? ''));
            $last = trim((string) ($item['client_last_name'] ?? ''));
            $full = trim($first . ' ' . $last);
            $clientName = $full !== '' ? $full : null;
        }

        return [
            'id' => (int) $item['id'],
            'booking_id' => $item['booking_id'] !== null ? (int) $item['booking_id'] : null,
            'business_id' => (int) $item['business_id'],
            'location_id' => $item['location_id'] !== null ? (int) $item['location_id'] : null,
            'location_name' => $item['location_name'] ?? null,
            'client_name' => $clientName,
            'channel' => (string) ($item['channel'] ?? ''),
            'status' => (string) ($item['status'] ?? ''),
            'recipient_email' => $item['recipient_email'] ?? null,
            'recipient_name' => $item['recipient_name'] ?? null,
            'subject' => $item['subject'] ?? null,
            'error_message' => $item['error_message'] ?? null,
            'attempts' => (int) ($item['attempts'] ?? 0),
            'max_attempts' => (int) ($item['max_attempts'] ?? 0),
            'created_at' => $item['created_at'] ?? null,
            'scheduled_at' => $item['scheduled_at'] ?? null,
            'sent_at' => $item['sent_at'] ?? null,
            'failed_at' => $item['failed_at'] ?? null,
            'first_start_time' => $item['first_start_time'] ?? null,
            'last_end_time' => $item['last_end_time'] ?? null,
        ];
    }
}
