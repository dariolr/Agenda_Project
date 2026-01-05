-- ============================================================================
-- Migration: 0023_location_booking_limits.sql
-- Description: Add booking time limits to locations table
-- Date: 2026-01-05
-- ============================================================================

-- Add minimum notice hours for online booking (how many hours before the appointment)
-- Default: 1 hour (customers must book at least 1 hour before)
ALTER TABLE locations ADD COLUMN min_booking_notice_hours INT UNSIGNED NOT NULL DEFAULT 1
    COMMENT 'Minimum hours before appointment for online booking. Default 1 hour.'
    AFTER cancellation_hours;

-- Add maximum advance days for online booking (how far ahead customers can book)
-- Default: 90 days (customers can book up to 3 months ahead)
ALTER TABLE locations ADD COLUMN max_booking_advance_days INT UNSIGNED NOT NULL DEFAULT 90
    COMMENT 'Maximum days in advance for online booking. Default 90 days (3 months).'
    AFTER min_booking_notice_hours;

-- Add index for these fields (useful when filtering available dates)
ALTER TABLE locations ADD INDEX idx_locations_booking_limits (business_id, min_booking_notice_hours, max_booking_advance_days);
