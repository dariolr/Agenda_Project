-- 0046_drop_location_display_labels.sql
-- Remove deprecated single-label nomenclature columns in favor of booking_text_overrides_json

SET @col_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'locations'
    AND COLUMN_NAME = 'staff_display_label'
);
SET @sql := IF(@col_exists > 0, 'ALTER TABLE locations DROP COLUMN staff_display_label', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'locations'
    AND COLUMN_NAME = 'service_display_label'
);
SET @sql := IF(@col_exists > 0, 'ALTER TABLE locations DROP COLUMN service_display_label', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'locations'
    AND COLUMN_NAME = 'location_display_label'
);
SET @sql := IF(@col_exists > 0, 'ALTER TABLE locations DROP COLUMN location_display_label', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
