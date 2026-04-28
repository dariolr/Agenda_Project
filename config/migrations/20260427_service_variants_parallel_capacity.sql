-- 20260427_service_variants_parallel_capacity.sql
-- Capienza parallela per varianti servizio prenotabili sullo stesso staff/location/intervallo.
-- Script idempotente, eseguibile direttamente in phpMyAdmin come blocco SQL unico.
-- Non richiede DELIMITER, stored procedure o privilegi oltre ad ALTER/CREATE/DROP INDEX.

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'service_variants'
    AND COLUMN_NAME = 'parallel_capacity'
);

SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE service_variants ADD COLUMN parallel_capacity INT UNSIGNED NOT NULL DEFAULT 1 COMMENT ''Numero massimo di prenotazioni contemporanee consentite per questa variante servizio nella stessa location/staff/intervallo'' AFTER is_price_starting_from',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @service_variants_index_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'service_variants'
    AND INDEX_NAME = 'idx_service_variants_parallel_capacity'
);

SET @sql = IF(
  @service_variants_index_exists = 0,
  'CREATE INDEX idx_service_variants_parallel_capacity ON service_variants(location_id, service_id, parallel_capacity)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @booking_items_index_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_items'
    AND INDEX_NAME = 'idx_booking_items_capacity_check'
);

SET @booking_items_index_columns = (
  SELECT COALESCE(GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX SEPARATOR ','), '')
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_items'
    AND INDEX_NAME = 'idx_booking_items_capacity_check'
);

SET @sql = IF(
  @booking_items_index_exists > 0
    AND @booking_items_index_columns <> 'location_id,staff_id,service_variant_id,start_time,end_time',
  'DROP INDEX idx_booking_items_capacity_check ON booking_items',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @booking_items_index_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_items'
    AND INDEX_NAME = 'idx_booking_items_capacity_check'
);

SET @sql = IF(
  @booking_items_index_exists = 0,
  'CREATE INDEX idx_booking_items_capacity_check ON booking_items(location_id, staff_id, service_variant_id, start_time, end_time)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
