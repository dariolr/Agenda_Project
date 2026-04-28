-- 20260428_businesses_locale.sql
-- Aggiunge la colonna locale alla tabella businesses per supportare email
-- in lingua diversa per ogni business (it/en). Default 'it'.
-- Script idempotente.

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'businesses'
    AND COLUMN_NAME = 'locale'
);

SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE businesses ADD COLUMN locale VARCHAR(10) NOT NULL DEFAULT ''it'' AFTER email',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
