<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Domain\Exceptions\BookingException;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Database\Connection;
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
     * @throws BookingException
     * @return array Booking aggiornato
     */
    public function execute(int $bookingId, int $userId, array $data, bool $isOperator = false): array
    {
        // Verifica che il booking esista
        $booking = $this->bookingRepo->findById($bookingId);
        
        if ($booking === null) {
            throw BookingException::notFound('Booking not found');
        }

        // Verifica permessi: operatori possono modificare qualsiasi booking del business
        if (!$isOperator && $booking['user_id'] !== $userId) {
            throw BookingException::unauthorized('You do not have permission to update this booking');
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

            return $this->bookingRepo->findById($bookingId);
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
}