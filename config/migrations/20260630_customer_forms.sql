-- Moduli "per-cliente" (raccolti una volta sola) accanto ai moduli "per-prenotazione".
-- Aggiunge il tipo di modulo a booking_forms e due tabelle separate per le risposte
-- ancorate al cliente (client_id) invece che alla prenotazione (booking_id).
-- Il flusso prenotazione resta invariato.

ALTER TABLE `booking_forms`
  ADD COLUMN `data_scope` ENUM('per_booking', 'per_client') NOT NULL DEFAULT 'per_booking' AFTER `internal_name`,
  ADD COLUMN `registration_only` TINYINT(1) NOT NULL DEFAULT 0 AFTER `data_scope`;

CREATE TABLE IF NOT EXISTS `customer_form_submissions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` INT UNSIGNED NOT NULL,
  `client_id` INT UNSIGNED NOT NULL,
  `form_id` INT UNSIGNED NOT NULL,
  `form_title_snapshot` VARCHAR(191) NOT NULL,
  `location_id` INT UNSIGNED NULL,
  `submitted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_customer_form_submission_client_form` (`client_id`, `form_id`),
  KEY `idx_customer_form_submissions_business_client` (`business_id`, `client_id`),
  KEY `idx_customer_form_submissions_form` (`form_id`),
  CONSTRAINT `fk_customer_form_submissions_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_customer_form_submissions_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_customer_form_submissions_form` FOREIGN KEY (`form_id`) REFERENCES `booking_forms` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_customer_form_submissions_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `customer_form_submission_answers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `submission_id` BIGINT UNSIGNED NOT NULL,
  `business_id` INT UNSIGNED NOT NULL,
  `client_id` INT UNSIGNED NOT NULL,
  `form_id` INT UNSIGNED NOT NULL,
  `field_id` INT UNSIGNED NOT NULL,
  `field_type_snapshot` VARCHAR(40) NOT NULL,
  `field_label_snapshot` VARCHAR(191) NOT NULL,
  `answer_text` TEXT NULL,
  `answer_json` JSON NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_customer_form_answers_submission` (`submission_id`),
  KEY `idx_customer_form_answers_business_client` (`business_id`, `client_id`),
  KEY `idx_customer_form_answers_field` (`field_id`),
  CONSTRAINT `fk_customer_form_answers_submission` FOREIGN KEY (`submission_id`) REFERENCES `customer_form_submissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_customer_form_answers_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_customer_form_answers_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_customer_form_answers_form` FOREIGN KEY (`form_id`) REFERENCES `booking_forms` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_customer_form_answers_field` FOREIGN KEY (`field_id`) REFERENCES `booking_form_fields` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
