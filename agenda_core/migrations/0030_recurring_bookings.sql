-- =============================================================================
-- Migration: 0030_recurring_bookings.sql
-- Description: Aggiunge supporto per prenotazioni ricorrenti
-- Date: 2026-01-23
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tabella booking_recurrence_rules
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS booking_recurrence_rules (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    
    -- Pattern ricorrenza
    frequency ENUM('daily', 'weekly', 'monthly', 'custom') NOT NULL,
    interval_value INT UNSIGNED NOT NULL DEFAULT 1 
        COMMENT 'Ogni X giorni/settimane/mesi',
    
    -- Limiti
    max_occurrences INT UNSIGNED DEFAULT NULL 
        COMMENT 'Numero massimo di ripetizioni (NULL = infinito)',
    end_date DATE DEFAULT NULL 
        COMMENT 'Data fine ricorrenza (NULL = usa max_occurrences)',
    
    -- Gestione conflitti
    conflict_strategy ENUM('skip', 'force') NOT NULL DEFAULT 'skip'
        COMMENT 'skip = salta date con conflitto, force = crea comunque con sovrapposizione',
    
    -- Opzioni avanzate (per estensioni future)
    days_of_week JSON DEFAULT NULL 
        COMMENT 'Per weekly multi-day: [1,3,5] = Lun,Mer,Ven',
    day_of_month INT UNSIGNED DEFAULT NULL 
        COMMENT 'Per monthly: giorno del mese (1-31)',
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_recurrence_business (business_id),
    CONSTRAINT fk_recurrence_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Regole di ricorrenza per prenotazioni ripetute';

-- -----------------------------------------------------------------------------
-- 2. Estensione tabella bookings
-- -----------------------------------------------------------------------------
ALTER TABLE bookings 
ADD COLUMN recurrence_rule_id INT UNSIGNED DEFAULT NULL 
    COMMENT 'FK a booking_recurrence_rules se ricorrente' AFTER status,
ADD COLUMN recurrence_index INT UNSIGNED DEFAULT NULL 
    COMMENT 'Indice occorrenza nella serie (0 = prima, 1 = seconda, ...)' AFTER recurrence_rule_id,
ADD COLUMN is_recurrence_parent TINYINT(1) NOT NULL DEFAULT 0 
    COMMENT 'True se è la prenotazione madre della serie' AFTER recurrence_index,
ADD COLUMN has_conflict TINYINT(1) NOT NULL DEFAULT 0
    COMMENT 'True se creata con conflict_strategy=force nonostante sovrapposizione' AFTER is_recurrence_parent;

-- Indici per query efficienti
ALTER TABLE bookings
ADD KEY idx_bookings_recurrence (recurrence_rule_id),
ADD KEY idx_bookings_recurrence_parent (recurrence_rule_id, is_recurrence_parent);

-- Foreign key
ALTER TABLE bookings
ADD CONSTRAINT fk_bookings_recurrence FOREIGN KEY (recurrence_rule_id) 
    REFERENCES booking_recurrence_rules(id) ON DELETE SET NULL;

-- =============================================================================
-- Rollback (da eseguire manualmente se necessario)
-- =============================================================================
-- ALTER TABLE bookings DROP FOREIGN KEY fk_bookings_recurrence;
-- ALTER TABLE bookings DROP KEY idx_bookings_recurrence_parent;
-- ALTER TABLE bookings DROP KEY idx_bookings_recurrence;
-- ALTER TABLE bookings DROP COLUMN has_conflict;
-- ALTER TABLE bookings DROP COLUMN is_recurrence_parent;
-- ALTER TABLE bookings DROP COLUMN recurrence_index;
-- ALTER TABLE bookings DROP COLUMN recurrence_rule_id;
-- DROP TABLE IF EXISTS booking_recurrence_rules;
