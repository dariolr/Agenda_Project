-- 0043_booking_items_pricing_snapshot.sql
-- Add pricing snapshot fields for robust package-aware totals on booking_items
-- Date: 2026-03-27

START TRANSACTION;

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_items'
    AND COLUMN_NAME = 'list_price_cents'
);
SET @sql = IF(
  @col_exists = 0,
  "ALTER TABLE booking_items ADD COLUMN list_price_cents INT UNSIGNED NULL COMMENT 'List/original item price snapshot in cents' AFTER price",
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_items'
    AND COLUMN_NAME = 'applied_price_cents'
);
SET @sql = IF(
  @col_exists = 0,
  "ALTER TABLE booking_items ADD COLUMN applied_price_cents INT UNSIGNED NULL COMMENT 'Final applied item price snapshot in cents' AFTER list_price_cents",
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_items'
    AND COLUMN_NAME = 'package_id'
);
SET @sql = IF(
  @col_exists = 0,
  "ALTER TABLE booking_items ADD COLUMN package_id INT UNSIGNED NULL COMMENT 'Service package used for pricing, if any' AFTER applied_price_cents",
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_items'
    AND COLUMN_NAME = 'pricing_source'
);
SET @sql = IF(
  @col_exists = 0,
  "ALTER TABLE booking_items ADD COLUMN pricing_source VARCHAR(32) NULL COMMENT 'Pricing origin: service/package/discount/custom' AFTER package_id",
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_items'
    AND INDEX_NAME = 'idx_booking_items_package'
);
SET @sql = IF(
  @index_exists = 0,
  'ALTER TABLE booking_items ADD INDEX idx_booking_items_package (package_id)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Backfill existing rows from legacy decimal price.
UPDATE booking_items
SET
  list_price_cents = COALESCE(list_price_cents, ROUND(price * 100)),
  applied_price_cents = COALESCE(applied_price_cents, ROUND(price * 100)),
  pricing_source = COALESCE(pricing_source, 'legacy')
WHERE price IS NOT NULL
  AND (
    list_price_cents IS NULL
    OR applied_price_cents IS NULL
    OR pricing_source IS NULL
  );

-- Default remaining null source values to service.
UPDATE booking_items
SET pricing_source = 'service'
WHERE pricing_source IS NULL;

SET @fk_exists = (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_items'
    AND CONSTRAINT_NAME = 'fk_booking_items_package'
    AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);
SET @sql = IF(
  @fk_exists = 0,
  'ALTER TABLE booking_items ADD CONSTRAINT fk_booking_items_package FOREIGN KEY (package_id) REFERENCES service_packages(id) ON DELETE SET NULL ON UPDATE CASCADE',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

COMMIT;
