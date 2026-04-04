ALTER TABLE `locations`
  ADD COLUMN `booking_default_locale` VARCHAR(10) NULL
  COMMENT 'Default booking UI locale for this location (it/en)'
  AFTER `timezone`;

