-- Online booking payments (Stripe Connect / PayPal Multiparty)
-- Additive migration. Do not reuse business_billing_* tables.

CREATE TABLE IF NOT EXISTS `business_online_payment_accounts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `provider_code` VARCHAR(32) NOT NULL,
  `mode` ENUM('test','live') NOT NULL DEFAULT 'test',
  `provider_account_id` VARCHAR(191) DEFAULT NULL,
  `provider_merchant_id` VARCHAR(191) DEFAULT NULL,
  `is_enabled` TINYINT(1) NOT NULL DEFAULT 0,
  `onboarding_status` ENUM('not_configured','pending','active','restricted','disabled','error') NOT NULL DEFAULT 'not_configured',
  `charges_enabled` TINYINT(1) NOT NULL DEFAULT 0,
  `payouts_enabled` TINYINT(1) NOT NULL DEFAULT 0,
  `details_submitted` TINYINT(1) NOT NULL DEFAULT 0,
  `capabilities_json` JSON DEFAULT NULL,
  `requirements_json` JSON DEFAULT NULL,
  `last_onboarding_url_created_at` TIMESTAMP NULL DEFAULT NULL,
  `last_sync_at` TIMESTAMP NULL DEFAULT NULL,
  `last_error_code` VARCHAR(120) DEFAULT NULL,
  `last_error_message` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_bopa_business_provider_mode` (`business_id`,`provider_code`,`mode`),
  KEY `idx_bopa_business_enabled` (`business_id`,`is_enabled`),
  CONSTRAINT `fk_bopa_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `service_variants`
  ADD COLUMN `online_payment_required` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_price_starting_from`;

ALTER TABLE `service_packages`
  ADD COLUMN `online_payment_required` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_broken`;

ALTER TABLE `class_events`
  ADD COLUMN `online_payment_required` TINYINT(1) NOT NULL DEFAULT 0 AFTER `currency`;

CREATE TABLE IF NOT EXISTS `online_booking_payments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `location_id` INT UNSIGNED NOT NULL,
  `booking_id` INT UNSIGNED DEFAULT NULL,
  `class_booking_id` INT UNSIGNED DEFAULT NULL,
  `provider_code` VARCHAR(32) NOT NULL,
  `provider_account_id` VARCHAR(191) DEFAULT NULL,
  `provider_checkout_id` VARCHAR(191) DEFAULT NULL,
  `provider_payment_id` VARCHAR(191) DEFAULT NULL,
  `provider_order_id` VARCHAR(191) DEFAULT NULL,
  `status` ENUM('pending','requires_action','paid','failed','cancelled','expired','refunded') NOT NULL DEFAULT 'pending',
  `amount_cents` INT UNSIGNED NOT NULL,
  `currency` VARCHAR(3) NOT NULL DEFAULT 'EUR',
  `checkout_url` TEXT DEFAULT NULL,
  `return_url` TEXT DEFAULT NULL,
  `cancel_url` TEXT DEFAULT NULL,
  `idempotency_key` VARCHAR(64) DEFAULT NULL,
  `expires_at` TIMESTAMP NULL DEFAULT NULL,
  `paid_at` TIMESTAMP NULL DEFAULT NULL,
  `failed_at` TIMESTAMP NULL DEFAULT NULL,
  `cancelled_at` TIMESTAMP NULL DEFAULT NULL,
  `refunded_at` TIMESTAMP NULL DEFAULT NULL,
  `payload_json` JSON DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_obp_business_status` (`business_id`,`status`),
  KEY `idx_obp_booking` (`booking_id`),
  KEY `idx_obp_class_booking` (`class_booking_id`),
  UNIQUE KEY `uk_obp_provider_checkout` (`provider_code`,`provider_checkout_id`),
  UNIQUE KEY `uk_obp_provider_payment` (`provider_code`,`provider_payment_id`),
  UNIQUE KEY `uk_obp_business_idempotency` (`business_id`,`idempotency_key`),
  CONSTRAINT `fk_obp_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_obp_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_obp_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_obp_class_booking` FOREIGN KEY (`class_booking_id`) REFERENCES `class_bookings` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `online_payment_provider_events` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `provider_code` VARCHAR(32) NOT NULL,
  `provider_event_id` VARCHAR(191) NOT NULL,
  `event_type` VARCHAR(191) NOT NULL,
  `business_id` INT UNSIGNED DEFAULT NULL,
  `online_booking_payment_id` BIGINT UNSIGNED DEFAULT NULL,
  `payload_json` JSON DEFAULT NULL,
  `processed_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_oppe_provider_event` (`provider_code`,`provider_event_id`),
  KEY `idx_oppe_business` (`business_id`),
  KEY `idx_oppe_payment` (`online_booking_payment_id`),
  CONSTRAINT `fk_oppe_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_oppe_payment` FOREIGN KEY (`online_booking_payment_id`) REFERENCES `online_booking_payments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `bookings`
  MODIFY `status` ENUM('pending','pending_payment','confirmed','completed','cancelled','no_show','replaced') NOT NULL DEFAULT 'confirmed';
