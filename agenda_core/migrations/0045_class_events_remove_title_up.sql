-- 0045_class_events_remove_title_up.sql
-- Removes legacy title column from class_events.

START TRANSACTION;

ALTER TABLE `class_events`
  DROP COLUMN IF EXISTS `title`;

COMMIT;
