-- 0044_businesses_add_online_bookings_notification_email.sql
-- Add optional notification email for online bookings created/modified/cancelled by customers.

ALTER TABLE businesses
  ADD COLUMN online_bookings_notification_email VARCHAR(255) NULL AFTER phone;

