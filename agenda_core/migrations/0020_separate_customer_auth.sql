-- ============================================================================
-- MIGRATION: Separate Customer Authentication from Users
-- Date: 2026-01-02
-- Description: Adds password_hash to clients table for customer self-service auth
--              Keeps users table for operators/admin only
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1: Add authentication columns to clients table
-- ----------------------------------------------------------------------------
ALTER TABLE clients
    ADD COLUMN password_hash VARCHAR(255) DEFAULT NULL 
        COMMENT 'bcrypt hash for customer self-service login' AFTER user_id,
    ADD COLUMN email_verified_at TIMESTAMP NULL DEFAULT NULL 
        COMMENT 'When email was verified' AFTER password_hash;

-- ----------------------------------------------------------------------------
-- STEP 2: Create client_sessions table (parallel to auth_sessions)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS client_sessions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id INT UNSIGNED NOT NULL,
    refresh_token_hash VARCHAR(64) NOT NULL COMMENT 'SHA-256 hex of refresh token',
    user_agent VARCHAR(500) DEFAULT NULL,
    ip_address VARCHAR(45) DEFAULT NULL,
    expires_at TIMESTAMP NOT NULL,
    last_used_at TIMESTAMP NULL DEFAULT NULL,
    revoked_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_client_sessions_token (refresh_token_hash),
    KEY idx_client_sessions_client (client_id),
    KEY idx_client_sessions_expires (expires_at),
    CONSTRAINT fk_client_sessions_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- STEP 3: Create client_password_reset_tokens table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS client_password_reset_tokens (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    client_id INT UNSIGNED NOT NULL,
    token_hash VARCHAR(64) NOT NULL COMMENT 'SHA-256 hex of reset token',
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_client_password_reset_token (token_hash),
    KEY idx_client_password_reset_client (client_id),
    KEY idx_client_password_reset_expires (expires_at),
    CONSTRAINT fk_client_password_reset_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- STEP 4: Migrate existing customer data from users to clients
-- This copies password_hash from users to clients where:
-- - client has user_id linked
-- - user is NOT in business_users (i.e., NOT an operator/admin)
-- ----------------------------------------------------------------------------
UPDATE clients c
INNER JOIN users u ON c.user_id = u.id
SET c.password_hash = u.password_hash,
    c.email_verified_at = u.email_verified_at
WHERE c.user_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM business_users bu WHERE bu.user_id = u.id);

-- ----------------------------------------------------------------------------
-- STEP 5: Migrate client sessions from auth_sessions to client_sessions
-- Only for users that are pure customers (not in business_users)
-- ----------------------------------------------------------------------------
INSERT INTO client_sessions (client_id, refresh_token_hash, user_agent, ip_address, expires_at, last_used_at, revoked_at, created_at)
SELECT c.id, s.refresh_token_hash, s.user_agent, s.ip_address, s.expires_at, s.last_used_at, s.revoked_at, s.created_at
FROM auth_sessions s
INNER JOIN clients c ON c.user_id = s.user_id
WHERE NOT EXISTS (SELECT 1 FROM business_users bu WHERE bu.user_id = s.user_id);

-- ----------------------------------------------------------------------------
-- STEP 6: Delete migrated sessions from auth_sessions
-- Only sessions for pure customers (not operators)
-- ----------------------------------------------------------------------------
DELETE s FROM auth_sessions s
INNER JOIN clients c ON c.user_id = s.user_id
WHERE NOT EXISTS (SELECT 1 FROM business_users bu WHERE bu.user_id = s.user_id);

-- ----------------------------------------------------------------------------
-- STEP 7: Delete pure customer users from users table
-- Users that:
-- - Are NOT in business_users (not operators)
-- - ARE linked to a client record
-- ----------------------------------------------------------------------------
DELETE u FROM users u
INNER JOIN clients c ON c.user_id = u.id
WHERE NOT EXISTS (SELECT 1 FROM business_users bu WHERE bu.user_id = u.id);

-- ----------------------------------------------------------------------------
-- STEP 8: Clear user_id from clients that were migrated
-- Only for clients whose password was just migrated
-- ----------------------------------------------------------------------------
UPDATE clients c
SET c.user_id = NULL
WHERE c.password_hash IS NOT NULL
  AND c.user_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM business_users bu WHERE bu.user_id = c.user_id);

-- ----------------------------------------------------------------------------
-- STEP 9: Add index on clients.email for login lookups
-- ----------------------------------------------------------------------------
ALTER TABLE clients
    ADD KEY idx_clients_email_auth (email, password_hash);

-- ============================================================================
-- VERIFICATION QUERIES (run manually to verify migration)
-- ============================================================================
-- Check no pure customers left in users:
-- SELECT * FROM users u WHERE NOT EXISTS (SELECT 1 FROM business_users bu WHERE bu.user_id = u.id);
--
-- Check clients with password can login:
-- SELECT id, email, password_hash IS NOT NULL as can_login FROM clients WHERE email IS NOT NULL;
--
-- Check sessions migrated:
-- SELECT COUNT(*) FROM client_sessions;
-- ============================================================================
