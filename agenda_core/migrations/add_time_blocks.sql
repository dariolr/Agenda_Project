-- ============================================================================
-- MIGRATION: time_blocks
-- Date: 2026-01-01
-- Description: Tabella per blocchi di indisponibilità (ferie, chiusure, ecc.)
-- ============================================================================

CREATE TABLE IF NOT EXISTS time_blocks (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    start_time DATETIME NOT NULL COMMENT 'Inizio blocco',
    end_time DATETIME NOT NULL COMMENT 'Fine blocco',
    is_all_day TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Blocco per tutto il giorno',
    reason VARCHAR(255) DEFAULT NULL COMMENT 'Motivo del blocco',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_time_blocks_business (business_id),
    KEY idx_time_blocks_location (location_id),
    KEY idx_time_blocks_dates (start_time, end_time),
    CONSTRAINT fk_time_blocks_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_time_blocks_location FOREIGN KEY (location_id) 
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Blocchi di indisponibilità (chiusure, ferie aziendali, ecc.)';

-- Tabella di join per associare staff ai blocchi
CREATE TABLE IF NOT EXISTS time_block_staff (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    time_block_id INT UNSIGNED NOT NULL,
    staff_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_block_staff (time_block_id, staff_id),
    KEY idx_tbs_block (time_block_id),
    KEY idx_tbs_staff (staff_id),
    CONSTRAINT fk_tbs_block FOREIGN KEY (time_block_id) 
        REFERENCES time_blocks(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_tbs_staff FOREIGN KEY (staff_id) 
        REFERENCES staff(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Associazione staff a blocchi di indisponibilità';
