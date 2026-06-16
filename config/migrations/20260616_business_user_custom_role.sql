-- Nuovo ruolo operatore completamente configurabile: 'custom'.
-- Affianca i ruoli esistenti durante la transizione (non li rimuove).
ALTER TABLE business_users
  MODIFY COLUMN `role` enum('owner','admin','manager','staff','viewer','custom')
    COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'staff';

ALTER TABLE business_invitations
  MODIFY COLUMN `role` enum('admin','manager','staff','viewer','custom')
    COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'staff';
