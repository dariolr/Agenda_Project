-- 0044_booking_nomenclature_overrides.sql
-- Move booking nomenclature to location-only columns
-- Date: 2026-03-31

START TRANSACTION;

-- locations.staff_display_label
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'locations'
    AND COLUMN_NAME = 'staff_display_label'
);
SET @sql = IF(
  @col_exists = 0,
  "ALTER TABLE locations ADD COLUMN staff_display_label VARCHAR(80) NULL COMMENT 'Custom label override for staff in booking UI (location scope)' AFTER allow_customer_choose_staff",
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- locations.service_display_label
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'locations'
    AND COLUMN_NAME = 'service_display_label'
);
SET @sql = IF(
  @col_exists = 0,
  "ALTER TABLE locations ADD COLUMN service_display_label VARCHAR(80) NULL COMMENT 'Custom label override for services in booking UI (location scope)' AFTER staff_display_label",
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- locations.location_display_label
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'locations'
    AND COLUMN_NAME = 'location_display_label'
);
SET @sql = IF(
  @col_exists = 0,
  "ALTER TABLE locations ADD COLUMN location_display_label VARCHAR(80) NULL COMMENT 'Custom label override for locations in booking UI (location scope)' AFTER service_display_label",
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- If legacy table exists, migrate values into location columns.
SET @table_exists = (
  SELECT COUNT(*)
  FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'booking_nomenclature_overrides'
);

-- Location-level legacy overrides (location_id NOT NULL)
SET @sql = IF(
  @table_exists > 0,
  'UPDATE locations l
   JOIN booking_nomenclature_overrides bno
     ON bno.location_id = l.id
    AND bno.target = ''staff''
   SET l.staff_display_label = COALESCE(NULLIF(TRIM(l.staff_display_label), ''''), NULLIF(TRIM(bno.custom_label), ''''))',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  @table_exists > 0,
  'UPDATE locations l
   JOIN booking_nomenclature_overrides bno
     ON bno.location_id = l.id
    AND bno.target = ''services''
   SET l.service_display_label = COALESCE(NULLIF(TRIM(l.service_display_label), ''''), NULLIF(TRIM(bno.custom_label), ''''))',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  @table_exists > 0,
  'UPDATE locations l
   JOIN booking_nomenclature_overrides bno
     ON bno.location_id = l.id
    AND bno.target = ''locations''
   SET l.location_display_label = COALESCE(NULLIF(TRIM(l.location_display_label), ''''), NULLIF(TRIM(bno.custom_label), ''''))',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Business-level legacy overrides are expanded to all business locations only if location value is empty.
SET @sql = IF(
  @table_exists > 0,
  'UPDATE locations l
   JOIN booking_nomenclature_overrides bno
     ON bno.business_id = l.business_id
    AND bno.location_id IS NULL
    AND bno.target = ''staff''
   SET l.staff_display_label = COALESCE(NULLIF(TRIM(l.staff_display_label), ''''), NULLIF(TRIM(bno.custom_label), ''''))',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  @table_exists > 0,
  'UPDATE locations l
   JOIN booking_nomenclature_overrides bno
     ON bno.business_id = l.business_id
    AND bno.location_id IS NULL
    AND bno.target = ''services''
   SET l.service_display_label = COALESCE(NULLIF(TRIM(l.service_display_label), ''''), NULLIF(TRIM(bno.custom_label), ''''))',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  @table_exists > 0,
  'UPDATE locations l
   JOIN booking_nomenclature_overrides bno
     ON bno.business_id = l.business_id
    AND bno.location_id IS NULL
    AND bno.target = ''locations''
   SET l.location_display_label = COALESCE(NULLIF(TRIM(l.location_display_label), ''''), NULLIF(TRIM(bno.custom_label), ''''))',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Remove legacy table after backfill.
SET @sql = IF(
  @table_exists > 0,
  'DROP TABLE booking_nomenclature_overrides',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Drop obsolete business-level columns if present.
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'businesses'
    AND COLUMN_NAME = 'staff_display_label'
);
SET @sql = IF(@col_exists > 0, 'ALTER TABLE businesses DROP COLUMN staff_display_label', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'businesses'
    AND COLUMN_NAME = 'service_display_label'
);
SET @sql = IF(@col_exists > 0, 'ALTER TABLE businesses DROP COLUMN service_display_label', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'businesses'
    AND COLUMN_NAME = 'location_display_label'
);
SET @sql = IF(@col_exists > 0, 'ALTER TABLE businesses DROP COLUMN location_display_label', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

COMMIT;
