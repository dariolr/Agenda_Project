-- ============================================================================
-- Migration 0048: Add forgot-password rate limit tracking table
-- ============================================================================

CREATE TABLE `forgot_password_rate_limits` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `scope` enum('operator','customer') COLLATE utf8mb4_unicode_ci NOT NULL,
  `business_id` bigint UNSIGNED DEFAULT NULL,
  `email_hash` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ip_hash` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_forgot_rate_lookup` (`scope`,`business_id`,`email_hash`,`ip_hash`,`created_at`),
  KEY `idx_forgot_rate_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
