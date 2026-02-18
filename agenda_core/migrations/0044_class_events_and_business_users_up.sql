-- 0044_class_events_and_business_users_up.sql
-- Adds class events feature tables.
-- No changes to business_users and business_invitations.

START TRANSACTION;

CREATE TABLE IF NOT EXISTS `class_types` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` int UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_types_id_business` (`id`,`business_id`),
  UNIQUE KEY `uk_class_types_business_name` (`business_id`,`name`),
  KEY `idx_class_types_business_active` (`business_id`,`is_active`),
  CONSTRAINT `fk_class_types_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `class_type_locations` (
  `class_type_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`class_type_id`,`location_id`),
  KEY `idx_ctl_location_type` (`location_id`,`class_type_id`),
  CONSTRAINT `fk_ctl_class_type` FOREIGN KEY (`class_type_id`) REFERENCES `class_types` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ctl_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Abilitazione tipi classe per sede';

CREATE TABLE IF NOT EXISTS `class_events` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` int UNSIGNED NOT NULL,
  `class_type_id` int UNSIGNED NOT NULL COMMENT 'FK class_types.id',
  `starts_at` timestamp NOT NULL COMMENT 'UTC',
  `ends_at` timestamp NOT NULL COMMENT 'UTC',
  `location_id` int UNSIGNED NOT NULL,
  `staff_id` int UNSIGNED NOT NULL,
  `capacity_total` int UNSIGNED NOT NULL DEFAULT '1',
  `capacity_reserved` int UNSIGNED NOT NULL DEFAULT '0',
  `confirmed_count` int UNSIGNED NOT NULL DEFAULT '0',
  `waitlist_count` int UNSIGNED NOT NULL DEFAULT '0',
  `waitlist_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `booking_open_at` timestamp NULL DEFAULT NULL,
  `booking_close_at` timestamp NULL DEFAULT NULL,
  `cancel_cutoff_minutes` int UNSIGNED NOT NULL DEFAULT '0',
  `status` enum('SCHEDULED','CANCELLED','COMPLETED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SCHEDULED',
  `visibility` enum('PUBLIC','PRIVATE') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PUBLIC',
  `price_cents` int UNSIGNED DEFAULT NULL,
  `currency` varchar(3) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_class_events_business_starts` (`business_id`,`starts_at`),
  KEY `idx_class_events_business_staff_starts` (`business_id`,`staff_id`,`starts_at`),
  KEY `idx_class_events_business_type_starts` (`business_id`,`class_type_id`,`starts_at`),
  KEY `idx_class_events_business_status_starts` (`business_id`,`status`,`starts_at`),
  CONSTRAINT `chk_class_events_capacity_total` CHECK (`capacity_total` >= 1),
  CONSTRAINT `chk_class_events_capacity_reserved` CHECK (`capacity_reserved` <= `capacity_total`),
  CONSTRAINT `chk_class_events_time_range` CHECK (`ends_at` > `starts_at`),
  CONSTRAINT `fk_class_events_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_class_events_type` FOREIGN KEY (`class_type_id`,`business_id`) REFERENCES `class_types` (`id`,`business_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_class_events_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_class_events_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `class_event_resource_requirements` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_event_id` int UNSIGNED NOT NULL,
  `resource_id` int UNSIGNED NOT NULL,
  `quantity` int UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Quantita richiesta della risorsa',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_event_resource` (`class_event_id`,`resource_id`),
  KEY `idx_cerr_event` (`class_event_id`),
  KEY `idx_cerr_resource` (`resource_id`),
  CONSTRAINT `fk_cerr_event` FOREIGN KEY (`class_event_id`) REFERENCES `class_events` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_cerr_resource` FOREIGN KEY (`resource_id`) REFERENCES `resources` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Requisiti risorse per evento classe';

CREATE TABLE IF NOT EXISTS `class_bookings` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` int UNSIGNED NOT NULL,
  `class_event_id` int UNSIGNED NOT NULL,
  `customer_id` int UNSIGNED NOT NULL COMMENT 'FK clients.id',
  `status` enum('CONFIRMED','WAITLISTED','CANCELLED_BY_CUSTOMER','CANCELLED_BY_STAFF','NO_SHOW','ATTENDED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `waitlist_position` int UNSIGNED DEFAULT NULL,
  `booked_at` timestamp NOT NULL COMMENT 'UTC',
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `checked_in_at` timestamp NULL DEFAULT NULL,
  `payment_status` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_bookings_business_event_customer` (`business_id`,`class_event_id`,`customer_id`),
  KEY `idx_class_bookings_business_event_status` (`business_id`,`class_event_id`,`status`),
  KEY `idx_class_bookings_business_customer_status` (`business_id`,`customer_id`,`status`),
  KEY `idx_class_bookings_business_event_waitlist` (`business_id`,`class_event_id`,`waitlist_position`),
  CONSTRAINT `chk_class_bookings_waitlist_position` CHECK (
    (`status` <> 'WAITLISTED') OR (`waitlist_position` IS NOT NULL)
  ),
  CONSTRAINT `fk_class_bookings_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_class_bookings_event` FOREIGN KEY (`class_event_id`) REFERENCES `class_events` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_class_bookings_customer` FOREIGN KEY (`customer_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
