<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Domain\Exceptions\BookingException;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\BookingAuditRepository;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Database\Connection;
use Agenda\UseCases\Notifications\QueueBookingCancellation;
use DateTimeImmutable;

/**
 * Use Case: Delete Booking
 * 
 * Permette di cancellare un booking e tutti i suoi booking_items associati.
 */
final class DeleteBooking
{
    public function __construct(
        private readonly BookingRepository $bookingRepo,
        private readonly Connection $db,
        private readonly ?NotificationRepository $notificationRepo = null,
        private readonly ?BookingAuditRepository $auditRepo = null,
    ) {}

    /**
     * @param int $bookingId ID del booking da cancellare
     * @param int $userId ID dell'utente che richiede la cancellazione
     * @param bool $isOperator Se true, bypassa controlli permessi/policy
     * @param bool $isCustomer Se true, usa client_id per i permessi
     * 
     * @throws BookingException
     * @return void
     */
    public function execute(
        int $bookingId,
        int $userId,
        bool $isOperator = false,
        bool $isCustomer = false
    ): void
    {
        // Verifica che il booking esista
        $booking = $this->bookingRepo->findById($bookingId);
        
        if ($booking === null) {
            throw BookingException::notFound('Booking not found');
        }

        // Verifica permessi: operatori possono cancellare qualsiasi booking del business
        if (!$isOperator) {
            if ($isCustomer) {
                if (empty($booking['client_id']) || (int) $booking['client_id'] !== $userId) {
                    throw BookingException::unauthorized('You do not have permission to delete this booking');
                }
            } else {
                if ((int) ($booking['user_id'] ?? 0) !== $userId) {
                    throw BookingException::unauthorized('You do not have permission to delete this booking');
                }
            }
        }

        // Verifica cancellation policy (skip per operatori)
        if (!$isOperator) {
            $this->validateCancellationPolicy($booking);
        }
        
        // Prepara i dati per la notifica prima di cancellare
        $notificationData = $this->prepareNotificationData($booking);
        
        // Cattura stato booking per audit prima della cancellazione
        $bookingStateForAudit = $this->captureBookingStateForAudit($bookingId);
        
        // Cancella il booking (e i suoi items tramite il repository)
        $deleted = $this->bookingRepo->deleteBooking($bookingId);

        if (!$deleted) {
            throw BookingException::serverError('Failed to delete booking');
        }
        
        // Registra evento audit: booking_cancelled
        $this->createBookingCancelledEvent(
            $bookingStateForAudit,
            $isOperator ? 'staff' : ($isCustomer ? 'customer' : 'customer'),
            $userId
        );
        
        // Invia notifica di cancellazione (non bloccante)
        $this->queueCancellationNotification($notificationData);
    }

    private function prepareNotificationData(array $booking): array
    {
        // Get booking details before deletion including location and business emails
        // NOTE: notifications go to CLIENT (from clients table), not user (operator)
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                bi.start_time,
                s.name as service_name,
                st.name as staff_first_name,
                st.surname as staff_last_name,
                c.id as client_id,
                c.email as client_email,
                c.first_name as client_first_name,
                c.last_name as client_last_name,
                l.id as location_id,
                l.name as location_name,
                l.address as location_address,
                l.email as location_email,
                l.timezone as location_timezone,
                b.name as business_name,
                b.email as business_email,
                b.slug as business_slug
             FROM booking_items bi
             JOIN services s ON bi.service_id = s.id
             LEFT JOIN staff st ON bi.staff_id = st.id
             JOIN bookings bk ON bi.booking_id = bk.id
             LEFT JOIN clients c ON bk.client_id = c.id
             LEFT JOIN locations l ON bk.location_id = l.id
             LEFT JOIN businesses b ON bk.business_id = b.id
             WHERE bi.booking_id = ?
             ORDER BY bi.start_time ASC
             LIMIT 1'
        );
        $stmt->execute([$booking['id']]);
        $details = $stmt->fetch();
        
        if (!$details) {
            return [];
        }
        
        // If no client associated, cannot send notification
        if (empty($details['client_id']) || empty($details['client_email'])) {
            return [];
        }
        
        // Get ALL service names for this booking
        $stmtServices = $this->db->getPdo()->prepare(
            'SELECT s.name as service_name
             FROM booking_items bi
             JOIN services s ON bi.service_id = s.id
             WHERE bi.booking_id = ?
             ORDER BY bi.start_time ASC'
        );
        $stmtServices->execute([$booking['id']]);
        $allServices = $stmtServices->fetchAll(\PDO::FETCH_COLUMN);
        $servicesString = implode(', ', $allServices);
        
        // Priority: location email > business email
        $senderEmail = $details['location_email'] ?? $details['business_email'] ?? null;
        $senderName = $details['location_email'] 
            ? $details['location_name'] 
            : ($details['business_email'] ? $details['business_name'] : null);
        
