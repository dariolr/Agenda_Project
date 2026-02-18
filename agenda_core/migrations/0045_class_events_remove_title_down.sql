-- 0045_class_events_remove_title_down.sql
-- Restores legacy title column on class_events.

START TRANSACTION;

ALTER TABLE `class_events`
  ADD COLUMN IF NOT EXISTS `title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL
  AFTER `class_type_id`;

COMMIT;
