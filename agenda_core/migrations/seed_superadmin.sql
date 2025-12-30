-- ============================================================================
-- SUPERADMIN SEED — agenda_core
-- ============================================================================
--
-- Questo file crea l'utente superadmin che gestisce l'intera piattaforma.
--
-- ⚠️ SICUREZZA: 
--    - Cambiare la password IMMEDIATAMENTE dopo il primo login
--    - NON committare questo file con password reali
--    - In produzione, eseguire manualmente con password sicura
--
-- Esecuzione:
--    mysql -u user -p database < migrations/seed_superadmin.sql
--
-- Oppure da MySQL CLI:
--    source /path/to/seed_superadmin.sql
--
-- ============================================================================

-- Password temporanea: 'TuaPasswordSicura123!'
-- ⚠️ CAMBIARE SUBITO DOPO IL PRIMO ACCESSO!
--
-- Per generare un nuovo hash:
--    php -r "echo password_hash('NuovaPassword', PASSWORD_BCRYPT) . PHP_EOL;"

INSERT INTO users (
    email,
    password_hash,
    first_name,
    last_name,
    phone,
    is_active,
    is_superadmin,
    email_verified_at,
    created_at
) VALUES (
    'dariolarosa@hotmail.com',
    '$2y$10$IsopvVDihNMHICUn2QsSX.kjIkw/uAf8Ofl2hV88pCzp8w44YSjhe',
    'Dario',
    'La Rosa',
    NULL,
    1,
    1,  -- ← SUPERADMIN FLAG
    NOW(),
    NOW()
)
ON DUPLICATE KEY UPDATE
    is_superadmin = 1,
    is_active = 1;

-- ============================================================================
-- VERIFICA
-- ============================================================================
-- Dopo l'esecuzione, verificare con:
--
--    SELECT id, email, first_name, last_name, is_superadmin 
--    FROM users 
--    WHERE is_superadmin = 1;
--
-- Output atteso:
--    +----+-------------------+------------+-----------+--------------+
--    | id | email             | first_name | last_name | is_superadmin|
--    +----+-------------------+------------+-----------+--------------+
--    |  X | dario@romeolab.it | Dario      | La Rosa   |            1 |
--    +----+-------------------+------------+-----------+--------------+
