-- ============================================================================
-- Migration 0028: Add category_id to service_packages
-- ============================================================================

ALTER TABLE service_packages
  ADD COLUMN category_id INT UNSIGNED NULL AFTER location_id;

-- Backfill category_id from the first service in the package (lowest sort_order)
UPDATE service_packages sp
JOIN (
  SELECT spi.package_id, s.category_id
  FROM service_package_items spi
  JOIN services s ON s.id = spi.service_id
  JOIN (
    SELECT package_id, MIN(sort_order) AS min_sort
    FROM service_package_items
    GROUP BY package_id
  ) first_item
    ON first_item.package_id = spi.package_id
    AND first_item.min_sort = spi.sort_order
) resolved
  ON resolved.package_id = sp.id
SET sp.category_id = resolved.category_id;

ALTER TABLE service_packages
  MODIFY category_id INT UNSIGNED NOT NULL,
  ADD KEY idx_service_packages_category (category_id),
  ADD CONSTRAINT fk_service_packages_category FOREIGN KEY (category_id)
    REFERENCES service_categories(id) ON DELETE RESTRICT ON UPDATE CASCADE;
