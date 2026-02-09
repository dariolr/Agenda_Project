-- 0043_business_invitations_add_staff_id.sql
-- Add optional staff assignment to invitations.
-- Used when role=staff to bind invited operator to exactly one staff profile.

ALTER TABLE business_invitations
  ADD COLUMN staff_id INT UNSIGNED NULL AFTER scope_type,
  ADD KEY idx_invitations_staff (staff_id),
  ADD CONSTRAINT fk_invitations_staff
    FOREIGN KEY (staff_id) REFERENCES staff(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

