-- Assegnazioni operative dei template WhatsApp per business e location.
-- Un template resta una definizione Meta; questa tabella dice quando usarlo.
-- Nota: nel delta live non aggiungiamo FK inline per evitare errori #1215
-- su ambienti dove le tabelle WhatsApp sono nate con tipi/engine storici.
-- Le ownership sono validate server-side; FULL_DATABASE_SCHEMA contiene i vincoli
-- per installazioni fresh coerenti.

ALTER TABLE `whatsapp_templates`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

CREATE TABLE IF NOT EXISTS `whatsapp_template_assignments` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED DEFAULT NULL,
  `location_scope_id` int UNSIGNED GENERATED ALWAYS AS (coalesce(`location_id`,0)) STORED,
  `message_type` enum('booking_confirmation','booking_reminder','booking_cancellation','booking_reschedule','class_booking_confirmation','class_booking_reminder','class_booking_cancellation','test') COLLATE utf8mb4_unicode_ci NOT NULL,
  `language_code` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `whatsapp_template_id` bigint UNSIGNED NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_wta_scope` (`business_id`,`location_scope_id`,`message_type`,`language_code`),
  KEY `idx_wta_lookup` (`business_id`,`location_id`,`message_type`,`language_code`,`is_active`),
  KEY `idx_wta_template` (`whatsapp_template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
