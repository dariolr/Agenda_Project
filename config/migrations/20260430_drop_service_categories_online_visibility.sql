-- 20260430_drop_service_categories_online_visibility.sql
-- Rimuove online_visibility dalle categorie servizio.
-- Script idempotente, eseguibile direttamente in phpMyAdmin come blocco SQL unico.

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'service_categories'
    AND COLUMN_NAME = 'online_visibility'
);
SET @sql = IF(
  @column_exists = 1,
  'ALTER TABLE service_categories DROP COLUMN online_visibility',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
