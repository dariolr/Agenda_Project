-- ============================================================================
-- MIGRATION 0025: Booking Replace Flow
-- Description: Add support for booking modification via replace pattern
-- Date: 2026-01-XX
-- 
-- Changes:
-- 1. Add 'replaced' to bookings.status enum
-- 2. Add replaces_booking_id and replaced_by_booking_id columns
-- 3. Create booking_replacements table for audit/relationships
-- 4. Create booking_events table for immutable audit trail
-- ============================================================================

-- ----------------------------------------------------------------------------
-- A2. Extend bookings.status enum to include 'replaced'
-- ----------------------------------------------------------------------------
ALTER TABLE bookings 
  MODIFY COLUMN status ENUM('pending', 'confirmed', 'completed', 'cancelled', 'no_show', 'replaced') 
  NOT NULL DEFAULT 'confirmed';

-- ----------------------------------------------------------------------------
-- A2. Add relationship columns for replace tracking
-- ----------------------------------------------------------------------------
ALTER TABLE bookings
  ADD COLUMN replaces_booking_id INT UNSIGNED NULL 
    COMMENT 'ID of the booking this one replaces (for new booking)',
  ADD COLUMN replaced_by_booking_id INT UNSIGNED NULL 
    COMMENT 'ID of the booking that replaced this one (for original booking)';

-- Create indexes for efficient lookups
CREATE INDEX idx_bookings_replaces_booking_id ON bookings(replaces_booking_id);
CREATE INDEX idx_bookings_replaced_by_booking_id ON bookings(replaced_by_booking_id);

-- Add foreign key constraints
ALTER TABLE bookings
  ADD CONSTRAINT fk_bookings_replaces_booking_id
  FOREIGN KEY (replaces_booking_id) REFERENCES bookings(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE bookings
  ADD CONSTRAINT fk_bookings_replaced_by_booking_id
  FOREIGN KEY (replaced_by_booking_id) REFERENCES bookings(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- ----------------------------------------------------------------------------
-- A3. Create booking_replacements table for audit/relationships
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS booking_replacements (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  original_booking_id INT UNSIGNED NOT NULL 
    COMMENT 'The booking that was replaced',
  new_booking_id INT UNSIGNED NOT NULL 
    COMMENT 'The booking that replaced the original',
  actor_type VARCHAR(32) NOT NULL 
    COMMENT 'customer, staff, or system',
  actor_id INT UNSIGNED NULL 
    COMMENT 'ID of the actor (client_id for customer, user_id for staff)',
  reason VARCHAR(255) NULL 
    COMMENT 'Optional reason for the modification',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  
  -- Each original booking can only be replaced once
  UNIQUE KEY uk_booking_replacements_original (original_booking_id),
  -- Each new booking can only be the result of one replacement
  UNIQUE KEY uk_booking_replacements_new (new_booking_id),
  -- Index for time-based queries
  KEY idx_booking_replacements_created_at (created_at),
  
  CONSTRAINT fk_booking_replacements_original
    FOREIGN KEY (original_booking_id) REFERENCES bookings(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_booking_replacements_new
    FOREIGN KEY (new_booking_id) REFERENCES bookings(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Audit table linking original bookings to their replacements';

-- ----------------------------------------------------------------------------
-- A4. Create booking_events table for immutable audit trail
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS booking_events (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id INT UNSIGNED NOT NULL 
    COMMENT 'The booking this event relates to',
  event_type VARCHAR(64) NOT NULL 
    COMMENT 'Type of event: booking_created, booking_replaced, booking_created_by_replace, booking_cancelled, etc.',
  actor_type VARCHAR(32) NOT NULL 
    COMMENT 'customer, staff, or system',
  actor_id INT UNSIGNED NULL 
    COMMENT 'ID of the actor who caused the event',
  correlation_id VARCHAR(64) NULL 
    COMMENT 'UUID to correlate related events (e.g., replace operation)',
  payload_json JSON NOT NULL 
    COMMENT 'Event-specific data with before/after snapshots',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  
  -- Index for fetching events by booking
  KEY idx_booking_events_booking_id (booking_id),
  -- Index for filtering by event type
  KEY idx_booking_events_event_type (event_type),
  -- Index for time-based queries
  KEY idx_booking_events_created_at (created_at),
  -- Index for correlating related events
  KEY idx_booking_events_correlation_id (correlation_id),
  
  CONSTRAINT fk_booking_events_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Immutable audit trail for all booking events';

-- ============================================================================
-- NOTE: This migration does NOT backfill existing data.
-- All new columns are nullable for backwards compatibility.
-- ============================================================================
