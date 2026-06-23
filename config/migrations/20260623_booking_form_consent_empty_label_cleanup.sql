UPDATE booking_form_fields
SET label = ''
WHERE field_type = 'consent'
  AND label = 'Campo';
