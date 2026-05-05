-- phpMyAdmin SQL Migration
-- Date: 2026-05-05
-- Description: Add booking_direct_link_id to bookings table.
-- This persists the direct link context on bookings created via direct link,
-- allowing the frontend to reconstruct the correct booking URL for "Prenota di nuovo" CTAs.

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

DROP PROCEDURE IF EXISTS `migrate_20260505_bookings_direct_link_id`;

DELIMITER //

CREATE PROCEDURE `migrate_20260505_bookings_direct_link_id`()
BEGIN
    -- 1. Add column booking_direct_link_id if it does not already exist
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'bookings'
          AND COLUMN_NAME = 'booking_direct_link_id'
    ) THEN
        ALTER TABLE `bookings`
          ADD COLUMN `booking_direct_link_id` int UNSIGNED DEFAULT NULL
          COMMENT 'Direct link used to create this booking (nullable, FK to booking_direct_links)'
          AFTER `idempotency_expires_at`;
    END IF;

    -- 2. Add index if it does not already exist
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'bookings'
          AND INDEX_NAME = 'idx_bookings_booking_direct_link_id'
    ) THEN
        ALTER TABLE `bookings`
          ADD INDEX `idx_bookings_booking_direct_link_id` (`booking_direct_link_id`);
    END IF;

    -- 3. Add foreign key if it does not already exist
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'bookings'
          AND CONSTRAINT_NAME = 'fk_bookings_booking_direct_link_id'
    ) THEN
        ALTER TABLE `bookings`
          ADD CONSTRAINT `fk_bookings_booking_direct_link_id`
            FOREIGN KEY (`booking_direct_link_id`)
            REFERENCES `booking_direct_links`(`id`)
            ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END //

DELIMITER ;

CALL `migrate_20260505_bookings_direct_link_id`();

DROP PROCEDURE IF EXISTS `migrate_20260505_bookings_direct_link_id`;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

