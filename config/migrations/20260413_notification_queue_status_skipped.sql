ALTER TABLE `notification_queue`
  MODIFY COLUMN `status` enum('pending','processing','sent','failed','skipped') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending';
