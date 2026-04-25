-- 20260424_business_billing.sql
-- Billing multi-provider per business: configurazione, subscription runtime, eventi provider e pagamenti futuri.

CREATE TABLE IF NOT EXISTS business_billing_config (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL UNIQUE,
  billing_enabled TINYINT(1) NOT NULL DEFAULT 0,
  billing_mode ENUM('free','recurring','one_time','manual') NOT NULL DEFAULT 'free',
  billing_interval_unit ENUM('month','year') DEFAULT NULL,
  billing_interval_count INT UNSIGNED DEFAULT NULL,
  amount_cents INT UNSIGNED DEFAULT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
  provider_code VARCHAR(32) DEFAULT NULL,
  provider_price_reference VARCHAR(191) DEFAULT NULL,
  notes VARCHAR(255) DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_business_billing_config_business
    FOREIGN KEY (business_id) REFERENCES businesses(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS business_billing_subscription (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL UNIQUE,
  provider_code VARCHAR(32) DEFAULT NULL,
  provider_customer_id VARCHAR(191) DEFAULT NULL,
  provider_subscription_id VARCHAR(191) DEFAULT NULL,
  provider_price_reference VARCHAR(191) DEFAULT NULL,
  status ENUM('not_required','inactive','pending_checkout','active','past_due','unpaid','canceled','error') NOT NULL DEFAULT 'not_required',
  current_period_start TIMESTAMP NULL DEFAULT NULL,
  current_period_end TIMESTAMP NULL DEFAULT NULL,
  cancel_at_period_end TINYINT(1) NOT NULL DEFAULT 0,
  canceled_at TIMESTAMP NULL DEFAULT NULL,
  last_payment_at TIMESTAMP NULL DEFAULT NULL,
  last_payment_failed_at TIMESTAMP NULL DEFAULT NULL,
  last_checkout_session_id VARCHAR(191) DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_business_billing_subscription_provider_subscription (provider_code, provider_subscription_id),
  CONSTRAINT fk_business_billing_subscription_business
    FOREIGN KEY (business_id) REFERENCES businesses(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS billing_provider_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  provider_code VARCHAR(32) NOT NULL,
  provider_event_id VARCHAR(191) NOT NULL,
  event_type VARCHAR(120) NOT NULL,
  business_id INT UNSIGNED DEFAULT NULL,
  payload_json JSON NOT NULL,
  processed_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_billing_provider_event (provider_code, provider_event_id),
  KEY idx_billing_provider_events_business (business_id),
  KEY idx_billing_provider_events_type (event_type),
  KEY idx_billing_provider_events_processed_at (processed_at),
  CONSTRAINT fk_billing_provider_events_business
    FOREIGN KEY (business_id) REFERENCES businesses(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS business_billing_payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  provider_code VARCHAR(32) DEFAULT NULL,
  provider_payment_id VARCHAR(191) DEFAULT NULL,
  payment_type ENUM('one_time','recurring_invoice','manual') NOT NULL DEFAULT 'one_time',
  status ENUM('pending','paid','failed','canceled','refunded') NOT NULL DEFAULT 'pending',
  amount_cents INT UNSIGNED NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
  paid_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_business_billing_payments_business (business_id),
  KEY idx_business_billing_payments_provider_payment (provider_code, provider_payment_id),
  CONSTRAINT fk_business_billing_payments_business
    FOREIGN KEY (business_id) REFERENCES businesses(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
