-- Disabilita gli invii WhatsApp diversi dal promemoria appuntamento.
-- Non elimina i template: li marca come disabled.

UPDATE `whatsapp_templates`
SET `status` = 'disabled',
    `updated_at` = NOW()
WHERE COALESCE(`message_type`, '') <> 'booking_reminder'
  AND `status` <> 'disabled';
