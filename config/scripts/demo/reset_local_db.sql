-- Reset mutable demo data (safe only on dedicated demo DB)
-- Used by config/scripts/demo/reset_demo_core.sh

SET FOREIGN_KEY_CHECKS = 0;

-- Payments
TRUNCATE TABLE booking_payment_lines;
TRUNCATE TABLE booking_payments;

-- Booking domain
TRUNCATE TABLE booking_events;
TRUNCATE TABLE booking_replacements;
TRUNCATE TABLE booking_items;
TRUNCATE TABLE bookings;
TRUNCATE TABLE booking_recurrence_rules;

-- Classes
TRUNCATE TABLE class_bookings;
TRUNCATE TABLE class_event_resource_requirements;
TRUNCATE TABLE class_events;
TRUNCATE TABLE class_type_locations;
TRUNCATE TABLE class_types;

-- Availability / closures
TRUNCATE TABLE time_block_staff;
TRUNCATE TABLE time_blocks;
TRUNCATE TABLE closure_locations;
TRUNCATE TABLE closures;
TRUNCATE TABLE staff_availability_exceptions;

-- Staff planning and links
TRUNCATE TABLE staff_planning_week_template;
TRUNCATE TABLE staff_planning;
TRUNCATE TABLE staff_services;
TRUNCATE TABLE staff_locations;
TRUNCATE TABLE popular_services;
TRUNCATE TABLE staff;

-- Services catalog
TRUNCATE TABLE service_variant_resource_requirements;
TRUNCATE TABLE service_variants;
TRUNCATE TABLE service_package_items;
TRUNCATE TABLE service_packages;
TRUNCATE TABLE services;
TRUNCATE TABLE service_categories;
TRUNCATE TABLE resources;

-- Clients and sessions
TRUNCATE TABLE password_reset_token_clients;
TRUNCATE TABLE client_sessions;
TRUNCATE TABLE clients;

-- Notifications and webhooks
TRUNCATE TABLE notification_queue;
TRUNCATE TABLE notification_templates;
TRUNCATE TABLE notification_settings;
TRUNCATE TABLE webhook_deliveries;
TRUNCATE TABLE webhook_endpoints;

-- Business/account scope
TRUNCATE TABLE business_invitation_locations;
TRUNCATE TABLE business_invitations;
TRUNCATE TABLE business_user_locations;
TRUNCATE TABLE business_users;
TRUNCATE TABLE business_application_settings;
TRUNCATE TABLE location_schedules;
TRUNCATE TABLE locations;
TRUNCATE TABLE businesses;

-- User auth
TRUNCATE TABLE password_reset_token_users;
TRUNCATE TABLE auth_sessions;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1;
