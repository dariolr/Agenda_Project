-- CRM Pro phase 1 rollback
-- ATTENZIONE: perdita dati CRM introdotti in phase 1.
-- Compatibile con MySQL/MariaDB senza DROP COLUMN IF EXISTS / DROP INDEX IF EXISTS.

DROP TABLE IF EXISTS `client_kpis`;
DROP TABLE IF EXISTS `client_segments`;
DROP TABLE IF EXISTS `client_merge_map`;
DROP TABLE IF EXISTS `client_loyalty_ledger`;
DROP TABLE IF EXISTS `client_tasks`;
DROP TABLE IF EXISTS `client_events`;
DROP TABLE IF EXISTS `client_tag_links`;
DROP TABLE IF EXISTS `client_tags`;
DROP TABLE IF EXISTS `client_consents`;
DROP TABLE IF EXISTS `client_addresses`;
DROP TABLE IF EXISTS `client_contacts`;

SET @db := DATABASE();

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'status'
    ),
    'ALTER TABLE `clients` DROP COLUMN `status`',
    'SELECT 1'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'source'
    ),
    'ALTER TABLE `clients` DROP COLUMN `source`',
    'SELECT 1'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'company_name'
    ),
    'ALTER TABLE `clients` DROP COLUMN `company_name`',
    'SELECT 1'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'vat_number'
    ),
    'ALTER TABLE `clients` DROP COLUMN `vat_number`',
    'SELECT 1'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'address_city'
    ),
    'ALTER TABLE `clients` DROP COLUMN `address_city`',
    'SELECT 1'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'deleted_at'
    ),
    'ALTER TABLE `clients` DROP COLUMN `deleted_at`',
    'SELECT 1'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'tags'
    ),
    'ALTER TABLE `clients` DROP COLUMN `tags`',
    'SELECT 1'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.STATISTICS
      WHERE TABLE_SCHEMA = @db
        AND TABLE_NAME = 'clients'
        AND INDEX_NAME = 'idx_clients_business_archived_last_visit'
    ),
    'DROP INDEX `idx_clients_business_archived_last_visit` ON `clients`',
    'SELECT 1'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
