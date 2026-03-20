#!/usr/bin/env bash
set -euo pipefail

# MONOLITHIC DEMO RESET SCRIPT
# Single file: includes reset SQL + seed SQL internally.
# Required env vars (set in cron or shell):
#   DB_DATABASE, DB_USERNAME
# Optional env vars:
#   DB_HOST (default: localhost), DB_PORT (default: 3306), DB_PASSWORD (default: empty)

APP_ENV="demo"

if ! command -v mysql >/dev/null 2>&1; then
  echo "ERROR: mysql client not found"
  exit 1
fi

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_DATABASE="${DB_DATABASE:-}"
DB_USERNAME="${DB_USERNAME:-}"
DB_PASSWORD="${DB_PASSWORD:-}"

if [[ -z "$DB_DATABASE" || -z "$DB_USERNAME" ]]; then
  echo "ERROR: DB_DATABASE and DB_USERNAME are required"
  exit 1
fi

MYSQL_CMD=(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME")
if [[ -n "$DB_PASSWORD" ]]; then
  MYSQL_CMD+=("-p$DB_PASSWORD")
fi

echo "[demo-cron] reset start: $(date '+%Y-%m-%d %H:%M:%S')"
"${MYSQL_CMD[@]}" "$DB_DATABASE" <<'SQL_RESET'
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
SQL_RESET

echo "[demo-cron] seed start"
"${MYSQL_CMD[@]}" "$DB_DATABASE" <<'SQL_SEED'
-- Demo seed dataset for agenda_core / agenda_backend
-- Safe to re-run: uses deterministic IDs + ON DUPLICATE KEY UPDATE.

SET NAMES utf8mb4;
SET time_zone = '+00:00';

START TRANSACTION;

-- ---------------------------------------------------------------------------
-- Core identity / tenant
-- ---------------------------------------------------------------------------

INSERT INTO users (
  id, email, password_hash, first_name, last_name, phone, email_verified_at, is_active, is_superadmin
) VALUES (
  900001,
  'admin@beauty-demo.example',
  '$2y$10$NZSINGbiLXd71WfI8y4k.udyW42ybwsVLaBL96zIa4pkp9wAutzBa',
  'Demo',
  'Admin',
  '+390200000001',
  UTC_TIMESTAMP(),
  1,
  0
)
ON DUPLICATE KEY UPDATE
  email = VALUES(email),
  password_hash = VALUES(password_hash),
  first_name = VALUES(first_name),
  last_name = VALUES(last_name),
  phone = VALUES(phone),
  email_verified_at = VALUES(email_verified_at),
  is_active = VALUES(is_active),
  is_superadmin = VALUES(is_superadmin);

INSERT INTO businesses (
  id, name, slug, email, phone, online_bookings_notification_email,
  service_color_palette, primary_color, timezone, currency,
  cancellation_hours, show_appointment_price_in_card, is_active, is_suspended, suspension_message
) VALUES (
  900001,
  'Luxe Beauty Studio',
  'luxe-beauty-studio',
  'hello@beauty-demo.example',
  '+390200000000',
  'hello@beauty-demo.example',
  'legacy',
  '#1E88E5',
  'Europe/Rome',
  'EUR',
  24,
  1,
  1,
  0,
  NULL
)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  slug = VALUES(slug),
  email = VALUES(email),
  phone = VALUES(phone),
  online_bookings_notification_email = VALUES(online_bookings_notification_email),
  service_color_palette = VALUES(service_color_palette),
  primary_color = VALUES(primary_color),
  timezone = VALUES(timezone),
  currency = VALUES(currency),
  cancellation_hours = VALUES(cancellation_hours),
  show_appointment_price_in_card = VALUES(show_appointment_price_in_card),
  is_active = VALUES(is_active),
  is_suspended = VALUES(is_suspended),
  suspension_message = VALUES(suspension_message);

INSERT INTO business_users (
  id, business_id, user_id, role, scope_type, staff_id,
  can_manage_bookings, can_manage_clients, can_manage_services, can_manage_staff, can_view_reports,
  is_active, invited_by, invited_at, accepted_at
) VALUES (
  900001,
  900001,
  900001,
  'owner',
  'business',
  NULL,
  1, 1, 1, 1, 1,
  1,
  NULL,
  UTC_TIMESTAMP(),
  UTC_TIMESTAMP()
)
ON DUPLICATE KEY UPDATE
  business_id = VALUES(business_id),
  user_id = VALUES(user_id),
  role = VALUES(role),
  scope_type = VALUES(scope_type),
  staff_id = VALUES(staff_id),
  can_manage_bookings = VALUES(can_manage_bookings),
  can_manage_clients = VALUES(can_manage_clients),
  can_manage_services = VALUES(can_manage_services),
  can_manage_staff = VALUES(can_manage_staff),
  can_view_reports = VALUES(can_view_reports),
  is_active = VALUES(is_active),
  invited_by = VALUES(invited_by),
  invited_at = VALUES(invited_at),
  accepted_at = VALUES(accepted_at);

-- ---------------------------------------------------------------------------
-- Locations + schedules
-- ---------------------------------------------------------------------------

INSERT INTO locations (
  id, business_id, name, address, city, postal_code, region, country,
  phone, email, latitude, longitude,
  timezone, currency, cancellation_hours,
  min_booking_notice_hours, max_booking_advance_days,
  allow_customer_choose_staff, is_default, sort_order, is_active,
  online_booking_slot_interval_minutes, slot_display_mode, min_gap_minutes
) VALUES (
  900001,
  900001,
  'Sede Demo Roma',
  'Via del Corso 101',
  'Roma',
  '00186',
  'Lazio',
  'IT',
  '+390200000010',
  'roma@beauty-demo.example',
  41.90278200,
  12.49636600,
  'Europe/Rome',
  'EUR',
  24,
  1,
  90,
  1,
  1,
  0,
  1,
  15,
  'all',
  30
)
ON DUPLICATE KEY UPDATE
  business_id = VALUES(business_id),
  name = VALUES(name),
  address = VALUES(address),
  city = VALUES(city),
  postal_code = VALUES(postal_code),
  region = VALUES(region),
  country = VALUES(country),
  phone = VALUES(phone),
  email = VALUES(email),
  latitude = VALUES(latitude),
  longitude = VALUES(longitude),
  timezone = VALUES(timezone),
  currency = VALUES(currency),
  cancellation_hours = VALUES(cancellation_hours),
  min_booking_notice_hours = VALUES(min_booking_notice_hours),
  max_booking_advance_days = VALUES(max_booking_advance_days),
  allow_customer_choose_staff = VALUES(allow_customer_choose_staff),
  is_default = VALUES(is_default),
  sort_order = VALUES(sort_order),
  is_active = VALUES(is_active),
  online_booking_slot_interval_minutes = VALUES(online_booking_slot_interval_minutes),
  slot_display_mode = VALUES(slot_display_mode),
  min_gap_minutes = VALUES(min_gap_minutes);

INSERT INTO business_user_locations (id, business_user_id, location_id)
VALUES (900001, 900001, 900001)
ON DUPLICATE KEY UPDATE
  business_user_id = VALUES(business_user_id),
  location_id = VALUES(location_id);

INSERT INTO location_schedules (id, location_id, day_of_week, open_time, close_time, is_closed)
VALUES
  (900100, 900001, 0, '00:00:00', '00:00:00', 1),
  (900101, 900001, 1, '09:00:00', '19:00:00', 0),
  (900102, 900001, 2, '09:00:00', '19:00:00', 0),
  (900103, 900001, 3, '09:00:00', '19:00:00', 0),
  (900104, 900001, 4, '09:00:00', '19:00:00', 0),
  (900105, 900001, 5, '09:00:00', '19:00:00', 0),
  (900106, 900001, 6, '09:00:00', '14:00:00', 0)
ON DUPLICATE KEY UPDATE
  location_id = VALUES(location_id),
  day_of_week = VALUES(day_of_week),
  open_time = VALUES(open_time),
  close_time = VALUES(close_time),
  is_closed = VALUES(is_closed);

-- ---------------------------------------------------------------------------
-- Staff + planning
-- ---------------------------------------------------------------------------

INSERT INTO staff (
  id, business_id, name, surname, color_hex, avatar_url, sort_order,
  is_default, is_bookable_online, is_active
) VALUES
  (900001, 900001, 'Marco', 'Rossi', '#FF6B35', NULL, 1, 1, 1, 1),
  (900002, 900001, 'Giulia', 'Bianchi', '#2A9D8F', NULL, 2, 0, 1, 1)
ON DUPLICATE KEY UPDATE
  business_id = VALUES(business_id),
  name = VALUES(name),
  surname = VALUES(surname),
  color_hex = VALUES(color_hex),
  avatar_url = VALUES(avatar_url),
  sort_order = VALUES(sort_order),
  is_default = VALUES(is_default),
  is_bookable_online = VALUES(is_bookable_online),
  is_active = VALUES(is_active);

INSERT INTO staff_locations (staff_id, location_id)
VALUES
  (900001, 900001),
  (900002, 900001)
ON DUPLICATE KEY UPDATE
  location_id = VALUES(location_id);

INSERT INTO staff_planning (id, staff_id, type, valid_from, valid_to)
VALUES
  (900001, 900001, 'weekly', '2026-01-01', NULL),
  (900002, 900002, 'weekly', '2026-01-01', NULL)
ON DUPLICATE KEY UPDATE
  staff_id = VALUES(staff_id),
  type = VALUES(type),
  valid_from = VALUES(valid_from),
  valid_to = VALUES(valid_to);

-- Slots are 15-minute indexes in the day (0..95)
-- 09:00-13:00 => 36..51
-- 14:00-18:00 => 56..71
INSERT INTO staff_planning_week_template (id, staff_planning_id, week_label, day_of_week, slots)
VALUES
  (900100, 900001, 'A', 1, JSON_ARRAY(36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71)),
  (900101, 900001, 'A', 2, JSON_ARRAY(36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71)),
  (900102, 900001, 'A', 3, JSON_ARRAY(36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71)),
  (900103, 900001, 'A', 4, JSON_ARRAY(36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71)),
  (900104, 900001, 'A', 5, JSON_ARRAY(36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71)),
  (900105, 900001, 'A', 6, JSON_ARRAY(36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51)),
  (900110, 900002, 'A', 1, JSON_ARRAY(40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67)),
  (900111, 900002, 'A', 2, JSON_ARRAY(40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67)),
  (900112, 900002, 'A', 3, JSON_ARRAY(40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67)),
  (900113, 900002, 'A', 4, JSON_ARRAY(40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67)),
  (900114, 900002, 'A', 5, JSON_ARRAY(40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67))
ON DUPLICATE KEY UPDATE
  staff_planning_id = VALUES(staff_planning_id),
  week_label = VALUES(week_label),
  day_of_week = VALUES(day_of_week),
  slots = VALUES(slots);

-- ---------------------------------------------------------------------------
-- Services catalog
-- ---------------------------------------------------------------------------

INSERT INTO service_categories (id, business_id, name, description, sort_order)
VALUES
  (900001, 900001, 'Capelli', 'Servizi capelli demo', 1),
  (900002, 900001, 'Barba', 'Servizi barba demo', 2)
ON DUPLICATE KEY UPDATE
  business_id = VALUES(business_id),
  name = VALUES(name),
  description = VALUES(description),
  sort_order = VALUES(sort_order);

INSERT INTO services (id, business_id, category_id, name, description, sort_order, is_active)
VALUES
  (900001, 900001, 900001, 'Taglio Uomo', 'Taglio classico', 1, 1),
  (900002, 900001, 900001, 'Taglio Donna', 'Taglio + piega', 2, 1),
  (900003, 900001, 900002, 'Regolazione Barba', 'Barba completa', 1, 1)
ON DUPLICATE KEY UPDATE
  business_id = VALUES(business_id),
  category_id = VALUES(category_id),
  name = VALUES(name),
  description = VALUES(description),
  sort_order = VALUES(sort_order),
  is_active = VALUES(is_active);

INSERT INTO service_variants (
  id, service_id, location_id, duration_minutes, processing_time, blocked_time,
  price, currency, color_hex, is_bookable_online, is_free, is_price_starting_from, is_active
) VALUES
  (900001, 900001, 900001, 30, 0, 0, 25.00, 'EUR', '#F4A261', 1, 0, 0, 1),
  (900002, 900002, 900001, 60, 0, 0, 45.00, 'EUR', '#E76F51', 1, 0, 0, 1),
  (900003, 900003, 900001, 30, 0, 0, 20.00, 'EUR', '#264653', 1, 0, 0, 1)
ON DUPLICATE KEY UPDATE
  service_id = VALUES(service_id),
  location_id = VALUES(location_id),
  duration_minutes = VALUES(duration_minutes),
  processing_time = VALUES(processing_time),
  blocked_time = VALUES(blocked_time),
  price = VALUES(price),
  currency = VALUES(currency),
  color_hex = VALUES(color_hex),
  is_bookable_online = VALUES(is_bookable_online),
  is_free = VALUES(is_free),
  is_price_starting_from = VALUES(is_price_starting_from),
  is_active = VALUES(is_active);

INSERT INTO staff_services (staff_id, service_id)
VALUES
  (900001, 900001),
  (900001, 900002),
  (900001, 900003),
  (900002, 900001),
  (900002, 900003)
ON DUPLICATE KEY UPDATE
  service_id = VALUES(service_id);

-- ---------------------------------------------------------------------------
-- Clients
-- ---------------------------------------------------------------------------

INSERT INTO clients (
  id, business_id, user_id, password_hash, email_verified_at,
  first_name, last_name, email, phone, gender, birth_date, city, notes,
  loyalty_points, last_visit, is_archived, blocked
) VALUES
  (900001, 900001, NULL, NULL, NULL, 'Luca', 'Verdi', 'luca.verdi@example.com', '+393331111111', 'male', '1990-05-12', 'Milano', 'Cliente abituale', 120, UTC_TIMESTAMP(), 0, 0),
  (900002, 900001, NULL, NULL, NULL, 'Sara', 'Neri', 'sara.neri@example.com', '+393332222222', 'female', '1988-09-03', 'Milano', NULL, 45, UTC_TIMESTAMP(), 0, 0),
  (900003, 900001, NULL, NULL, NULL, 'Paolo', 'Gialli', 'paolo.gialli@example.com', '+393333333333', 'male', '1995-02-20', 'Monza', NULL, 0, NULL, 0, 0),
  (900004, 900001, NULL, NULL, NULL, 'Elena', 'Blu', 'elena.blu@example.com', '+393334444444', 'female', '1992-11-30', 'Bergamo', NULL, 0, NULL, 0, 0)
ON DUPLICATE KEY UPDATE
  business_id = VALUES(business_id),
  user_id = VALUES(user_id),
  password_hash = VALUES(password_hash),
  email_verified_at = VALUES(email_verified_at),
  first_name = VALUES(first_name),
  last_name = VALUES(last_name),
  email = VALUES(email),
  phone = VALUES(phone),
  gender = VALUES(gender),
  birth_date = VALUES(birth_date),
  city = VALUES(city),
  notes = VALUES(notes),
  loyalty_points = VALUES(loyalty_points),
  last_visit = VALUES(last_visit),
  is_archived = VALUES(is_archived),
  blocked = VALUES(blocked);

-- ---------------------------------------------------------------------------
-- Bookings + booking items
-- Dynamic dates: relative to execution day (UTC) to keep demo always fresh.
-- ---------------------------------------------------------------------------

INSERT INTO bookings (
  id, business_id, location_id, client_id, user_id, client_name, notes,
  status, recurrence_rule_id, recurrence_index, is_recurrence_parent, has_conflict,
  source, idempotency_key, idempotency_expires_at, replaces_booking_id, replaced_by_booking_id
) VALUES
  (900001, 900001, 900001, 900001, NULL, NULL, 'Prenotazione demo confermata', 'confirmed', NULL, NULL, 0, 0, 'manual', NULL, NULL, NULL, NULL),
  (900002, 900001, 900001, 900002, NULL, NULL, 'Prenotazione demo completata', 'completed', NULL, NULL, 0, 0, 'manual', NULL, NULL, NULL, NULL),
  (900003, 900001, 900001, 900003, NULL, NULL, 'Prenotazione demo pending', 'pending', NULL, NULL, 0, 0, 'online', NULL, NULL, NULL, NULL),
  (900004, 900001, 900001, 900004, NULL, NULL, 'Prenotazione demo cancellata', 'cancelled', NULL, NULL, 0, 0, 'manual', NULL, NULL, NULL, NULL),
  (900005, 900001, 900001, 900001, NULL, NULL, 'Prenotazione no-show', 'no_show', NULL, NULL, 0, 0, 'manual', NULL, NULL, NULL, NULL),
  (900006, 900001, 900001, 900002, NULL, NULL, 'Prenotazione multi-servizio', 'confirmed', NULL, NULL, 0, 0, 'manual', NULL, NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE
  business_id = VALUES(business_id),
  location_id = VALUES(location_id),
  client_id = VALUES(client_id),
  user_id = VALUES(user_id),
  client_name = VALUES(client_name),
  notes = VALUES(notes),
  status = VALUES(status),
  recurrence_rule_id = VALUES(recurrence_rule_id),
  recurrence_index = VALUES(recurrence_index),
  is_recurrence_parent = VALUES(is_recurrence_parent),
  has_conflict = VALUES(has_conflict),
  source = VALUES(source),
  idempotency_key = VALUES(idempotency_key),
  idempotency_expires_at = VALUES(idempotency_expires_at),
  replaces_booking_id = VALUES(replaces_booking_id),
  replaced_by_booking_id = VALUES(replaced_by_booking_id);

INSERT INTO booking_items (
  id, booking_id, location_id, service_id, service_variant_id, staff_id,
  start_time, end_time, price, extra_blocked_minutes, extra_processing_minutes,
  service_name_snapshot, client_name_snapshot
) VALUES
  (
    900001, 900001, 900001, 900001, 900001, 900001,
    TIMESTAMP(DATE_ADD(UTC_DATE(), INTERVAL 1 DAY), '08:00:00'),
    TIMESTAMP(DATE_ADD(UTC_DATE(), INTERVAL 1 DAY), '08:30:00'),
    25.00, 0, 0, 'Taglio Uomo', 'Luca Verdi'
  ),
  (
    900002, 900002, 900001, 900002, 900002, 900001,
    TIMESTAMP(DATE_SUB(UTC_DATE(), INTERVAL 1 DAY), '12:00:00'),
    TIMESTAMP(DATE_SUB(UTC_DATE(), INTERVAL 1 DAY), '13:00:00'),
    45.00, 0, 0, 'Taglio Donna', 'Sara Neri'
  ),
  (
    900003, 900003, 900001, 900003, 900003, 900002,
    TIMESTAMP(DATE_ADD(UTC_DATE(), INTERVAL 2 DAY), '09:30:00'),
    TIMESTAMP(DATE_ADD(UTC_DATE(), INTERVAL 2 DAY), '10:00:00'),
    20.00, 0, 0, 'Regolazione Barba', 'Paolo Gialli'
  ),
  (
    900004, 900004, 900001, 900001, 900001, 900001,
    TIMESTAMP(DATE_SUB(UTC_DATE(), INTERVAL 2 DAY), '15:00:00'),
    TIMESTAMP(DATE_SUB(UTC_DATE(), INTERVAL 2 DAY), '15:30:00'),
    25.00, 0, 0, 'Taglio Uomo', 'Elena Blu'
  ),
  (
    900005, 900005, 900001, 900003, 900003, 900002,
    TIMESTAMP(DATE_SUB(UTC_DATE(), INTERVAL 3 DAY), '10:30:00'),
    TIMESTAMP(DATE_SUB(UTC_DATE(), INTERVAL 3 DAY), '11:00:00'),
    20.00, 0, 0, 'Regolazione Barba', 'Luca Verdi'
  ),
  (
    900006, 900006, 900001, 900001, 900001, 900001,
    TIMESTAMP(DATE_ADD(UTC_DATE(), INTERVAL 3 DAY), '08:00:00'),
    TIMESTAMP(DATE_ADD(UTC_DATE(), INTERVAL 3 DAY), '08:30:00'),
    25.00, 0, 0, 'Taglio Uomo', 'Sara Neri'
  ),
  (
    900007, 900006, 900001, 900003, 900003, 900001,
    TIMESTAMP(DATE_ADD(UTC_DATE(), INTERVAL 3 DAY), '08:30:00'),
    TIMESTAMP(DATE_ADD(UTC_DATE(), INTERVAL 3 DAY), '09:00:00'),
    20.00, 0, 0, 'Regolazione Barba', 'Sara Neri'
  )
ON DUPLICATE KEY UPDATE
  booking_id = VALUES(booking_id),
  location_id = VALUES(location_id),
  service_id = VALUES(service_id),
  service_variant_id = VALUES(service_variant_id),
  staff_id = VALUES(staff_id),
  start_time = VALUES(start_time),
  end_time = VALUES(end_time),
  price = VALUES(price),
  extra_blocked_minutes = VALUES(extra_blocked_minutes),
  extra_processing_minutes = VALUES(extra_processing_minutes),
  service_name_snapshot = VALUES(service_name_snapshot),
  client_name_snapshot = VALUES(client_name_snapshot);

INSERT INTO notification_settings (
  id, business_id, email_enabled, email_booking_confirmed, email_booking_cancelled,
  email_booking_rescheduled, email_reminder_enabled, email_reminder_hours,
  sms_enabled, sms_reminder_enabled, sms_reminder_hours, sender_name, reply_to_email
) VALUES (
  900001, 900001, 1, 1, 1,
  1, 1, 24,
  0, 0, 24, 'Luxe Beauty Studio', 'hello@beauty-demo.example'
)
ON DUPLICATE KEY UPDATE
  business_id = VALUES(business_id),
  email_enabled = VALUES(email_enabled),
  email_booking_confirmed = VALUES(email_booking_confirmed),
  email_booking_cancelled = VALUES(email_booking_cancelled),
  email_booking_rescheduled = VALUES(email_booking_rescheduled),
  email_reminder_enabled = VALUES(email_reminder_enabled),
  email_reminder_hours = VALUES(email_reminder_hours),
  sms_enabled = VALUES(sms_enabled),
  sms_reminder_enabled = VALUES(sms_reminder_enabled),
  sms_reminder_hours = VALUES(sms_reminder_hours),
  sender_name = VALUES(sender_name),
  reply_to_email = VALUES(reply_to_email);

COMMIT;
SQL_SEED

echo "[demo-cron] done: $(date '+%Y-%m-%d %H:%M:%S')"
