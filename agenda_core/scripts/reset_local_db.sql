-- ============================================================
-- Script per svuotare il database locale e resettare auto_increment
-- Mantiene SOLO il superadmin (is_superadmin = 1) nella tabella users
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 1. TRUNCATE tabelle senza dipendenze critiche
-- ============================================================

-- Audit e eventi
TRUNCATE TABLE booking_events;
TRUNCATE TABLE booking_replacements;

-- Notifiche e webhook
TRUNCATE TABLE notification_queue;
TRUNCATE TABLE notification_settings;
TRUNCATE TABLE notification_templates;
TRUNCATE TABLE webhook_deliveries;
TRUNCATE TABLE webhook_endpoints;

-- Booking e appointments
TRUNCATE TABLE booking_items;
TRUNCATE TABLE bookings;

-- Time blocks
TRUNCATE TABLE time_block_staff;
TRUNCATE TABLE time_blocks;

-- Staff related
TRUNCATE TABLE staff_services;
TRUNCATE TABLE staff_planning_week_template;
TRUNCATE TABLE staff_planning;
TRUNCATE TABLE staff_availability_exceptions;
TRUNCATE TABLE staff_locations;
TRUNCATE TABLE staff;

-- Services
TRUNCATE TABLE service_package_items;
TRUNCATE TABLE service_packages;
TRUNCATE TABLE service_variant_resource_requirements;
TRUNCATE TABLE service_variants;
TRUNCATE TABLE services;
TRUNCATE TABLE service_categories;

-- Resources
TRUNCATE TABLE resources;

-- Locations
TRUNCATE TABLE location_schedules;
TRUNCATE TABLE locations;

-- Clients
TRUNCATE TABLE client_sessions;
TRUNCATE TABLE password_reset_token_clients;
TRUNCATE TABLE clients;

-- Business invitations
TRUNCATE TABLE business_invitations;

-- ============================================================
-- 2. DELETE con condizioni (tabelle con dati da preservare)
-- ============================================================

-- Business users (elimina tutti tranne quelli del superadmin)
DELETE FROM business_users WHERE user_id NOT IN (SELECT id FROM users WHERE is_superadmin = 1);

-- Users auth sessions
TRUNCATE TABLE auth_sessions;
TRUNCATE TABLE password_reset_token_users;

-- Users (elimina tutti tranne superadmin)
DELETE FROM users WHERE is_superadmin = 0 OR is_superadmin IS NULL;

-- Businesses (elimina tutti)
DELETE FROM businesses;

-- ============================================================
-- 3. RESET AUTO_INCREMENT per tutte le tabelle
-- ============================================================

ALTER TABLE booking_events AUTO_INCREMENT = 1;
ALTER TABLE booking_replacements AUTO_INCREMENT = 1;
ALTER TABLE notification_queue AUTO_INCREMENT = 1;
ALTER TABLE notification_settings AUTO_INCREMENT = 1;
ALTER TABLE notification_templates AUTO_INCREMENT = 1;
ALTER TABLE webhook_deliveries AUTO_INCREMENT = 1;
ALTER TABLE webhook_endpoints AUTO_INCREMENT = 1;
ALTER TABLE booking_items AUTO_INCREMENT = 1;
ALTER TABLE bookings AUTO_INCREMENT = 1;
ALTER TABLE time_block_staff AUTO_INCREMENT = 1;
ALTER TABLE time_blocks AUTO_INCREMENT = 1;
ALTER TABLE staff_planning_week_template AUTO_INCREMENT = 1;
ALTER TABLE staff_planning AUTO_INCREMENT = 1;
ALTER TABLE staff_availability_exceptions AUTO_INCREMENT = 1;
ALTER TABLE staff AUTO_INCREMENT = 1;
ALTER TABLE service_package_items AUTO_INCREMENT = 1;
ALTER TABLE service_packages AUTO_INCREMENT = 1;
ALTER TABLE service_variants AUTO_INCREMENT = 1;
ALTER TABLE services AUTO_INCREMENT = 1;
ALTER TABLE service_categories AUTO_INCREMENT = 1;
ALTER TABLE resources AUTO_INCREMENT = 1;
ALTER TABLE location_schedules AUTO_INCREMENT = 1;
ALTER TABLE locations AUTO_INCREMENT = 1;
ALTER TABLE client_sessions AUTO_INCREMENT = 1;
ALTER TABLE password_reset_token_clients AUTO_INCREMENT = 1;
ALTER TABLE clients AUTO_INCREMENT = 1;
ALTER TABLE business_users AUTO_INCREMENT = 1;
ALTER TABLE business_invitations AUTO_INCREMENT = 1;
ALTER TABLE auth_sessions AUTO_INCREMENT = 1;
ALTER TABLE password_reset_token_users AUTO_INCREMENT = 1;
ALTER TABLE businesses AUTO_INCREMENT = 1;

-- Users: reset a 2 (1 è il superadmin)
ALTER TABLE users AUTO_INCREMENT = 2;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 4. VERIFICA
-- ============================================================

SELECT '=== VERIFICA RESET ===' AS info;
SELECT 'Superadmin rimasti' AS tabella, COUNT(*) AS records FROM users WHERE is_superadmin = 1;
SELECT 'Users totali' AS tabella, COUNT(*) AS records FROM users;
SELECT 'Businesses' AS tabella, COUNT(*) AS records FROM businesses;
SELECT 'Staff' AS tabella, COUNT(*) AS records FROM staff;
SELECT 'Clients' AS tabella, COUNT(*) AS records FROM clients;
SELECT 'Bookings' AS tabella, COUNT(*) AS records FROM bookings;
