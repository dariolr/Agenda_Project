-- Aggiunge class_booking_id a notification_queue per collegare notifiche alle prenotazioni di classe

ALTER TABLE `notification_queue`
    ADD COLUMN `class_booking_id` int UNSIGNED DEFAULT NULL COMMENT 'Reference to related class booking' AFTER `booking_id`;

ALTER TABLE `notification_queue`
    ADD KEY `idx_nq_class_booking_id` (`class_booking_id`);
