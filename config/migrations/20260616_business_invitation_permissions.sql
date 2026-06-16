-- Permessi granulari salvati sull''invito (soprattutto per il ruolo custom),
-- applicati alla creazione del business_user all''accettazione.
-- NULL = non specificato → all''accettazione si usa il default del ruolo.
ALTER TABLE business_invitations
  ADD COLUMN can_manage_bookings tinyint(1) DEFAULT NULL,
  ADD COLUMN can_manage_clients  tinyint(1) DEFAULT NULL,
  ADD COLUMN can_manage_services tinyint(1) DEFAULT NULL,
  ADD COLUMN can_manage_staff    tinyint(1) DEFAULT NULL,
  ADD COLUMN can_view_reports    tinyint(1) DEFAULT NULL;
