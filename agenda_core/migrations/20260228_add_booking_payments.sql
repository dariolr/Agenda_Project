CREATE TABLE `booking_payments` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `booking_id` int UNSIGNED NOT NULL,
  `client_id` int UNSIGNED NULL,
  `currency` char(3) NOT NULL DEFAULT 'EUR',
  `total_due_cents` int UNSIGNED NOT NULL DEFAULT 0,
  `note` text NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by_user_id` int UNSIGNED NULL,
  PRIMARY KEY (`id`),
  KEY `idx_booking_payments_booking_active` (`booking_id`, `is_active`),
  KEY `idx_booking_payments_business` (`business_id`),
  KEY `idx_booking_payments_location` (`location_id`),
  KEY `idx_booking_payments_client` (`client_id`),
  KEY `idx_booking_payments_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `booking_payment_lines` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `booking_payment_id` int UNSIGNED NOT NULL,
  `type` enum('cash','card','discount','voucher','other') NOT NULL,
  `amount_cents` int UNSIGNED NOT NULL DEFAULT 0,
  `meta_json` json NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by_user_id` int UNSIGNED NULL,
  PRIMARY KEY (`id`),
  KEY `idx_booking_payment_lines_payment` (`booking_payment_id`),
  KEY `idx_booking_payment_lines_type` (`type`),
  CONSTRAINT `fk_booking_payment_lines_payment`
    FOREIGN KEY (`booking_payment_id`) REFERENCES `booking_payments`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
