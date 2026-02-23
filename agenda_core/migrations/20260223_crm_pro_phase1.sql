-- CRM Pro phase 1 (forward migration)
-- Idempotente anche su MySQL/MariaDB che non supportano
-- ADD COLUMN IF NOT EXISTS / CREATE INDEX IF NOT EXISTS.

SET @db := DATABASE();

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'status'
    ),
    'SELECT 1',
    'ALTER TABLE `clients` ADD COLUMN `status` ENUM(''lead'',''active'',''inactive'',''lost'') NOT NULL DEFAULT ''active'' AFTER `is_archived`'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'source'
    ),
    'SELECT 1',
    'ALTER TABLE `clients` ADD COLUMN `source` VARCHAR(120) NULL AFTER `status`'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'company_name'
    ),
    'SELECT 1',
    'ALTER TABLE `clients` ADD COLUMN `company_name` VARCHAR(255) NULL AFTER `source`'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'vat_number'
    ),
    'SELECT 1',
    'ALTER TABLE `clients` ADD COLUMN `vat_number` VARCHAR(64) NULL AFTER `company_name`'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'address_city'
    ),
    'SELECT 1',
    'ALTER TABLE `clients` ADD COLUMN `address_city` VARCHAR(100) NULL AFTER `city`'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'deleted_at'
    ),
    'SELECT 1',
    'ALTER TABLE `clients` ADD COLUMN `deleted_at` DATETIME NULL AFTER `updated_at`'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'clients' AND COLUMN_NAME = 'tags'
    ),
    'SELECT 1',
    'ALTER TABLE `clients` ADD COLUMN `tags` JSON NULL AFTER `last_visit`'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

