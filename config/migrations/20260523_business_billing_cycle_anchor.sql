-- Aggiunge billing_cycle_anchor_at a business_billing_config
-- Idempotente: controlla information_schema prima di aggiungere

SET @col_exists = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'business_billing_config'
      AND COLUMN_NAME = 'billing_cycle_anchor_at'
);

SET @sql = IF(
    @col_exists = 0,
    'ALTER TABLE business_billing_config ADD COLUMN billing_cycle_anchor_at TIMESTAMP NULL DEFAULT NULL AFTER provider_price_reference',
    'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
