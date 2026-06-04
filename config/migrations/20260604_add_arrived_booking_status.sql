-- Add 'arrived' status to bookings table
-- This status represents a client who has arrived at the salon,
-- intermediate between 'confirmed' and 'completed'.

ALTER TABLE bookings
  MODIFY COLUMN `status` ENUM('pending','confirmed','arrived','completed','cancelled','no_show','replaced')
  COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'confirmed';
