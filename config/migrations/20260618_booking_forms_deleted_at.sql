ALTER TABLE `booking_forms`
  ADD COLUMN `deleted_at` TIMESTAMP NULL DEFAULT NULL AFTER `updated_at`,
  ADD KEY `idx_booking_forms_business_deleted_active_sort` (`business_id`, `deleted_at`, `is_active`, `sort_order`);
