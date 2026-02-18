-- 0044_class_events_and_business_users_down.sql
-- Rollback for class events feature.

START TRANSACTION;

DROP TABLE IF EXISTS `class_bookings`;
DROP TABLE IF EXISTS `class_event_resource_requirements`;
DROP TABLE IF EXISTS `class_events`;
DROP TABLE IF EXISTS `class_type_locations`;
DROP TABLE IF EXISTS `class_types`;

COMMIT;
