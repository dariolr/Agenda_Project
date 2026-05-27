-- Rimuove il flag ridondante business_whatsapp_settings.allow_business_self_onboarding.
-- Da ora l'onboarding Meta e' consentito quando whatsapp_enabled = 1.

ALTER TABLE `business_whatsapp_settings`
  DROP COLUMN `allow_business_self_onboarding`;