CREATE TABLE IF NOT EXISTS `client_contacts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `client_id` INT UNSIGNED NOT NULL,
  `type` ENUM('email','phone','whatsapp','instagram','facebook','other') NOT NULL,
  `value` VARCHAR(255) NOT NULL,
  `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
  `is_verified` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_client_contacts_business_type_value` (`business_id`,`type`,`value`),
  KEY `idx_client_contacts_business_client` (`business_id`,`client_id`),
  KEY `idx_client_contacts_business_type_value` (`business_id`,`type`,`value`),
  CONSTRAINT `fk_client_contacts_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `client_addresses` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `client_id` INT UNSIGNED NOT NULL,
  `label` VARCHAR(80) NULL,
  `line1` VARCHAR(255) NULL,
  `line2` VARCHAR(255) NULL,
  `city` VARCHAR(120) NULL,
  `province` VARCHAR(120) NULL,
  `postal_code` VARCHAR(40) NULL,
  `country` VARCHAR(100) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_client_addresses_business_client` (`business_id`,`client_id`),
  CONSTRAINT `fk_client_addresses_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `client_consents` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `client_id` INT UNSIGNED NOT NULL,
  `marketing_opt_in` TINYINT(1) NOT NULL DEFAULT 0,
  `profiling_opt_in` TINYINT(1) NOT NULL DEFAULT 0,
  `preferred_channel` ENUM('whatsapp','sms','email','phone','none') NOT NULL DEFAULT 'none',
  `updated_by_user_id` INT UNSIGNED NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `source` VARCHAR(120) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_client_consents_business_client` (`business_id`,`client_id`),
  KEY `idx_client_consents_business_client` (`business_id`,`client_id`),
  CONSTRAINT `fk_client_consents_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `client_tags` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `name_ci` VARCHAR(120) GENERATED ALWAYS AS (LOWER(`name`)) STORED,
  `color` VARCHAR(32) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_client_tags_business_name_ci` (`business_id`,`name_ci`),
  KEY `idx_client_tags_business` (`business_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `client_tag_links` (
  `business_id` INT UNSIGNED NOT NULL,
  `client_id` INT UNSIGNED NOT NULL,
  `tag_id` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uniq_client_tag_links` (`business_id`,`client_id`,`tag_id`),
  KEY `idx_client_tag_links_client` (`client_id`),
  KEY `idx_client_tag_links_tag` (`tag_id`),
  CONSTRAINT `fk_client_tag_links_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_client_tag_links_tag` FOREIGN KEY (`tag_id`) REFERENCES `client_tags` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `client_events` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `client_id` INT UNSIGNED NOT NULL,
  `event_type` ENUM('booking_created','booking_cancelled','booking_no_show','payment','note','task','message','campaign','merge','gdpr_export','gdpr_delete') NOT NULL,
  `payload` JSON NULL,
  `occurred_at` DATETIME NOT NULL,
  `created_by_user_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_client_events_business_client_occurred` (`business_id`,`client_id`,`occurred_at`),
  CONSTRAINT `fk_client_events_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `client_tasks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `client_id` INT UNSIGNED NOT NULL,
  `assigned_staff_id` INT UNSIGNED NULL,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `due_at` DATETIME NULL,
  `status` ENUM('open','done','cancelled') NOT NULL DEFAULT 'open',
  `priority` ENUM('low','medium','high') NOT NULL DEFAULT 'medium',
  `created_by_user_id` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `completed_at` DATETIME NULL,
  PRIMARY KEY (`id`),
  KEY `idx_client_tasks_business_status_due` (`business_id`,`status`,`due_at`),
  KEY `idx_client_tasks_business_client` (`business_id`,`client_id`),
  CONSTRAINT `fk_client_tasks_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `client_loyalty_ledger` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `client_id` INT UNSIGNED NOT NULL,
  `delta_points` INT NOT NULL,
  `reason` ENUM('manual','booking','promotion','refund','adjustment') NOT NULL,
  `ref_type` ENUM('booking','appointment','payment','other') NULL,
  `ref_id` INT NULL,
  `created_by_user_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_client_loyalty_ledger_business_client` (`business_id`,`client_id`),
  CONSTRAINT `fk_client_loyalty_ledger_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `client_merge_map` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `source_client_id` INT UNSIGNED NOT NULL,
  `target_client_id` INT UNSIGNED NOT NULL,
  `merged_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `merged_by_user_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_client_merge_source` (`business_id`,`source_client_id`),
  KEY `idx_client_merge_target` (`business_id`,`target_client_id`),
  CONSTRAINT `fk_client_merge_source_client` FOREIGN KEY (`source_client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_client_merge_target_client` FOREIGN KEY (`target_client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `client_segments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `filters_json` JSON NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_client_segments_business` (`business_id`),
  UNIQUE KEY `uniq_client_segments_business_name` (`business_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `client_kpis` (
  `business_id` INT UNSIGNED NOT NULL,
  `client_id` INT UNSIGNED NOT NULL,
  `visits_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `total_spent` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `avg_ticket` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `last_visit` DATETIME NULL,
  `no_show_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `rfm_segment` VARCHAR(16) NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`business_id`,`client_id`),
  KEY `idx_client_kpis_last_visit` (`business_id`,`last_visit`),
  CONSTRAINT `fk_client_kpis_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @q := (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM information_schema.STATISTICS
      WHERE TABLE_SCHEMA = @db
        AND TABLE_NAME = 'clients'
        AND INDEX_NAME = 'idx_clients_business_archived_last_visit'
    ),
    'SELECT 1',
    'CREATE INDEX `idx_clients_business_archived_last_visit` ON `clients` (`business_id`, `is_archived`, `last_visit`)'
  )
);
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

-- Bootstrap tags from legacy JSON/list column when present.
-- This step is idempotent and safe if tags are null/empty.
INSERT INTO `client_tags` (`business_id`, `name`)
SELECT DISTINCT c.business_id, jt.tag_name
FROM clients c
JOIN JSON_TABLE(
  CASE
    WHEN JSON_VALID(c.tags) THEN c.tags
    ELSE JSON_ARRAY()
  END,
  '$[*]' COLUMNS (`tag_name` VARCHAR(120) PATH '$')
) jt
WHERE c.tags IS NOT NULL
  AND jt.tag_name IS NOT NULL
  AND jt.tag_name <> ''
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT IGNORE INTO `client_tag_links` (`business_id`, `client_id`, `tag_id`)
SELECT c.business_id, c.id, t.id
FROM clients c
JOIN JSON_TABLE(
  CASE
    WHEN JSON_VALID(c.tags) THEN c.tags
    ELSE JSON_ARRAY()
  END,
  '$[*]' COLUMNS (`tag_name` VARCHAR(120) PATH '$')
) jt
  ON 1 = 1
JOIN client_tags t
  ON t.business_id = c.business_id
 AND t.name_ci = LOWER(jt.tag_name)
WHERE c.tags IS NOT NULL
  AND jt.tag_name IS NOT NULL
  AND jt.tag_name <> '';
