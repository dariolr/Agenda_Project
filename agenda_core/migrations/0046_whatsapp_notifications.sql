-- 0046_whatsapp_notifications.sql
-- WhatsApp notifications foundation (multi-tenant, consent, outbox, webhook log)

CREATE TABLE IF NOT EXISTS business_whatsapp_config (
  id CHAR(36) NOT NULL,
  business_id INT UNSIGNED NOT NULL,
  waba_id VARCHAR(64) NOT NULL,
  phone_number_id VARCHAR(64) NOT NULL,
  access_token_encrypted TEXT NOT NULL,
  token_expires_at TIMESTAMP NULL DEFAULT NULL,
  connected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('active','disabled','error') NOT NULL DEFAULT 'active',
  quality_rating VARCHAR(32) DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_business_whatsapp_config_business (business_id),
  KEY idx_business_whatsapp_config_status (status),
  CONSTRAINT fk_business_whatsapp_config_business FOREIGN KEY (business_id)
    REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS whatsapp_templates (
  id CHAR(36) NOT NULL,
  business_id INT UNSIGNED NOT NULL,
  template_name VARCHAR(128) NOT NULL,
  category ENUM('utility','authentication','marketing') NOT NULL DEFAULT 'utility',
  language_code VARCHAR(10) NOT NULL DEFAULT 'it',
  status ENUM('approved','pending','rejected') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_whatsapp_templates_business_name_lang (business_id, template_name, language_code),
  KEY idx_whatsapp_templates_status (status),
  CONSTRAINT fk_whatsapp_templates_business FOREIGN KEY (business_id)
    REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customer_consents (
  id CHAR(36) NOT NULL,
  customer_id INT UNSIGNED NOT NULL,
  business_id INT UNSIGNED NOT NULL,
  channel ENUM('whatsapp') NOT NULL DEFAULT 'whatsapp',
  opt_in TINYINT(1) NOT NULL DEFAULT 0,
  opt_in_at TIMESTAMP NULL DEFAULT NULL,
  source ENUM('web','app','whatsapp','paper') NOT NULL DEFAULT 'web',
  proof_reference VARCHAR(255) DEFAULT NULL,
  revoked_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_customer_consents_lookup (business_id, customer_id, channel),
  CONSTRAINT fk_customer_consents_business FOREIGN KEY (business_id)
    REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_customer_consents_customer FOREIGN KEY (customer_id)
    REFERENCES clients(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS whatsapp_notification_outbox (
  id CHAR(36) NOT NULL,
  business_id INT UNSIGNED NOT NULL,
  customer_id INT UNSIGNED NOT NULL,
  channel ENUM('whatsapp') NOT NULL DEFAULT 'whatsapp',
  event_type VARCHAR(64) NOT NULL,
  template_name VARCHAR(128) NOT NULL,
  payload_json JSON NOT NULL,
  status ENUM('queued','sent','delivered','read','failed') NOT NULL DEFAULT 'queued',
  provider_message_id VARCHAR(128) DEFAULT NULL,
  error_code VARCHAR(64) DEFAULT NULL,
  retry_count TINYINT UNSIGNED NOT NULL DEFAULT 0,
  next_retry_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_whatsapp_outbox_dispatch (status, next_retry_at, created_at),
  KEY idx_whatsapp_outbox_business (business_id),
  CONSTRAINT fk_whatsapp_outbox_business FOREIGN KEY (business_id)
    REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_whatsapp_outbox_customer FOREIGN KEY (customer_id)
    REFERENCES clients(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS whatsapp_message_log (
  id CHAR(36) NOT NULL,
  business_id INT UNSIGNED NOT NULL,
  customer_id INT UNSIGNED DEFAULT NULL,
  direction ENUM('outbound','inbound') NOT NULL,
  message_type VARCHAR(32) NOT NULL,
  content_snapshot TEXT,
  provider_message_id VARCHAR(128) DEFAULT NULL,
  delivery_status VARCHAR(32) DEFAULT NULL,
  timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_whatsapp_message_log_business_time (business_id, timestamp),
  KEY idx_whatsapp_message_log_provider (provider_message_id),
  CONSTRAINT fk_whatsapp_message_log_business FOREIGN KEY (business_id)
    REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_whatsapp_message_log_customer FOREIGN KEY (customer_id)
    REFERENCES clients(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
