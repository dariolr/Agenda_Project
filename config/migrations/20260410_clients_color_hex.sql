ALTER TABLE `clients`
  ADD COLUMN `color_hex` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Colore cliente in formato #RRGGBB' AFTER `notes`;
