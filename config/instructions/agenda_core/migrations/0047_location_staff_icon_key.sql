-- 0047_location_staff_icon_key.sql
-- Add semantic icon key for booking staff/resource step, independent from locale text.

SET @col_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'locations'
    AND COLUMN_NAME = 'staff_icon_key'
);

SET @sql := IF(
  @col_exists = 0,
  "ALTER TABLE locations ADD COLUMN staff_icon_key VARCHAR(32) NOT NULL DEFAULT 'person' COMMENT 'Semantic icon key for booking staff/resource step' AFTER booking_text_overrides_json",
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
