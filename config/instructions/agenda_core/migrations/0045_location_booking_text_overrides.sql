-- 0045_location_booking_text_overrides.sql
-- Add per-locale phrase overrides for online booking copy at location level

SET @col_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'locations'
    AND COLUMN_NAME = 'booking_text_overrides_json'
);

SET @sql := IF(
  @col_exists = 0,
  "ALTER TABLE locations ADD COLUMN booking_text_overrides_json JSON NULL COMMENT 'Per-locale booking phrase overrides: {\"it\":{\"services_title\":\"...\"},\"en\":{\"services_title\":\"...\"}}' AFTER allow_customer_choose_staff",
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
