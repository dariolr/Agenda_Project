-- 20260430_booking_direct_links_location_id.sql
-- Aggiunge location_id ai booking_direct_links per rendere ogni link deterministico sulla sede.
-- Script idempotente, eseguibile direttamente in phpMyAdmin come blocco SQL unico.

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_direct_links'
    AND COLUMN_NAME = 'location_id'
);
SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE booking_direct_links ADD COLUMN location_id INT UNSIGNED NULL AFTER business_id',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE booking_direct_links bdl
INNER JOIN service_variants sv
  ON bdl.target_type = 'service_variant'
 AND bdl.target_id = sv.id
SET bdl.location_id = sv.location_id
WHERE bdl.location_id IS NULL;

UPDATE booking_direct_links bdl
INNER JOIN service_packages sp
  ON bdl.target_type = 'service_package'
 AND bdl.target_id = sp.id
SET bdl.location_id = sp.location_id
WHERE bdl.location_id IS NULL;

UPDATE booking_direct_links bdl
INNER JOIN class_events ce
  ON bdl.target_type = 'class_event'
 AND bdl.target_id = ce.id
SET bdl.location_id = ce.location_id
WHERE bdl.location_id IS NULL;

UPDATE booking_direct_links bdl
INNER JOIN (
  SELECT l.business_id, COALESCE(
    MAX(CASE WHEN l.is_default = 1 AND l.is_active = 1 THEN l.id END),
    MIN(CASE WHEN l.is_active = 1 THEN l.id END)
  ) AS location_id
  FROM locations l
  GROUP BY l.business_id
) defaults_by_business
  ON defaults_by_business.business_id = bdl.business_id
SET bdl.location_id = defaults_by_business.location_id
WHERE bdl.target_type = 'service_category'
  AND bdl.location_id IS NULL;

SET @idx_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_direct_links'
    AND INDEX_NAME = 'idx_booking_direct_links_target'
);
SET @sql = IF(
  @idx_exists > 0,
  'ALTER TABLE booking_direct_links DROP INDEX idx_booking_direct_links_target',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @uniq_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_direct_links'
    AND INDEX_NAME = 'uniq_booking_direct_links_business_target_location'
);
SET @sql = IF(
  @uniq_exists = 0,
  'ALTER TABLE booking_direct_links ADD UNIQUE KEY uniq_booking_direct_links_business_target_location (business_id, target_type, target_id, location_id)',
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
    AND INDEX_NAME = 'idx_booking_direct_links_location'
);
SET @sql = IF(
  @idx_exists = 0,
  'ALTER TABLE booking_direct_links ADD KEY idx_booking_direct_links_location (location_id)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @null_count = (
  SELECT COUNT(*)
  FROM booking_direct_links
  WHERE location_id IS NULL
);
SET @sql = IF(
  @null_count = 0,
  'ALTER TABLE booking_direct_links MODIFY COLUMN location_id INT UNSIGNED NOT NULL',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
