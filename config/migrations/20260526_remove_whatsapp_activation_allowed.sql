-- Rimuove il flag ridondante business_whatsapp_settings.activation_allowed.
-- Da ora l'attivazione Meta dipende da whatsapp_enabled + allow_business_self_onboarding.

ALTER TABLE `business_whatsapp_settings`
  DROP INDEX `idx_bws_enabled_flags`;

ALTER TABLE `business_whatsapp_settings`
  DROP COLUMN `activation_allowed`;

ALTER TABLE `business_whatsapp_settings`
  ADD KEY `idx_bws_enabled_flags` (`whatsapp_enabled`, `messages_enabled`);
