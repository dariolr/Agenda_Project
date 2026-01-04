-- =============================================================================
-- Migration: 0022_staff_planning.sql
-- Descrizione: Crea tabelle per staff planning settimanale/bisettimanale
-- Data: 2026-01-04
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Tabella: staff_planning
-- Rappresenta una pianificazione settimanale o bisettimanale di uno staff.
-- Intervallo di validità [valid_from, valid_to] chiuso-chiuso.
-- valid_to NULL significa "senza scadenza".
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS staff_planning (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_id INT UNSIGNED NOT NULL,
    type ENUM('weekly', 'biweekly') NOT NULL DEFAULT 'weekly',
    valid_from DATE NOT NULL,
    valid_to DATE NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    
    -- FK verso staff
    CONSTRAINT fk_staff_planning_staff
        FOREIGN KEY (staff_id) REFERENCES staff(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    -- Indice per ricerche per staff
    INDEX idx_staff_planning_staff_id (staff_id),
    
    -- Indice per ricerche di validità (query: valid_from <= D AND (valid_to IS NULL OR valid_to >= D))
    INDEX idx_staff_planning_validity (staff_id, valid_from, valid_to),
    
    -- Indice per valid_from (ordinamento cronologico)
    INDEX idx_staff_planning_valid_from (valid_from)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -----------------------------------------------------------------------------
-- Tabella: staff_planning_week_template
-- Template settimanale con slot per ogni giorno.
-- Per planning weekly: solo record con week_label='A'.
-- Per planning biweekly: record con week_label='A' e 'B'.
-- day_of_week: 1=Monday, 7=Sunday (ISO 8601).
-- slots: JSON array di interi (indici slot, es. [36,37,38,39] = 09:00-10:00 con slot 15min).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS staff_planning_week_template (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_planning_id INT UNSIGNED NOT NULL,
    week_label ENUM('A', 'B') NOT NULL DEFAULT 'A',
    day_of_week TINYINT UNSIGNED NOT NULL,
    slots JSON NOT NULL,
    
    PRIMARY KEY (id),
    
    -- FK verso staff_planning
    CONSTRAINT fk_staff_planning_week_template_planning
        FOREIGN KEY (staff_planning_id) REFERENCES staff_planning(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    -- Unicità: un solo record per (planning, settimana, giorno)
    UNIQUE KEY uk_planning_week_day (staff_planning_id, week_label, day_of_week),
    
    -- Indice per ricerche per planning
    INDEX idx_week_template_planning_id (staff_planning_id),
    
    -- Vincolo: day_of_week deve essere 1-7
    CONSTRAINT chk_planning_template_day_of_week CHECK (day_of_week >= 1 AND day_of_week <= 7)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
