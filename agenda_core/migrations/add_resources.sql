-- ============================================================================
-- MIGRATION: resources
-- Date: 2026-01-01
-- Description: Tabella per risorse/attrezzature (cabine, postazioni, ecc.)
-- ============================================================================

CREATE TABLE IF NOT EXISTS resources (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    location_id INT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL COMMENT 'Nome risorsa (es. Cabina Relax 1)',
    type VARCHAR(50) DEFAULT NULL COMMENT 'Tipo: room, station, equipment, other',
    quantity INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Quantità disponibili',
    note TEXT DEFAULT NULL COMMENT 'Note aggiuntive',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    sort_order INT UNSIGNED NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_resources_location (location_id),
    KEY idx_resources_active (is_active),
    CONSTRAINT fk_resources_location FOREIGN KEY (location_id) 
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Risorse/attrezzature per sede (cabine, postazioni, equipment)';

-- Tabella per i requisiti di risorse per service_variant
CREATE TABLE IF NOT EXISTS service_variant_resource_requirements (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    service_variant_id INT UNSIGNED NOT NULL,
    resource_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Quantità richiesta della risorsa',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_variant_resource (service_variant_id, resource_id),
    KEY idx_svrr_variant (service_variant_id),
    KEY idx_svrr_resource (resource_id),
    CONSTRAINT fk_svrr_variant FOREIGN KEY (service_variant_id) 
        REFERENCES service_variants(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_svrr_resource FOREIGN KEY (resource_id) 
        REFERENCES resources(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Requisiti di risorse per ogni variante servizio';
