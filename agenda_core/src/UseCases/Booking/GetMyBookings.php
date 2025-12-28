<?php

declare(strict_types=1);

namespace Agenda\UseCases\Booking;

use Agenda\Infrastructure\Database\Connection;
use DateTimeImmutable;

final class GetMyBookings
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Get all bookings for the authenticated user.
     * @return array{upcoming: array, past: array}
     */
    public function execute(int $userId): array
    {
        // Find all bookings for this user across all businesses
        // Query booking_items per aggregare service_names
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 
                b.id as booking_id,
                b.status,
                b.notes,
                b.created_at,
                bi.id as item_id,
                bi.start_time,
                bi.end_time,
                bi.price as item_price,
                bi.duration_minutes,
                sv.id as service_variant_id,
                s.name as service_name,
                st.name as staff_first_name,
                st.surname as staff_surname,
                l.id as location_id,
                l.name as location_name,
                l.address as location_address,
                l.city as location_city,
                l.phone as location_phone,
                l.cancellation_hours as location_cancellation_hours,
                bus.id as business_id,
                bus.name as business_name,
                bus.cancellation_hours as business_cancellation_hours
             FROM bookings b
             JOIN locations l ON b.location_id = l.id
             JOIN businesses bus ON l.business_id = bus.id
             LEFT JOIN booking_items bi ON b.id = bi.booking_id
             LEFT JOIN service_variants sv ON bi.service_variant_id = sv.id
             LEFT JOIN services s ON sv.service_id = s.id
             LEFT JOIN staff st ON bi.staff_id = st.id
             WHERE b.user_id = ?
               AND b.status NOT IN ("cancelled")
             ORDER BY b.id, bi.start_time ASC'
        );
        $stmt->execute([$userId]);
        $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        // Aggrega per booking_id
        $bookingsMap = [];
        foreach ($rows as $row) {
            $bookingId = (int) $row['booking_id'];
            
            if (!isset($bookingsMap[$bookingId])) {
                $bookingsMap[$bookingId] = [
                    'booking_id' => $bookingId,
                    'status' => $row['status'],
                    'notes' => $row['notes'],
                    'created_at' => $row['created_at'],
                    'location_id' => (int) $row['location_id'],
                    'location_name' => $row['location_name'],
                    'location_address' => $row['location_address'],
                    'location_city' => $row['location_city'],
                    'location_phone' => $row['location_phone'],
                    'location_cancellation_hours' => $row['location_cancellation_hours'],
                    'business_id' => (int) $row['business_id'],
                    'business_name' => $row['business_name'],
                    'business_cancellation_hours' => $row['business_cancellation_hours'],
                    'service_names' => [],
                    'service_ids' => [],
                    'staff_name' => null,
                    'start_time' => null,
                    'end_time' => null,
                    'total_price' => 0.0,
                ];
            }
            
            // Aggrega service names e IDs
            if ($row['service_name'] && !in_array($row['service_name'], $bookingsMap[$bookingId]['service_names'], true)) {
                $bookingsMap[$bookingId]['service_names'][] = $row['service_name'];
            }
            if ($row['service_variant_id'] && !in_array((int) $row['service_variant_id'], $bookingsMap[$bookingId]['service_ids'], true)) {
                $bookingsMap[$bookingId]['service_ids'][] = (int) $row['service_variant_id'];
            }
            
            // Staff name (primo trovato)
            if ($bookingsMap[$bookingId]['staff_name'] === null && $row['staff_first_name']) {
                $staffName = trim($row['staff_first_name'] . ' ' . ($row['staff_surname'] ?? ''));
                $bookingsMap[$bookingId]['staff_name'] = $staffName;
            }
            
            // Start/end time (primo/ultimo item)
            if ($row['start_time']) {
                if ($bookingsMap[$bookingId]['start_time'] === null || $row['start_time'] < $bookingsMap[$bookingId]['start_time']) {
                    $bookingsMap[$bookingId]['start_time'] = $row['start_time'];
                }
                if ($bookingsMap[$bookingId]['end_time'] === null || $row['end_time'] > $bookingsMap[$bookingId]['end_time']) {
                    $bookingsMap[$bookingId]['end_time'] = $row['end_time'];
                }
            }
            
            // Somma prezzi
            $bookingsMap[$bookingId]['total_price'] += (float) ($row['item_price'] ?? 0);
        }

        $now = new DateTimeImmutable();
        $upcoming = [];
        $past = [];

        foreach ($bookingsMap as $booking) {
            if ($booking['start_time'] === null) {
                continue; // Skip booking senza items
            }
            
            $startTime = new DateTimeImmutable($booking['start_time']);
            
            // Determine cancellation policy
            $cancellationHours = $booking['location_cancellation_hours'] 
                ?? $booking['business_cancellation_hours'] 
                ?? 24;
            
            $canModifyUntil = $startTime->modify("-{$cancellationHours} hours");
            $booking['can_modify'] = $now < $canModifyUntil;
            $booking['can_modify_until'] = $canModifyUntil->format('c');
            
            // Rimuovi campi interni
            unset($booking['location_cancellation_hours'], $booking['business_cancellation_hours']);
            
            // Group by upcoming/past
            if ($startTime > $now) {
                $upcoming[] = $booking;
            } else {
                $past[] = $booking;
            }
        }
        
        // Ordina: upcoming ASC (prossimo prima), past DESC (recente prima)
        usort($upcoming, fn($a, $b) => strcmp($a['start_time'], $b['start_time']));
        usort($past, fn($a, $b) => strcmp($b['start_time'], $a['start_time']));

        return [
            'upcoming' => $upcoming,
            'past' => $past,
        ];
    }
}
