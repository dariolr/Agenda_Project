SET @has_booking_intro_message := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'locations'
    AND COLUMN_NAME = 'booking_intro_message'
);

SET @sql := IF(
  @has_booking_intro_message = 0,
  "ALTER TABLE `locations` ADD COLUMN `booking_intro_message` TEXT NULL COMMENT 'Messaggio opzionale mostrato nel booking online dopo la scelta sede e prima della selezione servizi/lezioni' AFTER `booking_default_locale`",
  "SELECT 'booking_intro_message already exists' AS message"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_booking_confirmation_message := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'locations'
    AND COLUMN_NAME = 'booking_confirmation_message'
);

SET @sql := IF(
  @has_booking_confirmation_message = 0,
  "ALTER TABLE `locations` ADD COLUMN `booking_confirmation_message` TEXT NULL COMMENT 'Messaggio opzionale mostrato nel booking online nella pagina di conferma prenotazione' AFTER `booking_intro_message`",
  "SELECT 'booking_confirmation_message already exists' AS message"
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
