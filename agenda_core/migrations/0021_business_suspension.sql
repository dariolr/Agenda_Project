-- ============================================================================
-- MIGRATION 0021: Business Suspension Support
-- Date: 2026-01-03
-- Description: Add is_suspended and suspension_message fields to businesses
-- ============================================================================

-- Add suspension fields to businesses table
ALTER TABLE businesses 
ADD COLUMN is_suspended TINYINT(1) NOT NULL DEFAULT 0 
    COMMENT 'Whether the business is suspended (visible but not operational)'
    AFTER is_active;

ALTER TABLE businesses 
ADD COLUMN suspension_message TEXT DEFAULT NULL 
    COMMENT 'Message shown to operators and customers when business is suspended'
    AFTER is_suspended;

-- Add index for efficient querying
CREATE INDEX idx_businesses_suspended ON businesses(is_suspended);
