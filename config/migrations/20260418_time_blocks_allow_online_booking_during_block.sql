ALTER TABLE `time_blocks`
  ADD COLUMN `allow_online_booking_during_block` tinyint(1) NOT NULL DEFAULT '0' AFTER `is_all_day`;
