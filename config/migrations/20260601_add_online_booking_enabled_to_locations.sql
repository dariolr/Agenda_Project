ALTER TABLE locations
    ADD COLUMN online_booking_enabled TINYINT(1) NOT NULL DEFAULT 1
    AFTER is_active;
