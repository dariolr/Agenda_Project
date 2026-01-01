-- ============================================================================
-- MIGRATION: staff_availability_exceptions
-- Date: 2026-01-01
-- Description: Tabella per eccezioni alla disponibilità settimanale dello staff
-- ============================================================================

CREATE TABLE IF NOT EXISTS staff_availability_exceptions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_id INT UNSIGNED NOT NULL,
    exception_date DATE NOT NULL COMMENT 'Data specifica dell eccezione',
    start_time TIME DEFAULT NULL COMMENT 'Inizio fascia oraria (NULL = tutto il giorno)',
    end_time TIME DEFAULT NULL COMMENT 'Fine fascia oraria (NULL = tutto il giorno)',
    exception_type ENUM('available', 'unavailable') NOT NULL DEFAULT 'unavailable'
        COMMENT 'available = aggiunge disponibilità, unavailable = rimuove disponibilità',
    reason_code VARCHAR(50) DEFAULT NULL 
        COMMENT 'Codice motivo: vacation, medical_visit, extra_shift, personal, training, meeting',
    reason VARCHAR(255) DEFAULT NULL COMMENT 'Motivo testuale libero',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_staff_exceptions_staff (staff_id),
    KEY idx_staff_exceptions_date (exception_date),
    KEY idx_staff_exceptions_staff_date (staff_id, exception_date),
    CONSTRAINT fk_staff_exceptions_staff FOREIGN KEY (staff_id) 
        REFERENCES staff(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Eccezioni alla disponibilità settimanale staff (ferie, permessi, turni extra)';
