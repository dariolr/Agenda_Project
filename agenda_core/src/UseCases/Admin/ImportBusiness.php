<?php

declare(strict_types=1);

namespace Agenda\UseCases\Admin;

use Agenda\Infrastructure\Database\Connection;

/**
 * Importa dati di un business da export JSON.
 * Usato per sincronizzare dati da produzione a staging.
 * 
 * ATTENZIONE: Questo UseCase ELIMINA tutti i dati esistenti del business prima di importare!
 */
final class ImportBusiness
{
    public function __construct(
        private Connection $db
    ) {}

    public function execute(array $exportData): array
    {
        $pdo = $this->db->getPdo();
        
        if (empty($exportData['business'])) {
            throw new \InvalidArgumentException('Dati business mancanti');
        }
        
        $businessId = (int)$exportData['business']['id'];
        $businessName = $exportData['business']['name'] ?? 'Unknown';
        
        $stats = [
            'business_id' => $businessId,
            'business_name' => $businessName,
            'deleted' => [],
            'imported' => [],
        ];
        
        $pdo->beginTransaction();
        
        try {
            // ===== FASE 1: ELIMINAZIONE DATI ESISTENTI =====
            $pdo->exec('SET FOREIGN_KEY_CHECKS = 0');
            
            // Elimina notification_queue per questo business
            $stmt = $pdo->prepare('DELETE FROM notification_queue WHERE business_id = ?');
            $stmt->execute([$businessId]);
            $stats['deleted']['notification_queue'] = $stmt->rowCount();
            
            // Elimina appointment_services
            $stmt = $pdo->prepare('
                DELETE FROM appointment_services WHERE appointment_id IN (
                    SELECT id FROM appointments WHERE staff_id IN (
                        SELECT id FROM staff WHERE business_id = ?
                    )
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['appointment_services'] = $stmt->rowCount();
            
            // Elimina appointments
            $stmt = $pdo->prepare('
                DELETE FROM appointments WHERE staff_id IN (
                    SELECT id FROM staff WHERE business_id = ?
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['appointments'] = $stmt->rowCount();
            
            // Elimina bookings orfani
            $stmt = $pdo->query('DELETE FROM bookings WHERE id NOT IN (SELECT DISTINCT booking_id FROM appointments WHERE booking_id IS NOT NULL)');
            $stats['deleted']['bookings_orphan'] = $stmt->rowCount();
            
            // Elimina time_block_staff
            $stmt = $pdo->prepare('
                DELETE FROM time_block_staff WHERE time_block_id IN (
                    SELECT id FROM time_blocks WHERE location_id IN (
                        SELECT id FROM locations WHERE business_id = ?
                    )
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['time_block_staff'] = $stmt->rowCount();
            
            // Elimina time_blocks
            $stmt = $pdo->prepare('
                DELETE FROM time_blocks WHERE location_id IN (
                    SELECT id FROM locations WHERE business_id = ?
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['time_blocks'] = $stmt->rowCount();
            
            // Elimina resources
            $stmt = $pdo->prepare('
                DELETE FROM resources WHERE location_id IN (
                    SELECT id FROM locations WHERE business_id = ?
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['resources'] = $stmt->rowCount();
            
            // Elimina staff_planning_week_template
            $stmt = $pdo->prepare('
                DELETE FROM staff_planning_week_template WHERE staff_planning_id IN (
                    SELECT id FROM staff_planning WHERE staff_id IN (
                        SELECT id FROM staff WHERE business_id = ?
                    )
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['staff_planning_week_template'] = $stmt->rowCount();
            
            // Elimina staff_planning
            $stmt = $pdo->prepare('
                DELETE FROM staff_planning WHERE staff_id IN (
                    SELECT id FROM staff WHERE business_id = ?
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['staff_planning'] = $stmt->rowCount();
            
            // Elimina staff_availability_exceptions
            $stmt = $pdo->prepare('
                DELETE FROM staff_availability_exceptions WHERE staff_id IN (
                    SELECT id FROM staff WHERE business_id = ?
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['staff_availability_exceptions'] = $stmt->rowCount();
            
            // Elimina staff_services
            $stmt = $pdo->prepare('
                DELETE FROM staff_services WHERE staff_id IN (
                    SELECT id FROM staff WHERE business_id = ?
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['staff_services'] = $stmt->rowCount();
            
            // Elimina service_variants
            $stmt = $pdo->prepare('
                DELETE FROM service_variants WHERE service_id IN (
                    SELECT id FROM services WHERE location_id IN (
                        SELECT id FROM locations WHERE business_id = ?
                    )
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['service_variants'] = $stmt->rowCount();
            
            // Elimina services
            $stmt = $pdo->prepare('
                DELETE FROM services WHERE location_id IN (
                    SELECT id FROM locations WHERE business_id = ?
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['services'] = $stmt->rowCount();
            
            // Elimina staff
            $stmt = $pdo->prepare('DELETE FROM staff WHERE business_id = ?');
            $stmt->execute([$businessId]);
            $stats['deleted']['staff'] = $stmt->rowCount();
            
            // Elimina password_reset_token_clients
            $stmt = $pdo->prepare('
                DELETE FROM password_reset_token_clients WHERE client_id IN (
                    SELECT id FROM clients WHERE business_id = ?
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['password_reset_token_clients'] = $stmt->rowCount();
            
            // Elimina client_sessions
            $stmt = $pdo->prepare('
                DELETE FROM client_sessions WHERE client_id IN (
                    SELECT id FROM clients WHERE business_id = ?
                )
            ');
            $stmt->execute([$businessId]);
            $stats['deleted']['client_sessions'] = $stmt->rowCount();
            
            // Elimina clients
            $stmt = $pdo->prepare('DELETE FROM clients WHERE business_id = ?');
            $stmt->execute([$businessId]);
            $stats['deleted']['clients'] = $stmt->rowCount();
            
            // Elimina categories
            $stmt = $pdo->prepare('DELETE FROM categories WHERE business_id = ?');
            $stmt->execute([$businessId]);
            $stats['deleted']['categories'] = $stmt->rowCount();
            
            // Elimina locations
            $stmt = $pdo->prepare('DELETE FROM locations WHERE business_id = ?');
            $stmt->execute([$businessId]);
            $stats['deleted']['locations'] = $stmt->rowCount();
            
            // Elimina business_users
            $stmt = $pdo->prepare('DELETE FROM business_users WHERE business_id = ?');
            $stmt->execute([$businessId]);
            $stats['deleted']['business_users'] = $stmt->rowCount();
            
            // Elimina business
            $stmt = $pdo->prepare('DELETE FROM businesses WHERE id = ?');
            $stmt->execute([$businessId]);
            $stats['deleted']['businesses'] = $stmt->rowCount();
            
            // ===== FASE 2: IMPORTAZIONE DATI =====
            
            // Business
            $this->insertRow($pdo, 'businesses', $exportData['business']);
            $stats['imported']['businesses'] = 1;
            
            // Users (se non esistono già)
            foreach ($exportData['users'] ?? [] as $user) {
                $stmt = $pdo->prepare('SELECT id FROM users WHERE id = ?');
                $stmt->execute([$user['id']]);
                if (!$stmt->fetch()) {
                    // User non esiste, inserisco senza password
                    $user['password_hash'] = null; // Dovrà resettare password
                    $this->insertRow($pdo, 'users', $user);
                }
            }
            $stats['imported']['users'] = count($exportData['users'] ?? []);
            
            // Business Users
            foreach ($exportData['business_users'] ?? [] as $row) {
                $this->insertRow($pdo, 'business_users', $row);
            }
            $stats['imported']['business_users'] = count($exportData['business_users'] ?? []);
            
            // Locations
            foreach ($exportData['locations'] ?? [] as $row) {
                $this->insertRow($pdo, 'locations', $row);
            }
            $stats['imported']['locations'] = count($exportData['locations'] ?? []);
            
            // Categories
            foreach ($exportData['categories'] ?? [] as $row) {
                $this->insertRow($pdo, 'categories', $row);
            }
            $stats['imported']['categories'] = count($exportData['categories'] ?? []);
            
            // Staff
            foreach ($exportData['staff'] ?? [] as $row) {
                $this->insertRow($pdo, 'staff', $row);
            }
            $stats['imported']['staff'] = count($exportData['staff'] ?? []);
            
            // Services
            foreach ($exportData['services'] ?? [] as $row) {
                $this->insertRow($pdo, 'services', $row);
            }
            $stats['imported']['services'] = count($exportData['services'] ?? []);
            
            // Service Variants
            foreach ($exportData['service_variants'] ?? [] as $row) {
                $this->insertRow($pdo, 'service_variants', $row);
            }
            $stats['imported']['service_variants'] = count($exportData['service_variants'] ?? []);
            
            // Staff Services
            foreach ($exportData['staff_services'] ?? [] as $row) {
                $this->insertRow($pdo, 'staff_services', $row);
            }
            $stats['imported']['staff_services'] = count($exportData['staff_services'] ?? []);
            
            // Staff Availability Exceptions
            foreach ($exportData['staff_availability_exceptions'] ?? [] as $row) {
                $this->insertRow($pdo, 'staff_availability_exceptions', $row);
            }
            $stats['imported']['staff_availability_exceptions'] = count($exportData['staff_availability_exceptions'] ?? []);
            
            // Staff Planning
            foreach ($exportData['staff_planning'] ?? [] as $row) {
                $this->insertRow($pdo, 'staff_planning', $row);
            }
            $stats['imported']['staff_planning'] = count($exportData['staff_planning'] ?? []);
            
            // Staff Planning Week Template
            foreach ($exportData['staff_planning_week_template'] ?? [] as $row) {
                $this->insertRow($pdo, 'staff_planning_week_template', $row);
            }
            $stats['imported']['staff_planning_week_template'] = count($exportData['staff_planning_week_template'] ?? []);
            
            // Clients (senza password)
            foreach ($exportData['clients'] ?? [] as $row) {
                $row['password_hash'] = null; // Non importiamo password
                $this->insertRow($pdo, 'clients', $row);
            }
            $stats['imported']['clients'] = count($exportData['clients'] ?? []);
            
            // Resources
            foreach ($exportData['resources'] ?? [] as $row) {
                $this->insertRow($pdo, 'resources', $row);
            }
            $stats['imported']['resources'] = count($exportData['resources'] ?? []);
            
            // Time Blocks
            foreach ($exportData['time_blocks'] ?? [] as $row) {
                $this->insertRow($pdo, 'time_blocks', $row);
            }
            $stats['imported']['time_blocks'] = count($exportData['time_blocks'] ?? []);
            
            // Time Block Staff
            foreach ($exportData['time_block_staff'] ?? [] as $row) {
                $this->insertRow($pdo, 'time_block_staff', $row);
            }
            $stats['imported']['time_block_staff'] = count($exportData['time_block_staff'] ?? []);
            
            // Bookings
            foreach ($exportData['bookings'] ?? [] as $row) {
                $this->insertRow($pdo, 'bookings', $row);
            }
            $stats['imported']['bookings'] = count($exportData['bookings'] ?? []);
            
            // Appointments
            foreach ($exportData['appointments'] ?? [] as $row) {
                $this->insertRow($pdo, 'appointments', $row);
            }
            $stats['imported']['appointments'] = count($exportData['appointments'] ?? []);
            
            // Appointment Services
            foreach ($exportData['appointment_services'] ?? [] as $row) {
                $this->insertRow($pdo, 'appointment_services', $row);
            }
            $stats['imported']['appointment_services'] = count($exportData['appointment_services'] ?? []);
            
            $pdo->exec('SET FOREIGN_KEY_CHECKS = 1');
            $pdo->commit();
            
            return $stats;
            
        } catch (\Exception $e) {
            $pdo->rollBack();
            $pdo->exec('SET FOREIGN_KEY_CHECKS = 1');
            throw $e;
        }
    }
    
    private function insertRow(\PDO $pdo, string $table, array $data): void
    {
        if (empty($data)) {
            return;
        }
        
        $columns = array_keys($data);
        $placeholders = array_map(fn($c) => ":$c", $columns);
        
        $sql = sprintf(
            'INSERT INTO %s (%s) VALUES (%s)',
            $table,
            implode(', ', $columns),
            implode(', ', $placeholders)
        );
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($data);
    }
}
