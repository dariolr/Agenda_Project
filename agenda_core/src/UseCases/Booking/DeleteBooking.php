<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Domain\Exceptions\BookingException;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\NotificationRepository;
use Agenda\Infrastructure\Database\Connection;
use Agenda\UseCases\Notification\QueueBookingCancellation;
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
    ) {}

    /**
     * @param int $bookingId ID del booking da cancellare
     * @param int $userId ID dell'utente che richiede la cancellazione
     * @param bool $isOperator Se true, bypassa controlli permessi/policy
     * 
     * @throws BookingException
     * @return void
     */
    public function execute(int $bookingId, int $userId, bool $isOperator = false): void
    {
        // Verifica che il booking esista
        $booking = $this->bookingRepo->findById($bookingId);
        
        if ($booking === null) {
            throw BookingException::notFound('Booking not found');
        }

        // Verifica permessi: operatori possono cancellare qualsiasi booking del business
        if (!$isOperator && $booking['user_id'] !== $userId) {
            throw BookingException::unauthorized('You do not have permission to delete this booking');
        }

        // Verifica cancellation policy (skip per operatori)
        if (!$isOperator) {
            $this->validateCancellationPolicy($booking);
        }
        
        // Prepara i dati per la notifica prima di cancellare
        $notificationData = $this->prepareNotificationData($booking);
        
        // Cancella il booking (e i suoi items tramite il repository)
        $deleted = $this->bookingRepo->deleteBooking($bookingId);

        if (!$deleted) {
            throw BookingException::serverError('Failed to delete booking');
        }
        
        // Invia notifica di cancellazione (non bloccante)
        $this->queueCancellationNotification($notificationData);
    }

    private function prepareNotificationData(array $booking): array
    {
        // Get booking details before deletion including location and business emails
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                bi.start_time,
                s.name as service_name,
                st.first_name as staff_first_name,
                st.last_name as staff_last_name,
                u.email as customer_email,
                u.first_name as customer_first_name,
                u.last_name as customer_last_name,
                l.name as location_name,
                l.address as location_address,
                l.email as location_email,
                b.name as business_name,
                b.email as business_email
             FROM booking_items bi
             JOIN services s ON bi.service_id = s.id
             LEFT JOIN staff st ON bi.staff_id = st.id
             JOIN bookings bk ON bi.booking_id = bk.id
             JOIN users u ON bk.user_id = u.id
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
        
        // Priority: location email > business email
        $senderEmail = $details['location_email'] ?? $details['business_email'] ?? null;
        $senderName = $details['location_email'] 
            ? $details['location_name'] 
            : ($details['business_email'] ? $details['business_name'] : null);
        
        return [
            'booking_id' => $booking['id'],
            'user_id' => $booking['user_id'] ?? null,
            'business_id' => $booking['business_id'] ?? null,
            'customer_email' => $details['customer_email'],
            'customer_name' => trim($details['customer_first_name'] . ' ' . ($details['customer_last_name'] ?? '')),
            'service_name' => $details['service_name'],
            'staff_name' => trim(($details['staff_first_name'] ?? '') . ' ' . ($details['staff_last_name'] ?? '')),
            'date_time' => (new DateTimeImmutable($details['start_time']))->format('d/m/Y H:i'),
            'location_name' => $details['location_name'] ?? '',
            'location_address' => $details['location_address'] ?? '',
            'location_email' => $details['location_email'] ?? '',
            'business_name' => $details['business_name'] ?? 'Agenda',
            'business_email' => $details['business_email'] ?? '',
            'sender_email' => $senderEmail,
            'sender_name' => $senderName,
        ];
    }

    private function queueCancellationNotification(array $data): void
    {
        if ($this->notificationRepo === null || empty($data)) {
            return;
        }
        
        try {
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
}
