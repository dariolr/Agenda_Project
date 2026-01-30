-- ============================================================================
-- Migration 0035: Role Scope per Location
-- Description: Aggiunge scope_type a business_users per limitare accesso per location
-- Date: 2026-01-30
-- ============================================================================

-- 1. Aggiunge scope_type a business_users
ALTER TABLE business_users
ADD COLUMN scope_type ENUM('business','locations') NOT NULL DEFAULT 'business'
AFTER role;

-- 2. Nuova tabella per mapping utente -> location (quando scope=locations)
CREATE TABLE IF NOT EXISTS business_user_locations (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_user_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_business_user_location (business_user_id, location_id),
    KEY idx_bul_location (location_id),
    CONSTRAINT fk_bul_business_user FOREIGN KEY (business_user_id)
        REFERENCES business_users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bul_location FOREIGN KEY (location_id)
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Location assegnate a utenti con scope_type=locations';

-- 3. Aggiunge scope_type a business_invitations
ALTER TABLE business_invitations
ADD COLUMN scope_type ENUM('business','locations') NOT NULL DEFAULT 'business'
AFTER role;

-- 4. Nuova tabella per mapping invito -> location (quando scope=locations)
CREATE TABLE IF NOT EXISTS business_invitation_locations (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    invitation_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_invitation_location (invitation_id, location_id),
    KEY idx_bil_location (location_id),
    CONSTRAINT fk_bil_invitation FOREIGN KEY (invitation_id)
        REFERENCES business_invitations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bil_location FOREIGN KEY (location_id)
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Location assegnate a inviti con scope_type=locations';

-- 5. Backfill: tutti i record esistenti hanno già scope_type='business' (DEFAULT)
-- Non serve query esplicita per backfill

-- ============================================================================
-- Fine migrazione
-- ============================================================================
