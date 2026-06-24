-- 20260624_booking_direct_links_business_category_and_staff.sql
-- Supporta direct link business-level per categorie e staff.
-- Script idempotente, eseguibile direttamente in phpMyAdmin come blocco SQL unico.

SET @column_type = (
  SELECT COLUMN_TYPE
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_direct_links'
    AND COLUMN_NAME = 'target_type'
);
SET @sql = IF(
  @column_type NOT LIKE '%staff%',
  'ALTER TABLE booking_direct_links MODIFY COLUMN target_type ENUM(''service_variant'',''service_package'',''class_event'',''service_category'',''staff'') NOT NULL',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_direct_links'
    AND COLUMN_NAME = 'scope_type'
);
SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE booking_direct_links ADD COLUMN scope_type ENUM(''location'',''business'') NOT NULL DEFAULT ''location'' AFTER location_id',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE booking_direct_links
SET scope_type = 'location'
WHERE scope_type IS NULL OR scope_type = '';

ALTER TABLE booking_direct_links
  MODIFY COLUMN location_id INT UNSIGNED NULL;

SET @idx_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_direct_links'
    AND INDEX_NAME = 'uniq_booking_direct_links_business_target_location'
);
SET @sql = IF(
  @idx_exists > 0,
  'ALTER TABLE booking_direct_links DROP INDEX uniq_booking_direct_links_business_target_location',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_direct_links'
    AND COLUMN_NAME = 'location_scope_key'
);
SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE booking_direct_links ADD COLUMN location_scope_key INT UNSIGNED GENERATED ALWAYS AS (IF(scope_type = ''business'', 0, location_id)) STORED AFTER location_id',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_direct_links'
    AND INDEX_NAME = 'uniq_booking_direct_links_business_target_scope'
);
SET @sql = IF(
  @idx_exists = 0,
  'ALTER TABLE booking_direct_links ADD UNIQUE KEY uniq_booking_direct_links_business_target_scope (business_id, target_type, target_id, scope_type, location_scope_key)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @constraint_exists = (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_direct_links'
    AND CONSTRAINT_NAME = 'chk_booking_direct_links_scope_target'
);
SET @sql = IF(
  @constraint_exists = 0,
  'ALTER TABLE booking_direct_links ADD CONSTRAINT chk_booking_direct_links_scope_target CHECK ((scope_type = ''location'' AND location_id IS NOT NULL) OR (scope_type = ''business'' AND location_id IS NULL AND target_type IN (''service_category'',''staff'')))',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
