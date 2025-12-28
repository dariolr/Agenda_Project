-- Seed data for development/testing
-- Run after migrations: 0001-0007
--
-- ⚠️ PASSWORD UTENTI TEST: 'Password123!'
--    Hash generato con: password_hash('Password123!', PASSWORD_BCRYPT)
--    Se il login fallisce, rigenerare hash con PHP CLI:
--    php -r "echo password_hash('Password123!', PASSWORD_BCRYPT) . PHP_EOL;"
--
-- ============================================================================
-- BUSINESSES & LOCATIONS
-- ============================================================================

INSERT INTO businesses (id, name, slug, timezone, currency) VALUES
(1, 'Salone Bella Vita', 'salone-bella-vita', 'Europe/Rome', 'EUR');

INSERT INTO locations (id, business_id, name, address, city, phone, timezone, is_default) VALUES
(1, 1, 'Sede Centrale', 'Via Roma 123', 'Roma', '+39 06 1234567', 'Europe/Rome', 1);

-- ============================================================================
-- USERS (Global - no business_id)
-- ============================================================================
-- Password: 'Password123!' (bcrypt hash)
-- NOTA: Se hash non funziona, rigenerare con: php -r "echo password_hash('Password123!', PASSWORD_BCRYPT);"

INSERT INTO users (id, email, password_hash, first_name, last_name, phone) VALUES
(1, 'mario.rossi@example.com', '$2y$10$usU6FbYviY2LjAM9pqkaI.HdgqWW7iQkqoIl.u4Zu7k7XNMOhYacG', 'Mario', 'Rossi', '+39 333 1234567'),
(2, 'anna.bianchi@example.com', '$2y$10$usU6FbYviY2LjAM9pqkaI.HdgqWW7iQkqoIl.u4Zu7k7XNMOhYacG', 'Anna', 'Bianchi', '+39 333 7654321');

-- ============================================================================
-- STAFF
-- ============================================================================

INSERT INTO staff (id, business_id, name, surname, color_hex, is_bookable_online) VALUES
(1, 1, 'Anna', 'Bianchi', '#FF6B6B', 1),
(2, 1, 'Luca', 'Verdi', '#4ECDC4', 1),
(3, 1, 'Sara', 'Marino', '#45B7D1', 1);

-- Staff-Location assignments
INSERT INTO staff_locations (staff_id, location_id) VALUES
(1, 1),
(2, 1),
(3, 1);

-- ============================================================================
-- SERVICE CATEGORIES & SERVICES
-- ============================================================================

INSERT INTO service_categories (id, business_id, name, sort_order) VALUES
(1, 1, 'Taglio', 1),
(2, 1, 'Colore', 2),
(3, 1, 'Trattamenti', 3);

-- Services (without duration/price - those go in service_variants)
INSERT INTO services (id, business_id, category_id, name, description, sort_order) VALUES
(1, 1, 1, 'Taglio Uomo', 'Taglio classico maschile', 1),
(2, 1, 1, 'Taglio Donna', 'Taglio e piega donna', 2),
(3, 1, 1, 'Taglio Bambino', 'Taglio per bambini fino a 12 anni', 3),
(4, 1, 2, 'Colore Base', 'Colorazione mono-tono', 1),
(5, 1, 2, 'Meches', 'Schiariture e meches', 2),
(6, 1, 2, 'Balayage', 'Tecnica balayage', 3),
(7, 1, 3, 'Piega', 'Solo piega', 1),
(8, 1, 3, 'Trattamento Cheratina', 'Lisciatura alla cheratina', 2),
(9, 1, 3, 'Maschera Nutriente', 'Trattamento nutriente intensivo', 3);

-- Service variants (duration + price per location)
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, color_hex) VALUES
(1, 1, 30, 20.00, '#FF6B6B'),
(2, 1, 45, 35.00, '#FF6B6B'),
(3, 1, 20, 15.00, '#FF6B6B'),
(4, 1, 60, 45.00, '#4ECDC4'),
(5, 1, 90, 65.00, '#4ECDC4'),
(6, 1, 120, 85.00, '#4ECDC4'),
(7, 1, 30, 18.00, '#45B7D1'),
(8, 1, 90, 80.00, '#45B7D1'),
(9, 1, 20, 15.00, '#45B7D1');

-- ============================================================================
-- CLIENTS (per-business, linked to user)
-- ============================================================================

INSERT INTO clients (id, business_id, user_id, first_name, last_name, email, phone) VALUES
(1, 1, 1, 'Mario', 'Rossi', 'mario.rossi@example.com', '+39 333 1234567');

-- ============================================================================
-- LOCATION SCHEDULES (working hours)
-- ============================================================================
-- Monday-Friday 09:00-18:00, Saturday 09:00-13:00, Sunday closed

INSERT INTO location_schedules (location_id, day_of_week, open_time, close_time, is_closed) VALUES
(1, 1, '09:00:00', '18:00:00', 0),  -- Monday
(1, 2, '09:00:00', '18:00:00', 0),  -- Tuesday
(1, 3, '09:00:00', '18:00:00', 0),  -- Wednesday
(1, 4, '09:00:00', '18:00:00', 0),  -- Thursday
(1, 5, '09:00:00', '18:00:00', 0),  -- Friday
(1, 6, '09:00:00', '13:00:00', 0),  -- Saturday
(1, 0, '09:00:00', '18:00:00', 1);  -- Sunday (closed)

-- ============================================================================
-- STAFF SERVICES (restrictions - empty = all services allowed)
-- ============================================================================
-- Example: If you want to restrict staff to specific services, uncomment:
-- INSERT INTO staff_services (staff_id, service_id) VALUES
-- (1, 1),  -- Anna can do service 1
-- (1, 2),  -- Anna can do service 2
-- (2, 3);  -- Luca can do service 3
-- 
-- By default (no records), all staff can perform all services.
