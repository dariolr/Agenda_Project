-- ============================================================================
-- Migration 0026: Add actor_name column to booking_events
-- ============================================================================
-- This migration adds a denormalized actor_name column to preserve the actor's
-- name at the time of the event, even if the actor is later deleted.
-- ============================================================================

-- Add actor_name column
ALTER TABLE booking_events
ADD COLUMN actor_name VARCHAR(255) NULL 
  COMMENT 'Denormalized actor name at event time (preserved even if actor deleted)'
  AFTER actor_id;

-- ============================================================================
-- NOTE: Existing events will have actor_name = NULL.
-- The API will fallback to dynamic lookup for old events without actor_name.
-- ============================================================================
