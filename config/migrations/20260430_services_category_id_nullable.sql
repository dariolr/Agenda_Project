-- Make category_id nullable on services and service_packages, and change the FK
-- from ON DELETE RESTRICT to ON DELETE SET NULL.
--
-- Rationale: deleteCategory is only reachable when no active services exist
-- (hasActiveCategoryLinkedEntries blocks it otherwise). At that point only
-- soft-deleted rows (is_active = 0) still reference the category; MySQL can
-- safely NULL them out automatically without any application-level UPDATE.

ALTER TABLE services
  MODIFY COLUMN category_id INT UNSIGNED NULL DEFAULT NULL;

ALTER TABLE services
  DROP FOREIGN KEY fk_services_category;

ALTER TABLE services
  ADD CONSTRAINT fk_services_category
    FOREIGN KEY (category_id) REFERENCES service_categories(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE service_packages
  MODIFY COLUMN category_id INT UNSIGNED NULL DEFAULT NULL;

ALTER TABLE service_packages
  DROP FOREIGN KEY fk_service_packages_category;

ALTER TABLE service_packages
  ADD CONSTRAINT fk_service_packages_category
    FOREIGN KEY (category_id) REFERENCES service_categories(id)
    ON DELETE SET NULL ON UPDATE CASCADE;
