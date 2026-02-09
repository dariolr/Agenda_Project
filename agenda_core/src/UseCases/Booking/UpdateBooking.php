<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Domain\Exceptions\BookingException;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\BookingAuditRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Database\Connection;
use Agenda\UseCases\Notifications\QueueBookingRescheduled;
use DateTimeImmutable;

/**
 * Use Case: Update Booking
 * 
 * Permette di aggiornare lo status o le note di un booking esistente.
 */
final class UpdateBooking
{
    public function __construct(
        private readonly BookingRepository $bookingRepo,
        private readonly Connection $db,
        private readonly ?ClientRepository $clientRepo = null,
        private readonly ?NotificationRepository $notificationRepo = null,
        private readonly ?BookingAuditRepository $auditRepo = null,
    ) {}

    /**
     * @param int $bookingId ID del booking da aggiornare
     * @param int $userId ID dell'utente che richiede l'update
     * @param array $data Dati da aggiornare: 
     *   - 'status' => string|null
     *   - 'notes' => string|null
     *   - 'start_time' => string|null (ISO8601 per reschedule)
     * 
     * @param bool $isOperator Se true, bypassa controlli permessi/policy/conflitti
     * @param bool $isCustomer Se true, usa client_id per i permessi
     * @throws BookingException
     * @return array Booking aggiornato
     */
    public function execute(
        int $bookingId,
        int $userId,
        array $data,
        bool $isOperator = false,
        bool $isCustomer = false
    ): array
    {
        // Verifica che il booking esista
        $booking = $this->bookingRepo->findById($bookingId);
        
        if ($booking === null) {
            throw BookingException::notFound('Booking not found');
        }

        // Verifica permessi: operatori possono modificare qualsiasi booking del business
        if (!$isOperator) {
            if ($isCustomer) {
                if (empty($booking['client_id']) || (int) $booking['client_id'] !== $userId) {
                    throw BookingException::unauthorized('You do not have permission to update this booking');
                }
            } else {
                if ((int) ($booking['user_id'] ?? 0) !== $userId) {
                    throw BookingException::unauthorized('You do not have permission to update this booking');
                }
            }
        }

        // Verifica cancellation policy (skip per operatori)
        if (!$isOperator) {
            $this->validateCancellationPolicy($booking);
        }

        // Se reschedule (start_time presente)
        if (isset($data['start_time'])) {
            try {
                $newStartTime = new DateTimeImmutable($data['start_time']);
            } catch (\Exception $e) {
                throw BookingException::validationError('Invalid start_time format. Use ISO8601.');
            }

            // Save old start time for notification
            $oldStartTime = null;
            if (!empty($booking['items'])) {
                $oldStartTime = $booking['items'][0]['start_time'] ?? null;
            }

            // Esegui reschedule in transazione per garantire atomicità
            $this->db->beginTransaction();
            
            try {
                // Verifica availability con FOR UPDATE (skip per operatori)
                if (!$isOperator) {
                    $this->validateAvailabilityForReschedule($booking, $newStartTime);
                }

                // Esegui reschedule
                $updated = $this->bookingRepo->rescheduleBooking(
                    $bookingId,
                    $newStartTime,
                    $data['notes'] ?? null
                );

                if (!$updated) {
                    $this->db->rollback();
                    throw BookingException::serverError('Failed to reschedule booking');
                }

                $this->db->commit();
                
            } catch (\Exception $e) {
                $this->db->rollback();
                throw $e;
            }

            // Fetch updated booking
            $updatedBooking = $this->bookingRepo->findById($bookingId);
            
            // Queue reschedule notification (if client is associated)
            $this->queueRescheduleNotification($updatedBooking, $oldStartTime);

            return $updatedBooking;
        }

        // Altrimenti update normale (status/notes/client_id)
        // Valida status se presente (operatori possono usare qualsiasi status)
        if (isset($data['status']) && !$isOperator) {
            $allowedStatuses = ['pending', 'confirmed', 'cancelled', 'completed', 'no_show'];
            if (!in_array($data['status'], $allowedStatuses, true)) {
                throw BookingException::validationError(
                    'Invalid status. Allowed: ' . implode(', ', $allowedStatuses)
                );
            }
        }

        // Cattura stato booking PRIMA dell'update per audit
        $beforeState = $this->captureBookingState($bookingId);

        // Gestione client_id: key_exists permette di distinguere "non inviato" da "inviato null"
        // Se client_id è presente nella request (anche se null), aggiorna il campo
        $clientId = null;
        $customerName = null;
        $clearClient = false;
        if (array_key_exists('client_id', $data)) {
            if ($data['client_id'] === null) {
                $clearClient = true; // Rimuovi cliente
            } else {
                $clientId = (int) $data['client_id'];
                // Deriva customerName dal client_id
                if ($this->clientRepo !== null) {
                    $client = $this->clientRepo->findById($clientId);
                    if ($client !== null) {
                        $customerName = trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? ''));
                    }
                }
            }
        }

        // Aggiorna il booking
        $updated = $this->bookingRepo->updateBooking(
            $bookingId,
            $data['status'] ?? null,
            $data['notes'] ?? null,
            $clientId,
            $customerName,
            $clearClient
        );

        if (!$updated) {
            throw BookingException::serverError('Failed to update booking');
        }

        // Se lo status viene cambiato a 'cancelled', elimina i reminder pendenti
        if (($data['status'] ?? null) === 'cancelled' && $this->notificationRepo !== null) {
            $this->notificationRepo->deletePendingReminders($bookingId);
        }

        // Cattura stato DOPO l'update per audit
        $afterState = $this->captureBookingState($bookingId);
        
        // Registra evento audit: booking_updated
        $this->createBookingUpdatedEvent(
            $bookingId,
            $beforeState,
            $afterState,
            $isOperator ? 'staff' : ($isCustomer ? 'customer' : 'customer'),
            $userId
        );

        // Ritorna il booking aggiornato
        return $this->bookingRepo->findById($bookingId);
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
            return; // No items, allow modification
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
                "Cannot modify booking within {$cancellationHours} hours of appointment start time",
                ['cancellation_deadline' => $deadline->format('c')]
            );
        }
    }

    /**
     * Valida availability per reschedule verificando conflitti staff.
     * 
     * @param array $booking Booking originale con items
     * @param DateTimeImmutable $newStartTime Nuovo orario di inizio
     * @throws BookingException Se ci sono conflitti
     */
    private function validateAvailabilityForReschedule(array $booking, DateTimeImmutable $newStartTime): void
    {
        // Recupera tutti i booking_items per calcolare offset
        $items = $booking['items'] ?? [];
        
        if (empty($items)) {
            throw BookingException::validationError('Booking has no items to reschedule');
        }

        // Calcola offset temporale
        $firstItem = $items[0];
        $oldStartTime = new DateTimeImmutable($firstItem['start_time']);
        $offsetSeconds = $newStartTime->getTimestamp() - $oldStartTime->getTimestamp();

        // Verifica conflitti per ogni booking_item
        foreach ($items as $item) {
            $oldItemStart = new DateTimeImmutable($item['start_time']);
            $oldItemEnd = new DateTimeImmutable($item['end_time']);

            $newItemStart = $oldItemStart->modify("+{$offsetSeconds} seconds");
            $newItemEnd = $oldItemEnd->modify("+{$offsetSeconds} seconds");

            // Check conflicts usando repository (con FOR UPDATE per sicurezza transazionale)
            $conflicts = $this->bookingRepo->checkConflicts(
                (int) $item['staff_id'],
                (int) $item['location_id'],
                $newItemStart,
                $newItemEnd,
                (int) $booking['id'] // Escludi booking corrente
            );

            if (!empty($conflicts)) {
                $conflictDetails = array_map(function($conflict) {
                    return [
                        'booking_id' => $conflict['booking_id'],
                        'start_time' => $conflict['start_time'],
                        'end_time' => $conflict['end_time'],
                    ];
                }, $conflicts);

                throw BookingException::slotConflict(
                    'The requested time slot is no longer available for this staff member',
                    ['conflicts' => $conflictDetails]
                );
            }
        }
    }

    /**
     * Queue reschedule notification for client.
     */
    private function queueRescheduleNotification(array $booking, ?string $oldStartTime): void
    {
        // No client = no notification
        $clientId = $booking['client_id'] ?? null;
        if ($clientId === null) {
            return;
        }
        
        if ($this->notificationRepo === null) {
            return;
        }

        try {
            // Get location and business details
            $locationData = $this->getLocationAndBusinessData((int) $booking['location_id']);
            
            // Get client email
            $clientEmail = null;
            $clientName = $booking['client_name'] ?? 'Cliente';
            if ($this->clientRepo !== null) {
                $client = $this->clientRepo->findById((int) $clientId);
                if ($client !== null) {
                    $clientEmail = $client['email'] ?? null;
                    $clientName = trim(($client['first_name'] ?? '') . ' ' . ($client['last_name'] ?? ''));
                }
            }
            
            if (empty($clientEmail)) {
                return;
            }

            // Determine sender
            $senderEmail = $locationData['location_email'] ?? $locationData['business_email'] ?? null;
            $senderName = $locationData['location_email'] 
                ? $locationData['location_name'] 
                : ($locationData['business_email'] ? $locationData['business_name'] : null);

            // Get new start time from booking items
            $newStartTime = $booking['items'][0]['start_time'] ?? null;
            if ($newStartTime === null) {
                return;
            }
            $timezoneName = $locationData['location_timezone'] ?? 'Europe/Rome';
            $locationTimezone = new \DateTimeZone($timezoneName);
            $startTime = new DateTimeImmutable($newStartTime, $locationTimezone);
            $nowLocal = new DateTimeImmutable('now', $locationTimezone);
            if ($startTime <= $nowLocal) {
                return;
            }
            
            $notificationData = [
                'booking_id' => (int) $booking['id'],
                'client_id' => (int) $clientId,
                'client_email' => $clientEmail,
                'client_name' => $clientName,
                'business_id' => (int) $booking['business_id'],
                'business_name' => $locationData['business_name'] ?? '',
                'business_email' => $locationData['business_email'] ?? '',
                'location_name' => $locationData['location_name'] ?? '',
                'location_email' => $locationData['location_email'] ?? '',
                'location_address' => $locationData['location_address'] ?? '',
                'location_city' => $locationData['location_city'] ?? '',
                'location_phone' => $locationData['location_phone'] ?? '',
                'location_timezone' => $locationData['location_timezone'] ?? 'Europe/Rome',
                'sender_email' => $senderEmail,
                'sender_name' => $senderName,
                'old_start_time' => $oldStartTime,
                'new_start_time' => $newStartTime,
                'start_time' => $newStartTime,
                'services' => implode(', ', array_column($booking['items'] ?? [], 'service_name')),
                'manage_url' => ($_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it') . '/' . ($locationData['business_slug'] ?? '') . '/my-bookings',
                'booking_url' => ($_ENV['FRONTEND_URL'] ?? 'https://prenota.romeolab.it') . '/' . ($locationData['business_slug'] ?? '') . '/booking',
                'locale' => $_ENV['DEFAULT_LOCALE'] ?? 'it',
            ];

            $rescheduledUseCase = new QueueBookingRescheduled($this->db, $this->notificationRepo);
            $rescheduledUseCase->execute($notificationData);
        } catch (\Throwable $e) {
            // Non bloccare l'operazione per errori nelle notifiche
            error_log("Failed to queue reschedule notification for booking {$booking['id']}: " . $e->getMessage());
        }
    }

    /**
     * Get location and business data for notifications.
     */
    private function getLocationAndBusinessData(int $locationId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                l.name as location_name,
                l.email as location_email,
                l.address as location_address,
                l.city as location_city,
                l.phone as location_phone,
                l.timezone as location_timezone,
                b.name as business_name,
                b.email as business_email,
                b.slug as business_slug
             FROM locations l
             JOIN businesses b ON l.business_id = b.id
             WHERE l.id = ?'
        );
        $stmt->execute([$locationId]);
        return $stmt->fetch(\PDO::FETCH_ASSOC) ?: [];
    }

    /**
     * Cattura lo stato del booking per l'audit
     */
    private function captureBookingState(int $bookingId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, location_id, client_id, customer_name, status, notes, source
             FROM bookings
             WHERE id = ?'
        );
        $stmt->execute([$bookingId]);
        $booking = $stmt->fetch(\PDO::FETCH_ASSOC);
        
        return $booking ?: [];
    }

    /**
     * Registra evento booking_updated
     */
    private function createBookingUpdatedEvent(
        int $bookingId,
        array $before,
        array $after,
        string $actorType,
        int $actorId
    ): void {
        if ($this->auditRepo === null || empty($before) || empty($after)) {
            return;
        }
        
        // Calcola campi modificati
        $changedFields = [];
        $fieldsToTrack = ['client_id', 'customer_name', 'status', 'notes'];
        foreach ($fieldsToTrack as $field) {
            if (($before[$field] ?? null) !== ($after[$field] ?? null)) {
                $changedFields[] = $field;
            }
        }
        
        // Se nessun campo è cambiato, non registrare evento
        if (empty($changedFields)) {
            return;
        }
        
        try {
            // Resolve actor name for denormalization
            $actorName = $this->auditRepo->resolveActorName($actorType, $actorId);
            
            $this->auditRepo->createEvent(
                $bookingId,
                'booking_updated',
                $actorType,
                $actorId,
                [
                    'booking_id' => $bookingId,
                    'before' => $before,
                    'after' => $after,
                    'changed_fields' => $changedFields,
                ],
                null,
                $actorName
            );
        } catch (\Throwable $e) {
            error_log("Failed to create booking_updated event: " . $e->getMessage());
        }
    }
}
