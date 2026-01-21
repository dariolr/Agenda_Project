-- ============================================================================
-- Migration 0029: Add sort_order to service_packages
-- ============================================================================

ALTER TABLE service_packages
  ADD COLUMN sort_order INT UNSIGNED NOT NULL DEFAULT 0 AFTER category_id;

-- Backfill sort_order so packages appear after services within the same category
UPDATE service_packages sp
SET sort_order = COALESCE(
  (SELECT MAX(s.sort_order) FROM services s WHERE s.category_id = sp.category_id),
  -1
) + sp.id;

ALTER TABLE service_packages
  ADD KEY idx_service_packages_sort_order (sort_order);
