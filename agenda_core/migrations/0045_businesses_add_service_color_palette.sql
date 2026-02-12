-- 0045_businesses_add_service_color_palette.sql
-- Add business-level setting to choose which service color palette is used in agenda_backend.
-- Allowed values:
--   - enhanced: slightly darker palette
--   - legacy (default): original palette

ALTER TABLE businesses
  ADD COLUMN service_color_palette VARCHAR(16) NOT NULL DEFAULT 'legacy'
  AFTER online_bookings_notification_email;
