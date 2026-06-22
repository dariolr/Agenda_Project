-- Aggiunge i metadati per la submission automatica dei template WhatsApp a Meta.
-- Idempotente e phpMyAdmin-ready.

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
  'whatsapp_templates',
  'meta_submission_requested_at',
  'ALTER TABLE `whatsapp_templates` ADD COLUMN `meta_submission_requested_at` timestamp NULL DEFAULT NULL AFTER `provider_template_id`'
);

CALL add_column_if_missing(
  'whatsapp_templates',
  'meta_last_synced_at',
  'ALTER TABLE `whatsapp_templates` ADD COLUMN `meta_last_synced_at` timestamp NULL DEFAULT NULL AFTER `meta_submission_requested_at`'
);

CALL add_column_if_missing(
  'whatsapp_templates',
  'last_error_code',
  'ALTER TABLE `whatsapp_templates` ADD COLUMN `last_error_code` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `meta_last_synced_at`'
);

CALL add_column_if_missing(
  'whatsapp_templates',
  'last_error_message',
  'ALTER TABLE `whatsapp_templates` ADD COLUMN `last_error_message` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `last_error_code`'
);

CALL add_column_if_missing(
  'whatsapp_templates',
  'rejection_reason',
  'ALTER TABLE `whatsapp_templates` ADD COLUMN `rejection_reason` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `last_error_message`'
);

CALL add_column_if_missing(
  'whatsapp_templates',
  'is_auto_created',
  'ALTER TABLE `whatsapp_templates` ADD COLUMN `is_auto_created` tinyint(1) NOT NULL DEFAULT 0 AFTER `rejection_reason`'
);

CALL add_column_if_missing(
  'whatsapp_templates',
  'source',
  'ALTER TABLE `whatsapp_templates` ADD COLUMN `source` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `is_auto_created`'
);

CALL add_index_if_missing(
  'whatsapp_templates',
  'idx_wt_provider_template_id',
  'ALTER TABLE `whatsapp_templates` ADD KEY `idx_wt_provider_template_id` (`provider_template_id`)'
);

CALL add_index_if_missing(
  'whatsapp_templates',
  'idx_wt_message_language_status',
  'ALTER TABLE `whatsapp_templates` ADD KEY `idx_wt_message_language_status` (`business_id`, `message_type`, `language_code`, `status`)'
);

DROP PROCEDURE IF EXISTS add_index_if_missing;
DROP PROCEDURE IF EXISTS add_column_if_missing;
