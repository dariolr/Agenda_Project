-- 0042_whatsapp_integration.sql
-- WhatsApp Business Platform integration support for agenda_core
-- Date: 2026-03-24

START TRANSACTION;

CREATE TABLE IF NOT EXISTS whatsapp_business_config (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  waba_id VARCHAR(100) NOT NULL,
  phone_number_id VARCHAR(100) NOT NULL,
  display_phone_number VARCHAR(50) NULL,
  access_token_encrypted TEXT NOT NULL,
  status ENUM('active', 'inactive', 'pending', 'error') NOT NULL DEFAULT 'pending',
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_bwc_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  UNIQUE KEY uq_bwc_business_phone (business_id, phone_number_id),
  KEY idx_bwc_business_default (business_id, is_default),
  KEY idx_bwc_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS whatsapp_location_mapping (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  location_id INT UNSIGNED NOT NULL,
  whatsapp_config_id INT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_lwm_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  CONSTRAINT fk_lwm_location FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
  CONSTRAINT fk_lwm_config FOREIGN KEY (whatsapp_config_id) REFERENCES whatsapp_business_config(id) ON DELETE CASCADE,
  UNIQUE KEY uq_lwm_location (location_id),
  KEY idx_lwm_business (business_id),
  KEY idx_lwm_config (whatsapp_config_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS whatsapp_outbox (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  booking_id INT UNSIGNED NULL,
  location_id INT UNSIGNED NULL,
  whatsapp_config_id INT UNSIGNED NULL,
  recipient_phone VARCHAR(50) NOT NULL,
  template_name VARCHAR(120) NOT NULL,
  template_language VARCHAR(10) NOT NULL DEFAULT 'it',
  template_payload JSON NULL,
  status ENUM('queued', 'sent', 'delivered', 'read', 'failed') NOT NULL DEFAULT 'queued',
  attempts INT UNSIGNED NOT NULL DEFAULT 0,
  max_attempts INT UNSIGNED NOT NULL DEFAULT 3,
  provider_message_id VARCHAR(120) NULL,
  error_message TEXT NULL,
  scheduled_at DATETIME NULL,
  last_attempt_at DATETIME NULL,
  sent_at DATETIME NULL,
  delivered_at DATETIME NULL,
  read_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_wo_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  CONSTRAINT fk_wo_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL,
  CONSTRAINT fk_wo_location FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL,
  CONSTRAINT fk_wo_config FOREIGN KEY (whatsapp_config_id) REFERENCES whatsapp_business_config(id) ON DELETE SET NULL,
  KEY idx_wo_business_status (business_id, status),
  KEY idx_wo_schedule (status, scheduled_at),
  UNIQUE KEY uq_wo_provider_msg (provider_message_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS whatsapp_webhook_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  event_id VARCHAR(191) NOT NULL,
  business_id INT UNSIGNED NOT NULL,
  payload_json JSON NOT NULL,
  processed_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_wwe_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  UNIQUE KEY uq_wwe_event_id (event_id),
  KEY idx_wwe_business (business_id),
  KEY idx_wwe_processed (processed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS whatsapp_client_optins (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  client_id INT UNSIGNED NOT NULL,
  opt_in TINYINT(1) NOT NULL DEFAULT 0,
  source VARCHAR(100) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_cwo_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  CONSTRAINT fk_cwo_client FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
  UNIQUE KEY uq_cwo_business_client (business_id, client_id),
  KEY idx_cwo_optin (business_id, opt_in)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS whatsapp_templates (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  template_name VARCHAR(120) NOT NULL,
  category ENUM('marketing', 'utility', 'authentication', 'service') NOT NULL DEFAULT 'utility',
  status ENUM('approved', 'pending', 'rejected', 'paused') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_wt_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  UNIQUE KEY uq_wt_business_name (business_id, template_name),
  KEY idx_wt_business_status (business_id, status),
  KEY idx_wt_business_category (business_id, category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
