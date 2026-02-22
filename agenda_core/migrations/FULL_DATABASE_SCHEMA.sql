-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Creato il: Feb 19, 2026 alle 05:46
-- Versione del server: 8.4.5-5
-- Versione PHP: 8.2.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `db5hleekkbuuhm`
--

-- --------------------------------------------------------

--
-- Struttura della tabella `auth_sessions`
--

CREATE TABLE `auth_sessions` (
  `id` int UNSIGNED NOT NULL,
  `user_id` int UNSIGNED NOT NULL,
  `refresh_token_hash` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SHA-256 hex of refresh token',
  `user_agent` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Browser/app identification',
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'IPv4 or IPv6',
  `expires_at` timestamp NOT NULL COMMENT 'Refresh token expiration',
  `last_used_at` timestamp NULL DEFAULT NULL COMMENT 'Last refresh attempt',
  `revoked_at` timestamp NULL DEFAULT NULL COMMENT 'Manual revocation timestamp',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `bookings`
--

CREATE TABLE `bookings` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `client_id` int UNSIGNED DEFAULT NULL COMMENT 'Client from business anagrafica',
  `user_id` int UNSIGNED DEFAULT NULL COMMENT 'User who booked online',
  `client_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Fallback if no client',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `status` enum('pending','confirmed','completed','cancelled','no_show','replaced') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'confirmed',
  `recurrence_rule_id` int UNSIGNED DEFAULT NULL COMMENT 'FK a booking_recurrence_rules se ricorrente',
  `recurrence_index` int UNSIGNED DEFAULT NULL COMMENT 'Indice occorrenza nella serie (0 = prima, 1 = seconda, ...)',
  `is_recurrence_parent` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'True se è la prenotazione madre della serie',
  `has_conflict` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'True se creata con conflict_strategy=force nonostante sovrapposizione',
  `source` enum('online','manual','import','onlinestaff') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
  `idempotency_key` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Client-provided UUID for idempotent POST',
  `idempotency_expires_at` timestamp NULL DEFAULT NULL COMMENT 'Key expiration (24h TTL)',
  `replaces_booking_id` int UNSIGNED DEFAULT NULL COMMENT 'ID of booking this one replaces (for new booking)',
  `replaced_by_booking_id` int UNSIGNED DEFAULT NULL COMMENT 'ID of booking that replaced this (for original)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `booking_events`
--

CREATE TABLE `booking_events` (
  `id` int UNSIGNED NOT NULL,
  `booking_id` int UNSIGNED NOT NULL,
  `event_type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `actor_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `actor_id` int UNSIGNED DEFAULT NULL,
  `actor_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `correlation_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payload_json` json NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `booking_items`
--

CREATE TABLE `booking_items` (
  `id` int UNSIGNED NOT NULL,
  `booking_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL COMMENT 'Denormalized from bookings for availability queries',
  `service_id` int UNSIGNED NOT NULL,
  `service_variant_id` int UNSIGNED NOT NULL,
  `staff_id` int UNSIGNED NOT NULL,
  `start_time` timestamp NOT NULL COMMENT 'UTC',
  `end_time` timestamp NOT NULL COMMENT 'UTC',
  `price` decimal(10,2) DEFAULT NULL COMMENT 'Applied price at booking time',
  `extra_blocked_minutes` int UNSIGNED NOT NULL DEFAULT '0',
  `extra_processing_minutes` int UNSIGNED NOT NULL DEFAULT '0',
  `service_name_snapshot` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `client_name_snapshot` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `booking_recurrence_rules`
--

CREATE TABLE `booking_recurrence_rules` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `frequency` enum('daily','weekly','monthly','custom') COLLATE utf8mb4_unicode_ci NOT NULL,
  `interval_value` int UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Ogni X giorni/settimane/mesi',
  `max_occurrences` int UNSIGNED DEFAULT NULL COMMENT 'Numero massimo di ripetizioni (NULL = infinito)',
  `end_date` date DEFAULT NULL COMMENT 'Data fine ricorrenza (NULL = usa max_occurrences)',
  `conflict_strategy` enum('skip','force') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'skip' COMMENT 'skip = salta date con conflitto, force = crea comunque con sovrapposizione',
  `days_of_week` json DEFAULT NULL COMMENT 'Per weekly multi-day: [1,3,5] = Lun,Mer,Ven',
  `day_of_month` int UNSIGNED DEFAULT NULL COMMENT 'Per monthly: giorno del mese (1-31)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Regole di ricorrenza per prenotazioni ripetute';

-- --------------------------------------------------------

--
-- Struttura della tabella `booking_replacements`
--

CREATE TABLE `booking_replacements` (
  `id` int UNSIGNED NOT NULL,
  `original_booking_id` int UNSIGNED NOT NULL COMMENT 'The booking that was replaced',
  `new_booking_id` int UNSIGNED NOT NULL COMMENT 'The booking that replaced the original',
  `actor_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'customer, staff, or system',
  `actor_id` int UNSIGNED DEFAULT NULL COMMENT 'ID of the actor (client_id for customer, user_id for staff)',
  `reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Optional reason for the modification',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Audit table linking original bookings to their replacements';

-- --------------------------------------------------------

--
-- Struttura della tabella `businesses`
--

CREATE TABLE `businesses` (
  `id` int UNSIGNED NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `online_bookings_notification_email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `service_color_palette` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'legacy',
  `timezone` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Europe/Rome',
  `currency` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'EUR',
  `cancellation_hours` int UNSIGNED NOT NULL DEFAULT '24' COMMENT 'Default hours before appointment when cancellation/modification is allowed',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `is_suspended` tinyint(1) NOT NULL DEFAULT '0',
  `suspension_message` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `business_invitations`
--

CREATE TABLE `business_invitations` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('admin','manager','staff','viewer') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'staff',
  `scope_type` enum('business','locations') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'business',
  `staff_id` int UNSIGNED DEFAULT NULL,
  `token` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` timestamp NOT NULL,
  `status` enum('pending','accepted','expired','declined','revoked') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `accepted_by` int UNSIGNED DEFAULT NULL,
  `accepted_at` timestamp NULL DEFAULT NULL,
  `invited_by` int UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `business_invitation_locations`
--

CREATE TABLE `business_invitation_locations` (
  `id` int UNSIGNED NOT NULL,
  `invitation_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Location assegnate a inviti con scope_type=locations';

-- --------------------------------------------------------

--
-- Struttura della tabella `business_users`
--

CREATE TABLE `business_users` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `user_id` int UNSIGNED NOT NULL,
  `role` enum('owner','admin','manager','staff','viewer') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'staff',
  `scope_type` enum('business','locations') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'business',
  `staff_id` int UNSIGNED DEFAULT NULL,
  `can_manage_bookings` tinyint(1) NOT NULL DEFAULT '1',
  `can_manage_clients` tinyint(1) NOT NULL DEFAULT '1',
  `can_manage_services` tinyint(1) NOT NULL DEFAULT '0',
  `can_manage_staff` tinyint(1) NOT NULL DEFAULT '0',
  `can_view_reports` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `invited_by` int UNSIGNED DEFAULT NULL,
  `invited_at` timestamp NULL DEFAULT NULL,
  `accepted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `business_user_locations`
--

CREATE TABLE `business_user_locations` (
  `id` int UNSIGNED NOT NULL,
  `business_user_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Location assegnate a utenti con scope_type=locations';

-- --------------------------------------------------------

--
-- Struttura della tabella `class_bookings`
--

CREATE TABLE `class_bookings` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `class_event_id` int UNSIGNED NOT NULL,
  `customer_id` int UNSIGNED NOT NULL COMMENT 'FK clients.id',
  `status` enum('CONFIRMED','WAITLISTED','CANCELLED_BY_CUSTOMER','CANCELLED_BY_STAFF','NO_SHOW','ATTENDED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `waitlist_position` int UNSIGNED DEFAULT NULL,
  `booked_at` timestamp NOT NULL COMMENT 'UTC',
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `checked_in_at` timestamp NULL DEFAULT NULL,
  `payment_status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Struttura della tabella `class_events`
--

CREATE TABLE `class_events` (
  `id` int UNSIGNED NOT NULL,
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
  `status` enum('SCHEDULED','CANCELLED','COMPLETED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SCHEDULED',
  `visibility` enum('PUBLIC','PRIVATE') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PUBLIC',
  `price_cents` int UNSIGNED DEFAULT NULL,
  `currency` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Struttura della tabella `class_event_resource_requirements`
--

CREATE TABLE `class_event_resource_requirements` (
  `id` int UNSIGNED NOT NULL,
  `class_event_id` int UNSIGNED NOT NULL,
  `resource_id` int UNSIGNED NOT NULL,
  `quantity` int UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Quantita richiesta della risorsa',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Requisiti risorse per evento classe';

-- --------------------------------------------------------

--
-- Struttura della tabella `class_types`
--

CREATE TABLE `class_types` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `class_type_locations`
--

CREATE TABLE `class_type_locations` (
  `class_type_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Abilitazione tipi classe per sede';

-- --------------------------------------------------------

--
-- Struttura della tabella `clients`
--

CREATE TABLE `clients` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `user_id` int UNSIGNED DEFAULT NULL COMMENT 'Link a user se registrato online',
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'bcrypt hash for customer self-service login',
  `email_verified_at` timestamp NULL DEFAULT NULL COMMENT 'When email was verified',
  `first_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `loyalty_points` int NOT NULL DEFAULT '0',
  `last_visit` timestamp NULL DEFAULT NULL,
  `is_archived` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `client_sessions`
--

CREATE TABLE `client_sessions` (
  `id` int UNSIGNED NOT NULL,
  `client_id` int UNSIGNED NOT NULL,
  `refresh_token_hash` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SHA-256 hex of refresh token',
  `user_agent` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expires_at` timestamp NOT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `revoked_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `closures`
--

CREATE TABLE `closures` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Closure periods (holidays, vacations). Can apply to one or more locations.';

-- --------------------------------------------------------

--
-- Struttura della tabella `closure_locations`
--

CREATE TABLE `closure_locations` (
  `closure_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Pivot table linking closures to locations (many-to-many).';

-- --------------------------------------------------------

--
-- Struttura della tabella `locations`
--

CREATE TABLE `locations` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `address` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `postal_code` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Postal/ZIP code',
  `region` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'IT',
  `phone` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `timezone` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'Europe/Rome' COMMENT 'Location timezone',
  `currency` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Override business currency',
  `cancellation_hours` int UNSIGNED DEFAULT NULL COMMENT 'Override business cancellation policy. NULL = use business default',
  `min_booking_notice_hours` int UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Minimum hours before appointment for online booking. Default 1 hour.',
  `max_booking_advance_days` int UNSIGNED NOT NULL DEFAULT '90' COMMENT 'Maximum days in advance for online booking. Default 90 days (3 months).',
  `allow_customer_choose_staff` tinyint(1) NOT NULL DEFAULT '0',
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `sort_order` int NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `online_booking_slot_interval_minutes` int UNSIGNED NOT NULL DEFAULT '15' COMMENT 'Intervallo tra slot mostrati ai clienti online (minuti)',
  `slot_display_mode` enum('all','min_gap') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'all' COMMENT 'Modalità visualizzazione: all=tutti, min_gap=filtra gap piccoli',
  `min_gap_minutes` int UNSIGNED NOT NULL DEFAULT '30' COMMENT 'Gap minimo accettabile in minuti (usato solo se mode=min_gap)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `location_schedules`
--

CREATE TABLE `location_schedules` (
  `id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `day_of_week` tinyint UNSIGNED NOT NULL COMMENT '0=Sunday, 1=Monday, ..., 6=Saturday',
  `open_time` time NOT NULL COMMENT 'Opening time (e.g., 09:00:00)',
  `close_time` time NOT NULL COMMENT 'Closing time (e.g., 18:00:00)',
  `is_closed` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Day is closed for business',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Struttura della tabella `notification_queue`
--

CREATE TABLE `notification_queue` (
  `id` bigint UNSIGNED NOT NULL,
  `type` enum('email','sms','push','webhook') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'email',
  `channel` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'booking_confirmed, booking_cancelled, reminder_24h, etc.',
  `recipient_type` enum('user','client','staff') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `recipient_id` int UNSIGNED NOT NULL,
  `recipient_email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recipient_phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recipient_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `subject` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Email subject',
  `payload` json NOT NULL COMMENT 'Template variables and metadata',
  `priority` tinyint UNSIGNED NOT NULL DEFAULT '5' COMMENT '1=highest, 10=lowest',
  `scheduled_at` timestamp NULL DEFAULT NULL COMMENT 'For scheduled notifications like reminders',
  `status` enum('pending','processing','sent','failed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `attempts` int UNSIGNED NOT NULL DEFAULT '0',
  `max_attempts` int UNSIGNED NOT NULL DEFAULT '3',
  `last_attempt_at` timestamp NULL DEFAULT NULL,
  `sent_at` timestamp NULL DEFAULT NULL,
  `failed_at` timestamp NULL DEFAULT NULL,
  `error_message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `business_id` int UNSIGNED DEFAULT NULL COMMENT 'For business-specific templates',
  `booking_id` int UNSIGNED DEFAULT NULL COMMENT 'Reference to related booking',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Queue for async notification processing';

-- --------------------------------------------------------

--
-- Struttura della tabella `notification_settings`
--

CREATE TABLE `notification_settings` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `email_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `email_booking_confirmed` tinyint(1) NOT NULL DEFAULT '1',
  `email_booking_cancelled` tinyint(1) NOT NULL DEFAULT '1',
  `email_booking_rescheduled` tinyint(1) NOT NULL DEFAULT '1',
  `email_reminder_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `email_reminder_hours` int UNSIGNED NOT NULL DEFAULT '24' COMMENT 'Hours before appointment',
  `sms_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `sms_reminder_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `sms_reminder_hours` int UNSIGNED NOT NULL DEFAULT '24',
  `sender_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Custom from name',
  `reply_to_email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Business notification preferences';

-- --------------------------------------------------------

--
-- Struttura della tabella `notification_templates`
--

CREATE TABLE `notification_templates` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `channel` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'booking_confirmed, booking_cancelled, etc.',
  `type` enum('email','sms') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'email',
  `subject` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Email subject with {{placeholders}}',
  `body_html` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'HTML body for email',
  `body_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Plain text body for SMS or email fallback',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Custom notification templates per business';

-- --------------------------------------------------------

--
-- Struttura della tabella `password_reset_token_clients`
--

CREATE TABLE `password_reset_token_clients` (
  `id` int UNSIGNED NOT NULL,
  `client_id` int UNSIGNED NOT NULL,
  `token_hash` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SHA-256 hex of reset token',
  `expires_at` timestamp NOT NULL,
  `used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `password_reset_token_users`
--

CREATE TABLE `password_reset_token_users` (
  `id` int UNSIGNED NOT NULL,
  `user_id` int UNSIGNED NOT NULL,
  `token_hash` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SHA-256 hex of reset token',
  `expires_at` timestamp NOT NULL,
  `used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `popular_services`
--

CREATE TABLE `popular_services` (
  `id` int UNSIGNED NOT NULL,
  `staff_id` int UNSIGNED NOT NULL,
  `service_id` int UNSIGNED NOT NULL,
  `rank` tinyint UNSIGNED NOT NULL COMMENT '1 = più prenotato, 5 = quinto',
  `booking_count` int UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Numero prenotazioni negli ultimi 90 giorni',
  `computed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Struttura della tabella `resources`
--

CREATE TABLE `resources` (
  `id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int UNSIGNED NOT NULL DEFAULT '1',
  `type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `sort_order` int UNSIGNED NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `services`
--

CREATE TABLE `services` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `category_id` int UNSIGNED NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `sort_order` int NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `service_categories`
--

CREATE TABLE `service_categories` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `sort_order` int NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `service_packages`
--

CREATE TABLE `service_packages` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `category_id` int UNSIGNED NOT NULL,
  `sort_order` int UNSIGNED NOT NULL DEFAULT '0',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `override_price` decimal(10,2) DEFAULT NULL,
  `override_duration_minutes` int UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `is_broken` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `service_package_items`
--

CREATE TABLE `service_package_items` (
  `package_id` int UNSIGNED NOT NULL,
  `service_id` int UNSIGNED NOT NULL,
  `sort_order` int UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `service_variants`
--

CREATE TABLE `service_variants` (
  `id` int UNSIGNED NOT NULL,
  `service_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `duration_minutes` int UNSIGNED NOT NULL,
  `processing_time` int UNSIGNED DEFAULT NULL COMMENT 'Minuti post-lavorazione',
  `blocked_time` int UNSIGNED DEFAULT NULL COMMENT 'Minuti bloccati',
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `currency` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Override location currency',
  `color_hex` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Es. #FF5733',
  `is_bookable_online` tinyint(1) NOT NULL DEFAULT '1',
  `is_free` tinyint(1) NOT NULL DEFAULT '0',
  `is_price_starting_from` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Mostra "da €X"',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `service_variant_resource_requirements`
--

CREATE TABLE `service_variant_resource_requirements` (
  `id` int UNSIGNED NOT NULL,
  `service_variant_id` int UNSIGNED NOT NULL,
  `resource_id` int UNSIGNED NOT NULL,
  `quantity` int UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Quantità richiesta della risorsa',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Requisiti di risorse per ogni variante servizio';

-- --------------------------------------------------------

--
-- Struttura della tabella `staff`
--

CREATE TABLE `staff` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `surname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `color_hex` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '#FFD700',
  `avatar_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sort_order` int NOT NULL DEFAULT '0',
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_bookable_online` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `staff_availability_exceptions`
--

CREATE TABLE `staff_availability_exceptions` (
  `id` int UNSIGNED NOT NULL,
  `staff_id` int UNSIGNED NOT NULL,
  `exception_date` date NOT NULL COMMENT 'Data specifica dell eccezione',
  `start_time` time DEFAULT NULL COMMENT 'Inizio fascia oraria (NULL = tutto il giorno)',
  `end_time` time DEFAULT NULL COMMENT 'Fine fascia oraria (NULL = tutto il giorno)',
  `exception_type` enum('available','unavailable') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unavailable' COMMENT 'available = aggiunge disponibilità, unavailable = rimuove disponibilità',
  `reason_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Codice motivo: vacation, medical_visit, extra_shift, personal, training, meeting',
  `reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Motivo testuale libero',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Eccezioni alla disponibilità settimanale staff (ferie, permessi, turni extra)';

-- --------------------------------------------------------

--
-- Struttura della tabella `staff_locations`
--

CREATE TABLE `staff_locations` (
  `staff_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `staff_planning`
--

CREATE TABLE `staff_planning` (
  `id` int UNSIGNED NOT NULL,
  `staff_id` int UNSIGNED NOT NULL,
  `type` enum('weekly','biweekly') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'weekly',
  `planning_slot_minutes` tinyint UNSIGNED NOT NULL DEFAULT '15' COMMENT 'Passo (in minuti) usato per generare il planning',
  `valid_from` date NOT NULL,
  `valid_to` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `staff_planning_week_template`
--

CREATE TABLE `staff_planning_week_template` (
  `id` int UNSIGNED NOT NULL,
  `staff_planning_id` int UNSIGNED NOT NULL,
  `week_label` enum('A','B') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'A',
  `day_of_week` tinyint UNSIGNED NOT NULL,
  `slots` json NOT NULL
) ;

-- --------------------------------------------------------

-- Struttura della tabella `staff_services`
--

CREATE TABLE `staff_services` (
  `staff_id` int UNSIGNED NOT NULL,
  `service_id` int UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Services that each staff member is qualified to perform';

-- --------------------------------------------------------

--
-- Struttura della tabella `time_blocks`
--

CREATE TABLE `time_blocks` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `location_id` int UNSIGNED NOT NULL,
  `start_time` timestamp NOT NULL,
  `end_time` timestamp NOT NULL,
  `reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_all_day` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `time_block_staff`
--

CREATE TABLE `time_block_staff` (
  `time_block_id` int UNSIGNED NOT NULL,
  `staff_id` int UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `users`
--

CREATE TABLE `users` (
  `id` int UNSIGNED NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'bcrypt or argon2id hash',
  `first_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `is_superadmin` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `webhook_deliveries`
--

CREATE TABLE `webhook_deliveries` (
  `id` bigint UNSIGNED NOT NULL,
  `webhook_endpoint_id` int UNSIGNED NOT NULL,
  `event_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'booking.created, booking.updated, etc.',
  `payload` json NOT NULL,
  `http_status_code` int UNSIGNED DEFAULT NULL COMMENT 'HTTP response code',
  `response_body` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Response from webhook endpoint',
  `attempt_count` int UNSIGNED NOT NULL DEFAULT '0',
  `next_retry_at` timestamp NULL DEFAULT NULL COMMENT 'When to retry if failed',
  `delivered_at` timestamp NULL DEFAULT NULL COMMENT 'When successfully delivered',
  `failed_at` timestamp NULL DEFAULT NULL COMMENT 'When permanently failed',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Log of webhook delivery attempts with retry tracking';

-- --------------------------------------------------------

--
-- Struttura della tabella `webhook_endpoints`
--

CREATE TABLE `webhook_endpoints` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `secret` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Used to sign webhook payloads',
  `events` json NOT NULL COMMENT 'Array of event types to subscribe to',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Webhook endpoints registered by businesses';

--
-- Indici per le tabelle scaricate
--

--
-- Indici per le tabelle `auth_sessions`
--
ALTER TABLE `auth_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_auth_sessions_token` (`refresh_token_hash`),
  ADD KEY `idx_auth_sessions_user` (`user_id`),
  ADD KEY `idx_auth_sessions_user_active` (`user_id`,`revoked_at`,`expires_at`),
  ADD KEY `idx_auth_sessions_expires` (`expires_at`);

--
-- Indici per le tabelle `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_bookings_idempotency` (`business_id`,`idempotency_key`),
  ADD KEY `idx_bookings_business_location` (`business_id`,`location_id`),
  ADD KEY `idx_bookings_business_location_created` (`business_id`,`location_id`,`created_at`),
  ADD KEY `idx_bookings_client` (`client_id`),
  ADD KEY `idx_bookings_user` (`user_id`),
  ADD KEY `idx_bookings_status` (`business_id`,`status`),
  ADD KEY `idx_bookings_idempotency_expires` (`idempotency_expires_at`),
  ADD KEY `idx_bookings_replaces_booking_id` (`replaces_booking_id`),
  ADD KEY `idx_bookings_replaced_by_booking_id` (`replaced_by_booking_id`),
  ADD KEY `fk_bookings_location` (`location_id`),
  ADD KEY `idx_bookings_recurrence` (`recurrence_rule_id`),
  ADD KEY `idx_bookings_recurrence_parent` (`recurrence_rule_id`,`is_recurrence_parent`);

--
-- Indici per le tabelle `booking_events`
--
ALTER TABLE `booking_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_booking_events_booking_id` (`booking_id`),
  ADD KEY `idx_booking_events_event_type` (`event_type`),
  ADD KEY `idx_booking_events_created_at` (`created_at`),
  ADD KEY `idx_booking_events_correlation_id` (`correlation_id`);

--
-- Indici per le tabelle `booking_items`
--
ALTER TABLE `booking_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_booking_items_booking` (`booking_id`),
  ADD KEY `idx_booking_items_staff_time` (`staff_id`,`start_time`,`end_time`),
  ADD KEY `idx_booking_items_location_time` (`location_id`,`start_time`,`end_time`),
  ADD KEY `idx_booking_items_service` (`service_id`),
  ADD KEY `idx_booking_items_variant` (`service_variant_id`);

--
-- Indici per le tabelle `booking_recurrence_rules`
--
ALTER TABLE `booking_recurrence_rules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_recurrence_business` (`business_id`);

--
-- Indici per le tabelle `booking_replacements`
--
ALTER TABLE `booking_replacements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_booking_replacements_original` (`original_booking_id`),
  ADD UNIQUE KEY `uk_booking_replacements_new` (`new_booking_id`),
  ADD KEY `idx_booking_replacements_created_at` (`created_at`);

--
-- Indici per le tabelle `businesses`
--
ALTER TABLE `businesses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_businesses_slug` (`slug`),
  ADD KEY `idx_businesses_active` (`is_active`);

--
-- Indici per le tabelle `business_invitations`
--
ALTER TABLE `business_invitations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_invitation_token` (`token`),
  ADD UNIQUE KEY `uk_pending_invitation` (`business_id`,`email`,`status`),
  ADD KEY `fk_invitations_invited_by` (`invited_by`),
  ADD KEY `fk_invitations_accepted_by` (`accepted_by`),
  ADD KEY `idx_invitations_token` (`token`,`status`),
  ADD KEY `idx_invitations_business_status` (`business_id`,`status`),
  ADD KEY `idx_invitations_email_status` (`email`,`status`),
  ADD KEY `idx_invitations_staff` (`staff_id`);

--
-- Indici per le tabelle `business_invitation_locations`
--
ALTER TABLE `business_invitation_locations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_invitation_location` (`invitation_id`,`location_id`),
  ADD KEY `idx_bil_location` (`location_id`);

--
-- Indici per le tabelle `business_users`
--
ALTER TABLE `business_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_business_user` (`business_id`,`user_id`),
  ADD KEY `fk_business_users_invited_by` (`invited_by`),
  ADD KEY `idx_business_users_user_active` (`user_id`,`is_active`),
  ADD KEY `idx_business_users_business_role` (`business_id`,`role`,`is_active`),
  ADD KEY `idx_business_users_staff` (`staff_id`);

--
-- Indici per le tabelle `business_user_locations`
--
ALTER TABLE `business_user_locations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_business_user_location` (`business_user_id`,`location_id`),
  ADD KEY `idx_bul_location` (`location_id`);

--
-- Indici per le tabelle `class_bookings`
--
ALTER TABLE `class_bookings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_class_bookings_business_event_customer` (`business_id`,`class_event_id`,`customer_id`),
  ADD KEY `idx_class_bookings_business_event_status` (`business_id`,`class_event_id`,`status`),
  ADD KEY `idx_class_bookings_business_customer_status` (`business_id`,`customer_id`,`status`),
  ADD KEY `idx_class_bookings_business_event_waitlist` (`business_id`,`class_event_id`,`waitlist_position`),
  ADD KEY `fk_class_bookings_event` (`class_event_id`),
  ADD KEY `fk_class_bookings_customer` (`customer_id`);

--
-- Indici per le tabelle `class_events`
--
ALTER TABLE `class_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_class_events_business_starts` (`business_id`,`starts_at`),
  ADD KEY `idx_class_events_business_staff_starts` (`business_id`,`staff_id`,`starts_at`),
  ADD KEY `idx_class_events_business_type_starts` (`business_id`,`class_type_id`,`starts_at`),
  ADD KEY `idx_class_events_business_status_starts` (`business_id`,`status`,`starts_at`),
  ADD KEY `fk_class_events_type` (`class_type_id`,`business_id`),
  ADD KEY `fk_class_events_location` (`location_id`),
  ADD KEY `fk_class_events_staff` (`staff_id`);

--
-- Indici per le tabelle `class_event_resource_requirements`
--
ALTER TABLE `class_event_resource_requirements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_class_event_resource` (`class_event_id`,`resource_id`),
  ADD KEY `idx_cerr_event` (`class_event_id`),
  ADD KEY `idx_cerr_resource` (`resource_id`);

--
-- Indici per le tabelle `class_types`
--
ALTER TABLE `class_types`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_class_types_id_business` (`id`,`business_id`),
  ADD UNIQUE KEY `uk_class_types_business_name` (`business_id`,`name`),
  ADD KEY `idx_class_types_business_active` (`business_id`,`is_active`);

--
-- Indici per le tabelle `class_type_locations`
--
ALTER TABLE `class_type_locations`
  ADD PRIMARY KEY (`class_type_id`,`location_id`),
  ADD KEY `idx_ctl_location_type` (`location_id`,`class_type_id`);

--
-- Indici per le tabelle `clients`
--
ALTER TABLE `clients`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_clients_business` (`business_id`),
  ADD KEY `idx_clients_business_email` (`business_id`,`email`),
  ADD KEY `idx_clients_business_phone` (`business_id`,`phone`),
  ADD KEY `idx_clients_business_archived` (`business_id`,`is_archived`),
  ADD KEY `idx_clients_user` (`user_id`),
  ADD KEY `idx_clients_email_auth` (`email`,`password_hash`);

--
-- Indici per le tabelle `client_sessions`
--
ALTER TABLE `client_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_client_sessions_token` (`refresh_token_hash`),
  ADD KEY `idx_client_sessions_client` (`client_id`),
  ADD KEY `idx_client_sessions_expires` (`expires_at`);

--
-- Indici per le tabelle `closures`
--
ALTER TABLE `closures`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_business_dates` (`business_id`,`start_date`,`end_date`);

--
-- Indici per le tabelle `closure_locations`
--
ALTER TABLE `closure_locations`
  ADD PRIMARY KEY (`closure_id`,`location_id`),
  ADD KEY `idx_location_closure` (`location_id`,`closure_id`);

--
-- Indici per le tabelle `locations`
--
ALTER TABLE `locations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_locations_business` (`business_id`),
  ADD KEY `idx_locations_business_default` (`business_id`,`is_default`),
  ADD KEY `idx_locations_postal_code` (`postal_code`),
  ADD KEY `idx_locations_cancellation` (`business_id`,`cancellation_hours`),
  ADD KEY `idx_locations_booking_limits` (`business_id`,`min_booking_notice_hours`,`max_booking_advance_days`);

--
-- Indici per le tabelle `location_schedules`
--
ALTER TABLE `location_schedules`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_location_schedules` (`location_id`,`day_of_week`);

--
-- Indici per le tabelle `notification_queue`
--
ALTER TABLE `notification_queue`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notification_pending` (`status`,`scheduled_at`,`priority`),
  ADD KEY `idx_notification_business` (`business_id`,`channel`),
  ADD KEY `idx_notification_booking` (`booking_id`),
  ADD KEY `idx_notification_recipient` (`recipient_type`,`recipient_id`);

--
-- Indici per le tabelle `notification_settings`
--
ALTER TABLE `notification_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_business` (`business_id`);

--
-- Indici per le tabelle `notification_templates`
--
ALTER TABLE `notification_templates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_business_channel_type` (`business_id`,`channel`,`type`);

--
-- Indici per le tabelle `password_reset_token_clients`
--
ALTER TABLE `password_reset_token_clients`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_client_password_reset_token` (`token_hash`),
  ADD KEY `idx_client_password_reset_client` (`client_id`),
  ADD KEY `idx_client_password_reset_expires` (`expires_at`);

--
-- Indici per le tabelle `password_reset_token_users`
--
ALTER TABLE `password_reset_token_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_password_reset_token` (`token_hash`),
  ADD KEY `idx_password_reset_user` (`user_id`),
  ADD KEY `idx_password_reset_expires` (`expires_at`);

--
-- Indici per le tabelle `popular_services`
--
ALTER TABLE `popular_services`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_popular_services_staff_rank` (`staff_id`,`rank`),
  ADD UNIQUE KEY `uk_popular_services_staff_service` (`staff_id`,`service_id`),
  ADD KEY `idx_popular_services_staff` (`staff_id`),
  ADD KEY `idx_popular_services_service` (`service_id`);

--
-- Indici per le tabelle `resources`
--
ALTER TABLE `resources`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_resources_location` (`location_id`);

--
-- Indici per le tabelle `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_services_business` (`business_id`),
  ADD KEY `idx_services_category` (`category_id`),
  ADD KEY `idx_services_sort` (`business_id`,`category_id`,`sort_order`);

--
-- Indici per le tabelle `service_categories`
--
ALTER TABLE `service_categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_service_categories_business` (`business_id`),
  ADD KEY `idx_service_categories_sort` (`business_id`,`sort_order`);

--
-- Indici per le tabelle `service_packages`
--
ALTER TABLE `service_packages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_service_packages_business_location` (`business_id`,`location_id`),
  ADD KEY `idx_service_packages_location` (`location_id`),
  ADD KEY `idx_service_packages_category` (`category_id`),
  ADD KEY `idx_service_packages_sort_order` (`sort_order`);

--
-- Indici per le tabelle `service_package_items`
--
ALTER TABLE `service_package_items`
  ADD PRIMARY KEY (`package_id`,`service_id`),
  ADD KEY `idx_service_package_items_package` (`package_id`),
  ADD KEY `idx_service_package_items_service` (`service_id`);

--
-- Indici per le tabelle `service_variants`
--
ALTER TABLE `service_variants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_service_variants_service_location` (`service_id`,`location_id`),
  ADD KEY `idx_service_variants_location` (`location_id`),
  ADD KEY `idx_service_variants_bookable` (`location_id`,`is_bookable_online`,`is_active`);

--
-- Indici per le tabelle `service_variant_resource_requirements`
--
ALTER TABLE `service_variant_resource_requirements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_variant_resource` (`service_variant_id`,`resource_id`),
  ADD KEY `idx_svrr_variant` (`service_variant_id`),
  ADD KEY `idx_svrr_resource` (`resource_id`);

--
-- Indici per le tabelle `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_staff_business` (`business_id`),
  ADD KEY `idx_staff_sort` (`business_id`,`sort_order`),
  ADD KEY `idx_staff_bookable` (`business_id`,`is_bookable_online`,`is_active`);

--
-- Indici per le tabelle `staff_availability_exceptions`
--
ALTER TABLE `staff_availability_exceptions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_staff_exceptions_staff` (`staff_id`),
  ADD KEY `idx_staff_exceptions_date` (`exception_date`),
  ADD KEY `idx_staff_exceptions_staff_date` (`staff_id`,`exception_date`);

--
-- Indici per le tabelle `staff_locations`
--
ALTER TABLE `staff_locations`
  ADD PRIMARY KEY (`staff_id`,`location_id`),
  ADD KEY `idx_staff_locations_location` (`location_id`);

--
-- Indici per le tabelle `staff_planning`
--
ALTER TABLE `staff_planning`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_staff_planning_staff_id` (`staff_id`),
  ADD KEY `idx_staff_planning_validity` (`staff_id`,`valid_from`,`valid_to`),
  ADD KEY `idx_staff_planning_valid_from` (`valid_from`);

--
-- Indici per le tabelle `staff_planning_week_template`
--
ALTER TABLE `staff_planning_week_template`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_planning_week_day` (`staff_planning_id`,`week_label`,`day_of_week`),
  ADD KEY `idx_week_template_planning_id` (`staff_planning_id`);

-- Indici per le tabelle `staff_services`
--
ALTER TABLE `staff_services`
  ADD PRIMARY KEY (`staff_id`,`service_id`),
  ADD KEY `idx_staff_services_service` (`service_id`);

--
-- Indici per le tabelle `time_blocks`
--
ALTER TABLE `time_blocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_time_blocks_business_location` (`business_id`,`location_id`),
  ADD KEY `idx_time_blocks_time` (`start_time`,`end_time`),
  ADD KEY `fk_time_blocks_location` (`location_id`);

--
-- Indici per le tabelle `time_block_staff`
--
ALTER TABLE `time_block_staff`
  ADD PRIMARY KEY (`time_block_id`,`staff_id`),
  ADD KEY `idx_time_block_staff_staff` (`staff_id`);

--
-- Indici per le tabelle `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_users_email` (`email`),
  ADD KEY `idx_users_active` (`is_active`),
  ADD KEY `idx_users_created` (`created_at`),
  ADD KEY `idx_users_superadmin` (`is_superadmin`);

--
-- Indici per le tabelle `webhook_deliveries`
--
ALTER TABLE `webhook_deliveries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_webhook_deliveries_endpoint` (`webhook_endpoint_id`),
  ADD KEY `idx_webhook_deliveries_retry` (`next_retry_at`,`delivered_at`,`failed_at`),
  ADD KEY `idx_webhook_deliveries_event` (`event_type`,`created_at`);

--
-- Indici per le tabelle `webhook_endpoints`
--
ALTER TABLE `webhook_endpoints`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_webhook_endpoints_business` (`business_id`),
  ADD KEY `idx_webhook_endpoints_active` (`business_id`,`is_active`);

--
-- AUTO_INCREMENT per le tabelle scaricate
--

--
-- AUTO_INCREMENT per la tabella `auth_sessions`
--
ALTER TABLE `auth_sessions`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `booking_events`
--
ALTER TABLE `booking_events`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `booking_items`
--
ALTER TABLE `booking_items`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `booking_recurrence_rules`
--
ALTER TABLE `booking_recurrence_rules`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `booking_replacements`
--
ALTER TABLE `booking_replacements`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `businesses`
--
ALTER TABLE `businesses`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `business_invitations`
--
ALTER TABLE `business_invitations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `business_invitation_locations`
--
ALTER TABLE `business_invitation_locations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `business_users`
--
ALTER TABLE `business_users`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `business_user_locations`
--
ALTER TABLE `business_user_locations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `class_bookings`
--
ALTER TABLE `class_bookings`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `class_events`
--
ALTER TABLE `class_events`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `class_event_resource_requirements`
--
ALTER TABLE `class_event_resource_requirements`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `class_types`
--
ALTER TABLE `class_types`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `clients`
--
ALTER TABLE `clients`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `client_sessions`
--
ALTER TABLE `client_sessions`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `closures`
--
ALTER TABLE `closures`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `locations`
--
ALTER TABLE `locations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `location_schedules`
--
ALTER TABLE `location_schedules`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `notification_queue`
--
ALTER TABLE `notification_queue`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `notification_settings`
--
ALTER TABLE `notification_settings`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `notification_templates`
--
ALTER TABLE `notification_templates`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `password_reset_token_clients`
--
ALTER TABLE `password_reset_token_clients`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `password_reset_token_users`
--
ALTER TABLE `password_reset_token_users`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `popular_services`
--
ALTER TABLE `popular_services`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `resources`
--
ALTER TABLE `resources`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `services`
--
ALTER TABLE `services`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `service_categories`
--
ALTER TABLE `service_categories`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `service_packages`
--
ALTER TABLE `service_packages`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `service_variants`
--
ALTER TABLE `service_variants`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `service_variant_resource_requirements`
--
ALTER TABLE `service_variant_resource_requirements`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `staff`
--
ALTER TABLE `staff`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `staff_availability_exceptions`
--
ALTER TABLE `staff_availability_exceptions`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `staff_planning`
--
ALTER TABLE `staff_planning`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `staff_planning_week_template`
--
ALTER TABLE `staff_planning_week_template`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

-- AUTO_INCREMENT per la tabella `time_blocks`
--
ALTER TABLE `time_blocks`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `users`
--
ALTER TABLE `users`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `webhook_deliveries`
--
ALTER TABLE `webhook_deliveries`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `webhook_endpoints`
--
ALTER TABLE `webhook_endpoints`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Limiti per le tabelle scaricate
--

--
-- Limiti per la tabella `auth_sessions`
--
ALTER TABLE `auth_sessions`
  ADD CONSTRAINT `fk_auth_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `fk_bookings_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bookings_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bookings_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bookings_recurrence` FOREIGN KEY (`recurrence_rule_id`) REFERENCES `booking_recurrence_rules` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_bookings_replaced_by_booking_id` FOREIGN KEY (`replaced_by_booking_id`) REFERENCES `bookings` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bookings_replaces_booking_id` FOREIGN KEY (`replaces_booking_id`) REFERENCES `bookings` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bookings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Limiti per la tabella `booking_events`
--
ALTER TABLE `booking_events`
  ADD CONSTRAINT `fk_booking_events_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Limiti per la tabella `booking_items`
--
ALTER TABLE `booking_items`
  ADD CONSTRAINT `fk_booking_items_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_booking_items_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_booking_items_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_booking_items_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_booking_items_variant` FOREIGN KEY (`service_variant_id`) REFERENCES `service_variants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Limiti per la tabella `booking_recurrence_rules`
--
ALTER TABLE `booking_recurrence_rules`
  ADD CONSTRAINT `fk_recurrence_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE;

--
-- Limiti per la tabella `booking_replacements`
--
ALTER TABLE `booking_replacements`
  ADD CONSTRAINT `fk_booking_replacements_new` FOREIGN KEY (`new_booking_id`) REFERENCES `bookings` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_booking_replacements_original` FOREIGN KEY (`original_booking_id`) REFERENCES `bookings` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Limiti per la tabella `business_invitations`
--
ALTER TABLE `business_invitations`
  ADD CONSTRAINT `fk_invitations_accepted_by` FOREIGN KEY (`accepted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_invitations_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_invitations_invited_by` FOREIGN KEY (`invited_by`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_invitations_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Limiti per la tabella `business_invitation_locations`
--
ALTER TABLE `business_invitation_locations`
  ADD CONSTRAINT `fk_bil_invitation` FOREIGN KEY (`invitation_id`) REFERENCES `business_invitations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bil_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `business_users`
--
ALTER TABLE `business_users`
  ADD CONSTRAINT `fk_business_users_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_business_users_invited_by` FOREIGN KEY (`invited_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_business_users_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_business_users_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Limiti per la tabella `business_user_locations`
--
ALTER TABLE `business_user_locations`
  ADD CONSTRAINT `fk_bul_business_user` FOREIGN KEY (`business_user_id`) REFERENCES `business_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bul_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `class_bookings`
--
ALTER TABLE `class_bookings`
  ADD CONSTRAINT `fk_class_bookings_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_class_bookings_customer` FOREIGN KEY (`customer_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_class_bookings_event` FOREIGN KEY (`class_event_id`) REFERENCES `class_events` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `class_events`
--
ALTER TABLE `class_events`
  ADD CONSTRAINT `fk_class_events_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_class_events_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_class_events_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_class_events_type` FOREIGN KEY (`class_type_id`,`business_id`) REFERENCES `class_types` (`id`, `business_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Limiti per la tabella `class_event_resource_requirements`
--
ALTER TABLE `class_event_resource_requirements`
  ADD CONSTRAINT `fk_cerr_event` FOREIGN KEY (`class_event_id`) REFERENCES `class_events` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cerr_resource` FOREIGN KEY (`resource_id`) REFERENCES `resources` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `class_types`
--
ALTER TABLE `class_types`
  ADD CONSTRAINT `fk_class_types_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `class_type_locations`
--
ALTER TABLE `class_type_locations`
  ADD CONSTRAINT `fk_ctl_class_type` FOREIGN KEY (`class_type_id`) REFERENCES `class_types` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ctl_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `clients`
--
ALTER TABLE `clients`
  ADD CONSTRAINT `fk_clients_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_clients_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Limiti per la tabella `client_sessions`
--
ALTER TABLE `client_sessions`
  ADD CONSTRAINT `fk_client_sessions_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `closures`
--
ALTER TABLE `closures`
  ADD CONSTRAINT `closures_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE;

--
-- Limiti per la tabella `closure_locations`
--
ALTER TABLE `closure_locations`
  ADD CONSTRAINT `closure_locations_ibfk_1` FOREIGN KEY (`closure_id`) REFERENCES `closures` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `closure_locations_ibfk_2` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE;

--
-- Limiti per la tabella `locations`
--
ALTER TABLE `locations`
  ADD CONSTRAINT `fk_locations_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `location_schedules`
--
ALTER TABLE `location_schedules`
  ADD CONSTRAINT `fk_location_schedules_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `notification_queue`
--
ALTER TABLE `notification_queue`
  ADD CONSTRAINT `fk_notification_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_notification_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Limiti per la tabella `notification_settings`
--
ALTER TABLE `notification_settings`
  ADD CONSTRAINT `fk_notification_settings_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `notification_templates`
--
ALTER TABLE `notification_templates`
  ADD CONSTRAINT `fk_notification_templates_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `password_reset_token_clients`
--
ALTER TABLE `password_reset_token_clients`
  ADD CONSTRAINT `fk_client_password_reset_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `password_reset_token_users`
--
ALTER TABLE `password_reset_token_users`
  ADD CONSTRAINT `fk_password_reset_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `popular_services`
--
ALTER TABLE `popular_services`
  ADD CONSTRAINT `fk_popular_services_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_popular_services_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `resources`
--
ALTER TABLE `resources`
  ADD CONSTRAINT `fk_resources_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `services`
--
ALTER TABLE `services`
  ADD CONSTRAINT `fk_services_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_services_category` FOREIGN KEY (`category_id`) REFERENCES `service_categories` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Limiti per la tabella `service_categories`
--
ALTER TABLE `service_categories`
  ADD CONSTRAINT `fk_service_categories_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `service_packages`
--
ALTER TABLE `service_packages`
  ADD CONSTRAINT `fk_service_packages_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_service_packages_category` FOREIGN KEY (`category_id`) REFERENCES `service_categories` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_service_packages_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `service_package_items`
--
ALTER TABLE `service_package_items`
  ADD CONSTRAINT `fk_service_package_items_package` FOREIGN KEY (`package_id`) REFERENCES `service_packages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_service_package_items_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Limiti per la tabella `service_variants`
--
ALTER TABLE `service_variants`
  ADD CONSTRAINT `fk_service_variants_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_service_variants_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `service_variant_resource_requirements`
--
ALTER TABLE `service_variant_resource_requirements`
  ADD CONSTRAINT `fk_svrr_resource` FOREIGN KEY (`resource_id`) REFERENCES `resources` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_svrr_variant` FOREIGN KEY (`service_variant_id`) REFERENCES `service_variants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `staff`
--
ALTER TABLE `staff`
  ADD CONSTRAINT `fk_staff_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `staff_availability_exceptions`
--
ALTER TABLE `staff_availability_exceptions`
  ADD CONSTRAINT `fk_staff_exceptions_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `staff_locations`
--
ALTER TABLE `staff_locations`
  ADD CONSTRAINT `fk_staff_locations_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_staff_locations_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `staff_planning`
--
ALTER TABLE `staff_planning`
  ADD CONSTRAINT `fk_staff_planning_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `staff_planning_week_template`
--
ALTER TABLE `staff_planning_week_template`
  ADD CONSTRAINT `fk_staff_planning_week_template_planning` FOREIGN KEY (`staff_planning_id`) REFERENCES `staff_planning` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- Limiti per la tabella `staff_services`
--
ALTER TABLE `staff_services`
  ADD CONSTRAINT `fk_staff_services_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_staff_services_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `time_blocks`
--
ALTER TABLE `time_blocks`
  ADD CONSTRAINT `fk_time_blocks_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_time_blocks_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `time_block_staff`
--
ALTER TABLE `time_block_staff`
  ADD CONSTRAINT `fk_time_block_staff_block` FOREIGN KEY (`time_block_id`) REFERENCES `time_blocks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_time_block_staff_staff` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `webhook_deliveries`
--
ALTER TABLE `webhook_deliveries`
  ADD CONSTRAINT `fk_webhook_deliveries_endpoint` FOREIGN KEY (`webhook_endpoint_id`) REFERENCES `webhook_endpoints` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `webhook_endpoints`
--
ALTER TABLE `webhook_endpoints`
  ADD CONSTRAINT `fk_webhook_endpoints_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
