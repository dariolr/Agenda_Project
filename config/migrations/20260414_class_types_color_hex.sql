ALTER TABLE `class_types`
  ADD COLUMN `color_hex` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Colore tipo classe in formato #RRGGBB' AFTER `description`;
