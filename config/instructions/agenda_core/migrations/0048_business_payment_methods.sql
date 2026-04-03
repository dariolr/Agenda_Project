-- 0048_business_payment_methods.sql
-- Introduce business-specific payment methods and open booking payment line type from enum to string code.

-- 1) New table: business payment methods
CREATE TABLE IF NOT EXISTS business_payment_methods (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  code VARCHAR(40) NOT NULL,
  name VARCHAR(100) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  icon_key VARCHAR(32) DEFAULT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  updated_by_user_id INT UNSIGNED DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_business_payment_method_code (business_id, code),
  KEY idx_business_payment_methods_business_active (business_id, is_active),
  CONSTRAINT fk_business_payment_methods_business
    FOREIGN KEY (business_id) REFERENCES businesses(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_business_payment_methods_updated_by
    FOREIGN KEY (updated_by_user_id) REFERENCES users(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2) Allow dynamic payment method codes in booking lines
-- Direct ALTER is phpMyAdmin-safe and idempotent in practice:
-- if already VARCHAR(40), MySQL keeps the same definition.
ALTER TABLE booking_payment_lines
  MODIFY COLUMN type VARCHAR(40) NOT NULL;

-- 3) Seed default methods for every business (idempotent)
INSERT INTO business_payment_methods (business_id, code, name, sort_order, icon_key, is_active)
SELECT b.id, 'cash', 'Contanti', 10, 'cash', 1
FROM businesses b
WHERE NOT EXISTS (
  SELECT 1
  FROM business_payment_methods bpm
  WHERE bpm.business_id = b.id
    AND bpm.code = 'cash'
);

INSERT INTO business_payment_methods (business_id, code, name, sort_order, icon_key, is_active)
SELECT b.id, 'card', 'Carte di Pagamento/Bancomat', 20, 'card', 1
FROM businesses b
WHERE NOT EXISTS (
  SELECT 1
  FROM business_payment_methods bpm
  WHERE bpm.business_id = b.id
    AND bpm.code = 'card'
);

INSERT INTO business_payment_methods (business_id, code, name, sort_order, icon_key, is_active)
SELECT b.id, 'voucher', 'Buono/Pacchetto', 30, 'voucher', 1
FROM businesses b
WHERE NOT EXISTS (
  SELECT 1
  FROM business_payment_methods bpm
  WHERE bpm.business_id = b.id
    AND bpm.code = 'voucher'
);

INSERT INTO business_payment_methods (business_id, code, name, sort_order, icon_key, is_active)
SELECT b.id, 'other', 'Altro', 40, 'other', 1
FROM businesses b
WHERE NOT EXISTS (
  SELECT 1
  FROM business_payment_methods bpm
  WHERE bpm.business_id = b.id
    AND bpm.code = 'other'
);
