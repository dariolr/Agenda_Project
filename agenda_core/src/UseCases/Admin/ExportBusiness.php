<?php

declare(strict_types=1);

namespace Agenda\UseCases\Admin;

use Agenda\Infrastructure\Database\Connection;

/**
 * Esporta tutti i dati di un business per sincronizzazione staging.
 * NON include: sessioni, token, notification_queue
 */
final class ExportBusiness
{
    public function __construct(
        private Connection $db
    ) {}

    public function execute(int $businessId): array
    {
        $pdo = $this->db->getPdo();
        
        // Verifica esistenza business
        $stmt = $pdo->prepare('SELECT * FROM businesses WHERE id = ?');
        $stmt->execute([$businessId]);
        $business = $stmt->fetch(\PDO::FETCH_ASSOC);
        
        if (!$business) {
            throw new \InvalidArgumentException("Business ID $businessId non trovato");
        }
        
        $export = [
            'exported_at' => date('Y-m-d H:i:s'),
            'business' => $business,
            'locations' => [],
            'categories' => [],
            'staff' => [],
            'staff_services' => [],
            'staff_availability_exceptions' => [],
            'staff_planning' => [],
            'staff_planning_week_template' => [],
            'services' => [],
            'service_variants' => [],
            'clients' => [],
            'resources' => [],
            'time_blocks' => [],
            'time_block_staff' => [],
            'bookings' => [],
            'appointments' => [],
            'appointment_services' => [],
            'users' => [],
            'business_users' => [],
        ];
        
        // Locations
        $stmt = $pdo->prepare('SELECT * FROM locations WHERE business_id = ?');
        $stmt->execute([$businessId]);
        $export['locations'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        $locationIds = array_column($export['locations'], 'id');
        
        // Categories
        $stmt = $pdo->prepare('SELECT * FROM categories WHERE business_id = ?');
        $stmt->execute([$businessId]);
        $export['categories'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        
        // Staff
        $stmt = $pdo->prepare('SELECT * FROM staff WHERE business_id = ?');
        $stmt->execute([$businessId]);
        $export['staff'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        $staffIds = array_column($export['staff'], 'id');
        
        if (!empty($staffIds)) {
            $placeholders = implode(',', array_fill(0, count($staffIds), '?'));
            
            // Staff Services
            $stmt = $pdo->prepare("SELECT * FROM staff_services WHERE staff_id IN ($placeholders)");
            $stmt->execute($staffIds);
            $export['staff_services'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            
            // Staff Availability Exceptions
            $stmt = $pdo->prepare("SELECT * FROM staff_availability_exceptions WHERE staff_id IN ($placeholders)");
            $stmt->execute($staffIds);
            $export['staff_availability_exceptions'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            
            // Staff Planning
            $stmt = $pdo->prepare("SELECT * FROM staff_planning WHERE staff_id IN ($placeholders)");
            $stmt->execute($staffIds);
            $export['staff_planning'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            $planningIds = array_column($export['staff_planning'], 'id');
            
            if (!empty($planningIds)) {
                $placeholders2 = implode(',', array_fill(0, count($planningIds), '?'));
                $stmt = $pdo->prepare("SELECT * FROM staff_planning_week_template WHERE staff_planning_id IN ($placeholders2)");
                $stmt->execute($planningIds);
                $export['staff_planning_week_template'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            }
            
            // Appointments (per staff)
            $stmt = $pdo->prepare("SELECT * FROM appointments WHERE staff_id IN ($placeholders)");
            $stmt->execute($staffIds);
            $export['appointments'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            $appointmentIds = array_column($export['appointments'], 'id');
            
            if (!empty($appointmentIds)) {
                $placeholders3 = implode(',', array_fill(0, count($appointmentIds), '?'));
                
                // Appointment Services
                $stmt = $pdo->prepare("SELECT * FROM appointment_services WHERE appointment_id IN ($placeholders3)");
                $stmt->execute($appointmentIds);
                $export['appointment_services'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            }
            
            // Bookings (solo quelli con appointments di questo business)
            $bookingIds = array_unique(array_filter(array_column($export['appointments'], 'booking_id')));
            if (!empty($bookingIds)) {
                $placeholders4 = implode(',', array_fill(0, count($bookingIds), '?'));
                $stmt = $pdo->prepare("SELECT * FROM bookings WHERE id IN ($placeholders4)");
                $stmt->execute($bookingIds);
                $export['bookings'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            }
        }
        
        if (!empty($locationIds)) {
            $placeholders = implode(',', array_fill(0, count($locationIds), '?'));
            
            // Services
            $stmt = $pdo->prepare("SELECT * FROM services WHERE location_id IN ($placeholders)");
            $stmt->execute($locationIds);
            $export['services'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            $serviceIds = array_column($export['services'], 'id');
            
            if (!empty($serviceIds)) {
                $placeholders2 = implode(',', array_fill(0, count($serviceIds), '?'));
                $stmt = $pdo->prepare("SELECT * FROM service_variants WHERE service_id IN ($placeholders2)");
                $stmt->execute($serviceIds);
                $export['service_variants'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            }
            
            // Resources
            $stmt = $pdo->prepare("SELECT * FROM resources WHERE location_id IN ($placeholders)");
            $stmt->execute($locationIds);
            $export['resources'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            
            // Time Blocks
            $stmt = $pdo->prepare("SELECT * FROM time_blocks WHERE location_id IN ($placeholders)");
            $stmt->execute($locationIds);
            $export['time_blocks'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            $blockIds = array_column($export['time_blocks'], 'id');
            
            if (!empty($blockIds)) {
                $placeholders2 = implode(',', array_fill(0, count($blockIds), '?'));
                $stmt = $pdo->prepare("SELECT * FROM time_block_staff WHERE time_block_id IN ($placeholders2)");
                $stmt->execute($blockIds);
                $export['time_block_staff'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            }
        }
        
        // Clients (senza password_hash per sicurezza)
        $stmt = $pdo->prepare('SELECT id, business_id, email, first_name, last_name, phone, notes, 
                               email_verified_at, created_at, updated_at 
                               FROM clients WHERE business_id = ?');
        $stmt->execute([$businessId]);
        $export['clients'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        
        // Business Users
        $stmt = $pdo->prepare('SELECT * FROM business_users WHERE business_id = ?');
        $stmt->execute([$businessId]);
        $export['business_users'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        
        // Users (admin del business, senza password_hash)
        $userIds = array_column($export['business_users'], 'user_id');
        if (!empty($userIds)) {
            $placeholders = implode(',', array_fill(0, count($userIds), '?'));
            $stmt = $pdo->prepare("SELECT id, email, first_name, last_name, phone, is_superadmin, 
                                   email_verified_at, created_at, updated_at 
                                   FROM users WHERE id IN ($placeholders)");
            $stmt->execute($userIds);
            $export['users'] = $stmt->fetchAll(\PDO::FETCH_ASSOC);
        }
        
        return $export;
    }
    
    /**
     * Esegue export tramite slug
     */
    public function executeBySlug(string $slug): array
    {
        $stmt = $this->db->getPdo()->prepare('SELECT id FROM businesses WHERE slug = ?');
        $stmt->execute([$slug]);
        $business = $stmt->fetch(\PDO::FETCH_ASSOC);
        
        if (!$business) {
            throw new \InvalidArgumentException("Business con slug '$slug' non trovato");
        }
        
        return $this->execute((int)$business['id']);
    }
}
