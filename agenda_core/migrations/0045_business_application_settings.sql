-- ============================================================================
-- Migration 0045: Create business_application_settings table
-- ============================================================================

CREATE TABLE IF NOT EXISTS `business_application_settings` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` int UNSIGNED NOT NULL,
  `setting_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Unique parameter key within the business scope',
  `setting_value` json NOT NULL COMMENT 'Parameter value, supports scalar and structured data',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_business_setting_key` (`business_id`,`setting_key`),
  KEY `idx_business_setting_key` (`setting_key`),
  CONSTRAINT `fk_business_application_settings_business`
    FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Business-scoped application behavior parameters';
