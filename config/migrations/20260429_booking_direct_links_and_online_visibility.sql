-- 20260429_booking_direct_links_and_online_visibility.sql
-- Link diretti booking e visibilita online a tre stati.
-- Script idempotente, eseguibile direttamente in phpMyAdmin come blocco SQL unico.

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'service_variants'
    AND COLUMN_NAME = 'online_visibility'
);
SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE service_variants ADD COLUMN online_visibility ENUM(''public'',''direct_link'',''hidden'') NOT NULL DEFAULT ''public'' AFTER is_bookable_online',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'service_packages'
    AND COLUMN_NAME = 'online_visibility'
);
SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE service_packages ADD COLUMN online_visibility ENUM(''public'',''direct_link'',''hidden'') NOT NULL DEFAULT ''public'' AFTER is_bookable_online',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'class_events'
    AND COLUMN_NAME = 'online_visibility'
);
SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE class_events ADD COLUMN online_visibility ENUM(''public'',''direct_link'',''hidden'') NOT NULL DEFAULT ''public'' AFTER is_bookable_online',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'service_categories'
    AND COLUMN_NAME = 'online_visibility'
);
SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE service_categories ADD COLUMN online_visibility ENUM(''public'',''direct_link'',''hidden'') NOT NULL DEFAULT ''public'' AFTER sort_order',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE service_variants
SET online_visibility = IF(is_bookable_online = 1, 'public', 'hidden')
WHERE online_visibility = 'public';

UPDATE service_packages
SET online_visibility = IF(is_bookable_online = 1, 'public', 'hidden')
WHERE online_visibility = 'public';

UPDATE class_events
SET online_visibility = IF(is_bookable_online = 1, 'public', 'hidden')
WHERE online_visibility = 'public';

UPDATE service_categories
SET online_visibility = 'public'
WHERE online_visibility NOT IN ('public', 'direct_link', 'hidden');

CREATE TABLE IF NOT EXISTS booking_direct_links (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  slug VARCHAR(160) NOT NULL,
  target_type ENUM('service_variant','service_package','class_event','service_category') NOT NULL,
  target_id INT UNSIGNED NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_booking_direct_links_business_slug (business_id, slug),
  KEY idx_booking_direct_links_business_active (business_id, is_active),
  KEY idx_booking_direct_links_target (target_type, target_id),
  CONSTRAINT fk_booking_direct_links_business
    FOREIGN KEY (business_id) REFERENCES businesses(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
