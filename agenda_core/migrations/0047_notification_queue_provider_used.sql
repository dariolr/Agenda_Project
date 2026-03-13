ALTER TABLE `notification_queue`
  ADD COLUMN `provider_used` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
  NOT NULL DEFAULT 'smtp'
  COMMENT 'Actual provider used for delivery (smtp, brevo, mailgun, etc.)'
  AFTER `error_message`;
