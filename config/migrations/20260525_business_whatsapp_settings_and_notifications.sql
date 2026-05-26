-- Governance e completamento schema WhatsApp Business.
-- Idempotente quanto possibile per MySQL/SiteGround.

CREATE TABLE IF NOT EXISTS `business_whatsapp_settings` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` int UNSIGNED NOT NULL,
  `provider_code` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'meta',
  `whatsapp_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `activation_allowed` tinyint(1) NOT NULL DEFAULT '0',
  `messages_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `allow_business_self_onboarding` tinyint(1) NOT NULL DEFAULT '1',
  `allow_location_mapping` tinyint(1) NOT NULL DEFAULT '0',
  `default_channel_mode` enum('disabled','business_default','location_mapping') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'business_default',
  `status` enum('not_enabled','enabled','onboarding','pending_review','active','suspended','error') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'not_enabled',
  `last_go_live_check_at` timestamp NULL DEFAULT NULL,
  `last_error_code` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_error_message` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `enabled_by_user_id` int UNSIGNED DEFAULT NULL,
  `enabled_at` timestamp NULL DEFAULT NULL,
  `disabled_at` timestamp NULL DEFAULT NULL,
  `notes` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_business_whatsapp_settings_business` (`business_id`),
  KEY `idx_bws_enabled_flags` (`whatsapp_enabled`,`activation_allowed`,`messages_enabled`),
  KEY `idx_bws_status` (`status`),
  KEY `idx_bws_enabled_by_user` (`enabled_by_user_id`),
  CONSTRAINT `fk_bws_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bws_enabled_by_user` FOREIGN KEY (`enabled_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS add_column_if_missing;
DELIMITER //
CREATE PROCEDURE add_column_if_missing(IN tableName varchar(64), IN columnName varchar(64), IN alterSql text)
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = tableName
      AND COLUMN_NAME = columnName
  ) THEN
    SET @ddl = alterSql;
    PREPARE stmt FROM @ddl;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

CALL add_column_if_missing('whatsapp_business_config', 'provider_code', 'ALTER TABLE `whatsapp_business_config` ADD COLUMN `provider_code` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "meta" AFTER `business_id`');
CALL add_column_if_missing('whatsapp_business_config', 'display_name', 'ALTER TABLE `whatsapp_business_config` ADD COLUMN `display_name` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `provider_code`');
CALL add_column_if_missing('whatsapp_business_config', 'business_manager_id', 'ALTER TABLE `whatsapp_business_config` ADD COLUMN `business_manager_id` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `waba_id`');
CALL add_column_if_missing('whatsapp_business_config', 'token_expires_at', 'ALTER TABLE `whatsapp_business_config` ADD COLUMN `token_expires_at` timestamp NULL DEFAULT NULL AFTER `access_token_encrypted`');
CALL add_column_if_missing('whatsapp_business_config', 'webhook_verified_at', 'ALTER TABLE `whatsapp_business_config` ADD COLUMN `webhook_verified_at` timestamp NULL DEFAULT NULL AFTER `is_default`');
CALL add_column_if_missing('whatsapp_business_config', 'last_health_check_at', 'ALTER TABLE `whatsapp_business_config` ADD COLUMN `last_health_check_at` timestamp NULL DEFAULT NULL AFTER `webhook_verified_at`');
CALL add_column_if_missing('whatsapp_business_config', 'last_error_code', 'ALTER TABLE `whatsapp_business_config` ADD COLUMN `last_error_code` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `last_health_check_at`');
CALL add_column_if_missing('whatsapp_business_config', 'last_error_message', 'ALTER TABLE `whatsapp_business_config` ADD COLUMN `last_error_message` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `last_error_code`');
CALL add_column_if_missing('whatsapp_business_config', 'created_by_user_id', 'ALTER TABLE `whatsapp_business_config` ADD COLUMN `created_by_user_id` int UNSIGNED DEFAULT NULL AFTER `last_error_message`');
CALL add_column_if_missing('whatsapp_business_config', 'updated_by_user_id', 'ALTER TABLE `whatsapp_business_config` ADD COLUMN `updated_by_user_id` int UNSIGNED DEFAULT NULL AFTER `created_by_user_id`');

