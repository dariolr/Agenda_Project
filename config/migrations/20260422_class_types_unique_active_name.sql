ALTER TABLE `class_types`
  DROP INDEX `uk_class_types_business_name`,
  ADD COLUMN `active_name` varchar(255)
    GENERATED ALWAYS AS (CASE WHEN `is_active` = 1 THEN `name` ELSE NULL END) STORED,
  ADD UNIQUE KEY `uk_class_types_business_active_name` (`business_id`, `active_name`);
