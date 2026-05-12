-- 20260512_business_billing_checkout_handoffs.sql
-- Legacy checkout handoff table. Not used by the main billing Stripe flow.

CREATE TABLE IF NOT EXISTS business_billing_checkout_handoffs (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  business_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  provider_code VARCHAR(32) NOT NULL DEFAULT 'stripe',
  purpose ENUM('checkout','portal') NOT NULL,
  token_hash VARCHAR(64) NOT NULL,
  checkout_session_id VARCHAR(191) DEFAULT NULL,
  portal_session_id VARCHAR(191) DEFAULT NULL,
  target_url TEXT DEFAULT NULL,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uniq_business_billing_checkout_handoff_token (token_hash),
  KEY idx_business_billing_checkout_handoffs_business (business_id),
  KEY idx_business_billing_checkout_handoffs_user (user_id),
  KEY idx_business_billing_checkout_handoffs_expires_at (expires_at),
  KEY idx_business_billing_checkout_handoffs_used_at (used_at),
  CONSTRAINT fk_business_billing_checkout_handoffs_business
    FOREIGN KEY (business_id) REFERENCES businesses (id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_business_billing_checkout_handoffs_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
