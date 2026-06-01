-- Filtro visibilità servizi/lezioni per operatori
ALTER TABLE business_users
  ADD COLUMN allowed_service_ids JSON NULL COMMENT 'NULL = nessun filtro. Array di service_id: operatore vede solo quei servizi.',
  ADD COLUMN allowed_class_type_ids JSON NULL COMMENT 'NULL = nessun filtro. Array di class_type_id.';

-- Filtro visibilità servizi/lezioni salvato sull''invito (applicato all''accettazione)
ALTER TABLE business_invitations
  ADD COLUMN allowed_service_ids JSON NULL,
  ADD COLUMN allowed_class_type_ids JSON NULL;
