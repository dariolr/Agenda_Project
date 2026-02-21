-- Rename location slot proposal interval column to a clearer name.
-- It controls online booking slot cadence, not staff planning granularity.

ALTER TABLE locations
  CHANGE COLUMN slot_interval_minutes online_booking_slot_interval_minutes INT UNSIGNED NOT NULL DEFAULT 15;
