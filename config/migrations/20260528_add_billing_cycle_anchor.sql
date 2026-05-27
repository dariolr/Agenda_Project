-- Aggiunge billing_cycle_anchor_at a business_billing_config (idempotente)
SET @dbname = DATABASE();
SET @tblname = 'business_billing_config';
SET @colname = 'billing_cycle_anchor_at';

SET @add_col = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = @tblname AND COLUMN_NAME = @colname) = 0,
    CONCAT('ALTER TABLE `', @tblname, '` ADD COLUMN `', @colname, '` TIMESTAMP NULL DEFAULT NULL AFTER `activation_deadline_at`'),
    'SELECT 1'
);

PREPARE stmt FROM @add_col;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
