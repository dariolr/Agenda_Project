-- =============================================================================
-- Migration: Aggiorna location_id da 4 a 1 in tutte le tabelle
-- Data: 23/01/2026
-- Descrizione: Cambia tutti i riferimenti alla location 4 in location 1
-- =============================================================================

-- Disabilita i check delle foreign key durante l'update
SET FOREIGN_KEY_CHECKS = 0;

-- booking_items
UPDATE booking_items SET location_id = 1 WHERE location_id = 4;

-- bookings
UPDATE bookings SET location_id = 1 WHERE location_id = 4;

-- location_schedules
UPDATE location_schedules SET location_id = 1 WHERE location_id = 4;

-- resources
UPDATE resources SET location_id = 1 WHERE location_id = 4;

-- service_packages
UPDATE service_packages SET location_id = 1 WHERE location_id = 4;

-- service_variants
UPDATE service_variants SET location_id = 1 WHERE location_id = 4;

-- staff_locations
UPDATE staff_locations SET location_id = 1 WHERE location_id = 4;

-- time_blocks
UPDATE time_blocks SET location_id = 1 WHERE location_id = 4;

-- Riabilita i check delle foreign key
SET FOREIGN_KEY_CHECKS = 1;

-- Verifica risultati
SELECT 'booking_items' AS tabella, COUNT(*) AS righe_con_location_4 FROM booking_items WHERE location_id = 4
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings WHERE location_id = 4
UNION ALL
SELECT 'location_schedules', COUNT(*) FROM location_schedules WHERE location_id = 4
UNION ALL
SELECT 'resources', COUNT(*) FROM resources WHERE location_id = 4
UNION ALL
SELECT 'service_packages', COUNT(*) FROM service_packages WHERE location_id = 4
UNION ALL
SELECT 'service_variants', COUNT(*) FROM service_variants WHERE location_id = 4
UNION ALL
SELECT 'staff_locations', COUNT(*) FROM staff_locations WHERE location_id = 4
UNION ALL
SELECT 'time_blocks', COUNT(*) FROM time_blocks WHERE location_id = 4;
