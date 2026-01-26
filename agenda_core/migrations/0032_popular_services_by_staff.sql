-- ============================================================================
-- 0032_popular_services_by_staff.sql
-- Modifica popular_services per calcolare per staff invece che per location
-- ============================================================================

-- Rimuove i dati esistenti e le constraint
DROP TABLE IF EXISTS popular_services;

-- Ricrea la tabella con staff_id invece di location_id
CREATE TABLE popular_services (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_id INT UNSIGNED NOT NULL,
    service_id INT UNSIGNED NOT NULL,
    `rank` TINYINT UNSIGNED NOT NULL COMMENT '1 = più prenotato, 5 = quinto',
    booking_count INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Numero prenotazioni negli ultimi 90 giorni',
    computed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_popular_services_staff_rank (staff_id, `rank`),
    UNIQUE KEY uk_popular_services_staff_service (staff_id, service_id),
    KEY idx_popular_services_staff (staff_id),
    KEY idx_popular_services_service (service_id),
    CONSTRAINT fk_popular_services_staff FOREIGN KEY (staff_id)
        REFERENCES staff(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_popular_services_service FOREIGN KEY (service_id)
        REFERENCES services(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_popular_services_rank CHECK (`rank` BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Top 5 most booked services per staff member, updated weekly';
