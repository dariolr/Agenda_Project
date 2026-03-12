-- ============================================================================
-- Migration 0046: Add show_appointment_price_in_card flag to businesses
-- ============================================================================

ALTER TABLE `businesses`
  ADD COLUMN `show_appointment_price_in_card` tinyint(1) NOT NULL DEFAULT '0'
  AFTER `cancellation_hours`;
