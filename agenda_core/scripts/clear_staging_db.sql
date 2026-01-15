-- Script per svuotare il database staging mantenendo solo il superadmin
SET FOREIGN_KEY_CHECKS = 0;

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
TRUNCATE TABLE staff_schedules;
TRUNCATE TABLE staff_locations;
TRUNCATE TABLE staff;

-- Services
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

-- Business users e invitations
DELETE FROM business_users WHERE user_id NOT IN (SELECT id FROM users WHERE is_superadmin = 1);
TRUNCATE TABLE business_invitations;

-- Users auth
TRUNCATE TABLE auth_sessions;
TRUNCATE TABLE password_reset_token_users;
DELETE FROM users WHERE is_superadmin = 0 OR is_superadmin IS NULL;

-- Businesses
DELETE FROM businesses;

SET FOREIGN_KEY_CHECKS = 1;

-- Verifica
SELECT 'Users rimasti' AS info, COUNT(*) AS count FROM users;
SELECT 'Businesses rimasti' AS info, COUNT(*) AS count FROM businesses;
