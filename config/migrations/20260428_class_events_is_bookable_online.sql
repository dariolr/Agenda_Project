-- 20260428_class_events_is_bookable_online.sql
-- Aggiunge agli eventi programmati lo stesso flag dei servizi per escluderli
-- dalla prenotazione online sul frontend.
-- Script idempotente, eseguibile direttamente in phpMyAdmin come blocco SQL unico.

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'class_events'
    AND COLUMN_NAME = 'is_bookable_online'
);

SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE class_events ADD COLUMN is_bookable_online TINYINT(1) NOT NULL DEFAULT 1 AFTER waitlist_enabled',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
