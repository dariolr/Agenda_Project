-- Add allow_customer_choose_staff flag to locations
ALTER TABLE locations
  ADD COLUMN allow_customer_choose_staff TINYINT(1) NOT NULL DEFAULT 0
  AFTER max_booking_advance_days;