        // Build booking URL for "Book again" button (with location pre-selected)
        $bookingUrl = ($_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it') . '/' . ($details['business_slug'] ?? '') . '/booking';
        if (!empty($details['location_id'])) {
            $bookingUrl .= '?location=' . $details['location_id'];
        }
        
        return [
            'booking_id' => $booking['id'],
            'client_id' => $details['client_id'],
            'client_email' => $details['client_email'],
            'client_name' => trim($details['client_first_name'] . ' ' . ($details['client_last_name'] ?? '')),
            'business_id' => $booking['business_id'] ?? null,
            'service_name' => $details['service_name'],
            'services' => $servicesString,
            'start_time' => $details['start_time'],
            'staff_name' => trim(($details['staff_first_name'] ?? '') . ' ' . ($details['staff_last_name'] ?? '')),
            'date_time' => (new DateTimeImmutable($details['start_time']))->format('d/m/Y H:i'),
            'location_name' => $details['location_name'] ?? '',
            'location_address' => $details['location_address'] ?? '',
            'location_email' => $details['location_email'] ?? '',
            'location_timezone' => $details['location_timezone'] ?? null,
            'business_name' => $details['business_name'] ?? 'Agenda',
            'business_email' => $details['business_email'] ?? '',
            'sender_email' => $senderEmail,
            'sender_name' => $senderName,
            'booking_url' => $bookingUrl,
            'locale' => $_ENV['DEFAULT_LOCALE'] ?? 'it',
        ];
    }

    private function queueCancellationNotification(array $data): void
    {
        if ($this->notificationRepo === null || empty($data)) {
            return;
        }
        
        try {
            $timezoneName = $data['location_timezone'] ?? 'Europe/Rome';
            $locationTimezone = new \DateTimeZone($timezoneName);
            if (!empty($data['start_time'])) {
                $startTime = new DateTimeImmutable($data['start_time'], $locationTimezone);
                $nowLocal = new DateTimeImmutable('now', $locationTimezone);
                if ($startTime <= $nowLocal) {
                    return;
                }
            }

            $cancellationUseCase = new QueueBookingCancellation($this->db, $this->notificationRepo);
            $cancellationUseCase->execute($data);
        } catch (\Throwable $e) {
            // Non blocchiamo la cancellazione per errori nelle notifiche
            error_log("Failed to queue cancellation notification for booking {$data['booking_id']}: " . $e->getMessage());
        }
    }

    private function validateCancellationPolicy(array $booking): void
    {
        // Get earliest start_time from booking_items
        $stmt = $this->db->getPdo()->prepare(
            'SELECT MIN(start_time) as earliest_start 
             FROM booking_items WHERE booking_id = ?'
        );
        $stmt->execute([$booking['id']]);
        $result = $stmt->fetch();
        
        if ($result === null || $result['earliest_start'] === null) {
            return; // No items, allow cancellation
        }
        
        $startTime = new DateTimeImmutable($result['earliest_start']);
        $now = new DateTimeImmutable();
        
        // Get cancellation policy (location override or business default)
        $stmt = $this->db->getPdo()->prepare(
            'SELECT l.cancellation_hours as location_policy, 
                    b.cancellation_hours as business_policy
             FROM locations l
             JOIN businesses b ON l.business_id = b.id
             WHERE l.id = ?'
        );
        $stmt->execute([$booking['location_id']]);
        $policyData = $stmt->fetch();
        
        $cancellationHours = $policyData['location_policy'] ?? $policyData['business_policy'] ?? 24;
        
        // Calculate deadline
        $deadline = $startTime->modify("-{$cancellationHours} hours");
        
        if ($now >= $deadline) {
            throw BookingException::validationError(
                "Cannot cancel booking within {$cancellationHours} hours of appointment start time",
                ['cancellation_deadline' => $deadline->format('c')]
            );
        }
    }

    /**
     * Cattura lo stato completo del booking per l'audit prima della cancellazione
     */
    private function captureBookingStateForAudit(int $bookingId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT b.id, b.business_id, b.location_id, b.client_id, b.status, b.notes, b.source
             FROM bookings b
             WHERE b.id = ?'
        );
        $stmt->execute([$bookingId]);
        $booking = $stmt->fetch();
        
        if (!$booking) {
            return [];
        }
        
        // Get items
        $stmt = $this->db->getPdo()->prepare(
            'SELECT bi.id, bi.service_id, bi.staff_id, bi.start_time, bi.end_time, bi.price
             FROM booking_items bi
             WHERE bi.booking_id = ?
             ORDER BY bi.start_time ASC'
        );
        $stmt->execute([$bookingId]);
        $items = $stmt->fetchAll();
        
        $totalPrice = 0;
        foreach ($items as $item) {
            $totalPrice += (float) ($item['price'] ?? 0);
        }
        
        return [
            'booking_id' => $booking['id'],
            'business_id' => $booking['business_id'],
            'location_id' => $booking['location_id'],
            'client_id' => $booking['client_id'],
            'status' => $booking['status'],
            'notes' => $booking['notes'],
            'source' => $booking['source'],
            'items' => $items,
            'total_price' => $totalPrice,
            'first_start_time' => $items[0]['start_time'] ?? null,
            'last_end_time' => end($items)['end_time'] ?? null,
        ];
    }

    /**
     * Registra evento booking_cancelled
     */
    private function createBookingCancelledEvent(
        array $bookingState,
        string $actorType,
        int $actorId
    ): void {
        if ($this->auditRepo === null || empty($bookingState)) {
            return;
        }
        
        try {
            // Resolve actor name for denormalization
            $actorName = $this->auditRepo->resolveActorName($actorType, $actorId);
            
            $this->auditRepo->createEvent(
                (int) $bookingState['booking_id'],
                'booking_cancelled',
                $actorType,
                $actorId,
                $bookingState,
                null,
                $actorName
            );
        } catch (\Throwable $e) {
            error_log("Failed to create booking_cancelled event: " . $e->getMessage());
        }
    }
}
