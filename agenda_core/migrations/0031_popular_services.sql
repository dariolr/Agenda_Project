-- ============================================================================
-- 0031_popular_services.sql
-- Tabella per memorizzare i servizi più prenotati per location
-- Aggiornata settimanalmente dal worker compute-popular-services.php
-- ============================================================================

-- ----------------------------------------------------------------------------
-- popular_services: Top 5 servizi più prenotati per location
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS popular_services (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    location_id INT UNSIGNED NOT NULL,
    service_id INT UNSIGNED NOT NULL,
    `rank` TINYINT UNSIGNED NOT NULL COMMENT '1 = più prenotato, 5 = quinto',
    booking_count INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Numero prenotazioni negli ultimi 90 giorni',
    computed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_popular_services_location_rank (location_id, `rank`),
    UNIQUE KEY uk_popular_services_location_service (location_id, service_id),
    KEY idx_popular_services_location (location_id),
    KEY idx_popular_services_service (service_id),
    CONSTRAINT fk_popular_services_location FOREIGN KEY (location_id)
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_popular_services_service FOREIGN KEY (service_id)
        REFERENCES services(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_popular_services_rank CHECK (`rank` BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Top 5 most booked services per location, updated weekly';
