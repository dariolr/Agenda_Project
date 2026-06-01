-- Aggiunge il flag business-scoped per abilitare/disabilitare l'invio WhatsApp.
-- Precedenza invio: whatsapp_enabled = 1 AND messages_enabled = 1 AND business_messages_enabled = 1.

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

DROP PROCEDURE IF EXISTS add_index_if_missing $$
CREATE PROCEDURE add_index_if_missing(
    IN table_name_value varchar(64),
    IN index_name_value varchar(64),
    IN alter_sql text
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = table_name_value
          AND INDEX_NAME = index_name_value
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
  'business_messages_enabled',
  'ALTER TABLE `business_whatsapp_settings` ADD COLUMN `business_messages_enabled` tinyint(1) NOT NULL DEFAULT 1 AFTER `messages_enabled`'
);

CALL add_index_if_missing(
  'business_whatsapp_settings',
  'idx_bws_effective_messages',
  'ALTER TABLE `business_whatsapp_settings` ADD KEY `idx_bws_effective_messages` (`whatsapp_enabled`,`messages_enabled`,`business_messages_enabled`)'
);

DROP PROCEDURE IF EXISTS add_index_if_missing;
DROP PROCEDURE IF EXISTS add_column_if_missing;