CALL add_column_if_missing('whatsapp_outbox', 'class_booking_id', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `class_booking_id` int UNSIGNED DEFAULT NULL AFTER `booking_id`');
CALL add_column_if_missing('whatsapp_outbox', 'client_id', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `client_id` int UNSIGNED DEFAULT NULL AFTER `class_booking_id`');
CALL add_column_if_missing('whatsapp_outbox', 'recipient_phone_e164', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `recipient_phone_e164` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `recipient_phone`');
CALL add_column_if_missing('whatsapp_outbox', 'template_variables_json', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `template_variables_json` json DEFAULT NULL AFTER `template_payload`');
CALL add_column_if_missing('whatsapp_outbox', 'message_type', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `message_type` enum("booking_confirmation","booking_reminder","booking_cancellation","booking_reschedule","class_booking_confirmation","class_booking_reminder","class_booking_cancellation","test") COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "test" AFTER `template_variables_json`');
CALL add_column_if_missing('whatsapp_outbox', 'locked_at', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `locked_at` timestamp NULL DEFAULT NULL AFTER `scheduled_at`');
CALL add_column_if_missing('whatsapp_outbox', 'locked_by', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `locked_by` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `locked_at`');
CALL add_column_if_missing('whatsapp_outbox', 'provider_error_code', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `provider_error_code` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `error_message`');
CALL add_column_if_missing('whatsapp_outbox', 'provider_error_message', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `provider_error_message` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `provider_error_code`');
CALL add_column_if_missing('whatsapp_outbox', 'failed_at', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `failed_at` timestamp NULL DEFAULT NULL AFTER `read_at`');
CALL add_column_if_missing('whatsapp_outbox', 'dedupe_key', 'ALTER TABLE `whatsapp_outbox` ADD COLUMN `dedupe_key` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `failed_at`');

CALL add_column_if_missing('whatsapp_client_optins', 'phone_e164', 'ALTER TABLE `whatsapp_client_optins` ADD COLUMN `phone_e164` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `client_id`');
CALL add_column_if_missing('whatsapp_client_optins', 'opted_in', 'ALTER TABLE `whatsapp_client_optins` ADD COLUMN `opted_in` tinyint(1) NOT NULL DEFAULT "0" AFTER `phone_e164`');
CALL add_column_if_missing('whatsapp_client_optins', 'consent_text', 'ALTER TABLE `whatsapp_client_optins` ADD COLUMN `consent_text` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `source`');
CALL add_column_if_missing('whatsapp_client_optins', 'consented_at', 'ALTER TABLE `whatsapp_client_optins` ADD COLUMN `consented_at` timestamp NULL DEFAULT NULL AFTER `consent_text`');
CALL add_column_if_missing('whatsapp_client_optins', 'revoked_at', 'ALTER TABLE `whatsapp_client_optins` ADD COLUMN `revoked_at` timestamp NULL DEFAULT NULL AFTER `consented_at`');

CALL add_column_if_missing('whatsapp_templates', 'provider_code', 'ALTER TABLE `whatsapp_templates` ADD COLUMN `provider_code` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "meta" AFTER `business_id`');
CALL add_column_if_missing('whatsapp_templates', 'language_code', 'ALTER TABLE `whatsapp_templates` ADD COLUMN `language_code` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "it" AFTER `template_name`');
CALL add_column_if_missing('whatsapp_templates', 'message_type', 'ALTER TABLE `whatsapp_templates` ADD COLUMN `message_type` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `status`');
CALL add_column_if_missing('whatsapp_templates', 'body_preview', 'ALTER TABLE `whatsapp_templates` ADD COLUMN `body_preview` text COLLATE utf8mb4_unicode_ci AFTER `message_type`');
CALL add_column_if_missing('whatsapp_templates', 'variables_schema_json', 'ALTER TABLE `whatsapp_templates` ADD COLUMN `variables_schema_json` json DEFAULT NULL AFTER `body_preview`');
CALL add_column_if_missing('whatsapp_templates', 'provider_template_id', 'ALTER TABLE `whatsapp_templates` ADD COLUMN `provider_template_id` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `variables_schema_json`');

CALL add_column_if_missing('whatsapp_webhook_events', 'provider_code', 'ALTER TABLE `whatsapp_webhook_events` ADD COLUMN `provider_code` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "meta" AFTER `id`');
CALL add_column_if_missing('whatsapp_webhook_events', 'provider_event_id', 'ALTER TABLE `whatsapp_webhook_events` ADD COLUMN `provider_event_id` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `event_id`');
CALL add_column_if_missing('whatsapp_webhook_events', 'phone_number_id', 'ALTER TABLE `whatsapp_webhook_events` ADD COLUMN `phone_number_id` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `provider_event_id`');

DROP PROCEDURE IF EXISTS add_column_if_missing;

UPDATE `whatsapp_client_optins`
SET `opted_in` = `opt_in`
WHERE `opted_in` <> `opt_in`;

ALTER TABLE `whatsapp_business_config`
  MODIFY `status` enum('draft','pending','active','inactive','suspended','error') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  MODIFY `waba_id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  MODIFY `phone_number_id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  MODIFY `access_token_encrypted` text COLLATE utf8mb4_unicode_ci NULL;

ALTER TABLE `whatsapp_outbox`
  MODIFY `status` enum('queued','processing','sent','delivered','read','failed','cancelled','skipped') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'queued',
  MODIFY `provider_message_id` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL;

ALTER TABLE `whatsapp_templates`
  MODIFY `business_id` int UNSIGNED DEFAULT NULL,
  MODIFY `status` enum('draft','submitted','approved','rejected','disabled','pending','paused') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft';

DROP PROCEDURE IF EXISTS add_index_if_missing;
DELIMITER //
CREATE PROCEDURE add_index_if_missing(IN tableName varchar(64), IN indexName varchar(64), IN alterSql text)
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = tableName
      AND INDEX_NAME = indexName
  ) THEN
    SET @ddl = alterSql;
    PREPARE stmt FROM @ddl;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

CALL add_index_if_missing('whatsapp_business_config', 'idx_bwc_business_status_default', 'ALTER TABLE `whatsapp_business_config` ADD KEY `idx_bwc_business_status_default` (`business_id`,`status`,`is_default`)');
CALL add_index_if_missing('whatsapp_business_config', 'idx_bwc_provider_phone', 'ALTER TABLE `whatsapp_business_config` ADD KEY `idx_bwc_provider_phone` (`provider_code`,`phone_number_id`)');
CALL add_index_if_missing('whatsapp_outbox', 'idx_wo_booking_type', 'ALTER TABLE `whatsapp_outbox` ADD KEY `idx_wo_booking_type` (`booking_id`,`message_type`)');
CALL add_index_if_missing('whatsapp_outbox', 'idx_wo_class_booking_type', 'ALTER TABLE `whatsapp_outbox` ADD KEY `idx_wo_class_booking_type` (`class_booking_id`,`message_type`)');
CALL add_index_if_missing('whatsapp_outbox', 'uniq_whatsapp_outbox_dedupe_key', 'ALTER TABLE `whatsapp_outbox` ADD UNIQUE KEY `uniq_whatsapp_outbox_dedupe_key` (`dedupe_key`)');
CALL add_index_if_missing('whatsapp_webhook_events', 'idx_wwe_phone_number', 'ALTER TABLE `whatsapp_webhook_events` ADD KEY `idx_wwe_phone_number` (`phone_number_id`)');

DROP PROCEDURE IF EXISTS add_index_if_missing;
