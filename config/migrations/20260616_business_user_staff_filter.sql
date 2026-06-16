-- Filtro membri del team accessibili per operatori (3-stati: NULL=Tutti, []=Nessuno, [ids]=Solo selezionati)
ALTER TABLE business_users
  ADD COLUMN allowed_staff_ids JSON NULL COMMENT 'NULL = nessun filtro. Array di staff_id: operatore opera solo su quei membri del team.';

-- Filtro membri del team salvato sull''invito (applicato all''accettazione)
ALTER TABLE business_invitations
  ADD COLUMN allowed_staff_ids JSON NULL;
