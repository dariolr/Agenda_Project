-- Rinomina billing_cycle_anchor_at → activation_deadline_at in business_billing_config
-- Idempotente: controlla information_schema prima di procedere

SET @col_exists_old = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'business_billing_config'
      AND COLUMN_NAME = 'billing_cycle_anchor_at'
);

SET @col_exists_new = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'business_billing_config'
      AND COLUMN_NAME = 'activation_deadline_at'
);

-- Rinomina solo se billing_cycle_anchor_at esiste e activation_deadline_at non esiste ancora
SET @sql = IF(
    @col_exists_old = 1 AND @col_exists_new = 0,
    'ALTER TABLE business_billing_config CHANGE COLUMN billing_cycle_anchor_at activation_deadline_at TIMESTAMP NULL DEFAULT NULL',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
