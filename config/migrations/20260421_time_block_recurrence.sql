-- ============================================================
-- Migration: 20260421_time_block_recurrence
-- Aggiunge supporto per blocchi di non disponibilità ripetuti
-- ============================================================

-- 1. Tabella per le regole di ricorrenza dei blocchi
CREATE TABLE `time_block_recurrence_rules` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` int UNSIGNED NOT NULL,
  `frequency` enum('daily','weekly','monthly','custom') COLLATE utf8mb4_unicode_ci NOT NULL,
  `interval_value` int UNSIGNED NOT NULL DEFAULT '1',
  `max_occurrences` int UNSIGNED DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `days_of_week` json DEFAULT NULL,
  `day_of_month` int UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_tbrr_business_id` (`business_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Regole di ricorrenza per blocchi di non disponibilità';

-- 2. Campi di ricorrenza su time_blocks
ALTER TABLE `time_blocks`
  ADD COLUMN `recurrence_rule_id` int UNSIGNED DEFAULT NULL
    COMMENT 'FK a time_block_recurrence_rules; NULL = blocco singolo'
    AFTER `allow_online_booking_during_block`,
  ADD COLUMN `recurrence_index` int UNSIGNED DEFAULT NULL
    COMMENT 'Posizione 0-based nella serie (0 = prima occorrenza)'
    AFTER `recurrence_rule_id`,
  ADD COLUMN `is_recurrence_parent` tinyint(1) NOT NULL DEFAULT '0'
    COMMENT '1 per il blocco padre della serie (recurrence_index = 0)'
    AFTER `recurrence_index`,
  ADD KEY `idx_tb_recurrence_rule_id` (`recurrence_rule_id`);
