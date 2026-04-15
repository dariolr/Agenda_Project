ALTER TABLE `class_types`
  ADD COLUMN `service_category_id` int UNSIGNED DEFAULT NULL COMMENT 'Categoria servizi associata al tipo classe' AFTER `color_hex`,
  ADD KEY `idx_class_types_service_category` (`service_category_id`),
  ADD CONSTRAINT `fk_class_types_service_category` FOREIGN KEY (`service_category_id`) REFERENCES `service_categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
