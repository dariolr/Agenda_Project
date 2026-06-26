-- Visibilità moduli a "regole": OR tra regole, AND tra condizioni della stessa regola.
-- Sostituisce il modello a singola assegnazione (booking_form_assignments).

CREATE TABLE IF NOT EXISTS `booking_form_rules` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `form_id` INT UNSIGNED NOT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_booking_form_rules_form_active_sort` (`form_id`, `is_active`, `sort_order`),
  KEY `idx_booking_form_rules_business` (`business_id`),
  CONSTRAINT `fk_booking_form_rules_form` FOREIGN KEY (`form_id`) REFERENCES `booking_forms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_booking_form_rules_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `booking_form_rule_conditions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `rule_id` INT UNSIGNED NOT NULL,
  `form_id` INT UNSIGNED NOT NULL,
  `business_id` INT UNSIGNED NOT NULL,
  `scope_type` VARCHAR(40) NOT NULL,
  `scope_id` INT UNSIGNED NULL,
  `scope_key` VARCHAR(80) GENERATED ALWAYS AS (CONCAT(`scope_type`, ':', COALESCE(CAST(`scope_id` AS CHAR), 'business'))) STORED,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_booking_form_rule_condition_scope` (`rule_id`, `scope_key`),
  KEY `idx_booking_form_rule_conditions_rule` (`rule_id`),
  KEY `idx_booking_form_rule_conditions_business_scope` (`business_id`, `scope_type`, `scope_id`),
  CONSTRAINT `fk_booking_form_rule_conditions_rule` FOREIGN KEY (`rule_id`) REFERENCES `booking_form_rules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_booking_form_rule_conditions_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Migrazione dati: ogni assegnazione esistente diventa una regola autonoma
-- con una sola condizione (comportamento invariato).
ALTER TABLE `booking_form_rules` ADD COLUMN `legacy_assignment_id` INT UNSIGNED NULL;

INSERT INTO `booking_form_rules` (`business_id`, `form_id`, `is_active`, `sort_order`, `legacy_assignment_id`)
SELECT `business_id`, `form_id`, `is_active`, `id`, `id`
FROM `booking_form_assignments`;

INSERT INTO `booking_form_rule_conditions` (`rule_id`, `form_id`, `business_id`, `scope_type`, `scope_id`)
SELECT r.`id`, a.`form_id`, a.`business_id`, a.`scope_type`, a.`scope_id`
FROM `booking_form_assignments` a
INNER JOIN `booking_form_rules` r ON r.`legacy_assignment_id` = a.`id`;

ALTER TABLE `booking_form_rules` DROP COLUMN `legacy_assignment_id`;

DROP TABLE `booking_form_assignments`;
