ALTER TABLE `class_types`
  ADD COLUMN `sort_order` int NOT NULL DEFAULT '0' AFTER `service_category_id`,
  ADD KEY `idx_class_types_business_sort` (`business_id`, `sort_order`);
