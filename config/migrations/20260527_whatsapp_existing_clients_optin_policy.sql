-- Aggiunge la policy per clienti gia' esistenti rispetto all'invio WhatsApp.
-- explicit_only: invia solo a clienti con opt-in esplicito.
-- assume_existing_consented: considera consenzienti i clienti creati prima dell'attivazione policy.

DELIMITER $$

DROP PROCEDURE IF EXISTS add_column_if_missing $$
CREATE PROCEDURE add_column_if_missing(
    IN table_name_value varchar(64),
    IN column_name_value varchar(64),
    IN alter_sql text
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = table_name_value
          AND COLUMN_NAME = column_name_value
    ) THEN
        SET @sql = alter_sql;
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END $$

DELIMITER ;

CALL add_column_if_missing(
  'business_whatsapp_settings',
  'existing_clients_opt_in_policy',
  'ALTER TABLE `business_whatsapp_settings` ADD COLUMN `existing_clients_opt_in_policy` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "explicit_only" AFTER `default_channel_mode`'
);

CALL add_column_if_missing(
  'business_whatsapp_settings',
  'existing_clients_opt_in_assumed_at',
  'ALTER TABLE `business_whatsapp_settings` ADD COLUMN `existing_clients_opt_in_assumed_at` timestamp NULL DEFAULT NULL AFTER `existing_clients_opt_in_policy`'
);

DROP PROCEDURE IF EXISTS add_column_if_missing;

UPDATE `business_whatsapp_settings`
SET `existing_clients_opt_in_policy` = 'explicit_only'
WHERE `existing_clients_opt_in_policy` NOT IN ('explicit_only', 'assume_existing_consented');
