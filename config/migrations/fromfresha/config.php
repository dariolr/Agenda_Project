<?php
const FRESHA_CONFIG = array (
  'business_id' => 12,
  'location_id' => 12,
  'csv_clients' => 'export_customer_list.csv',
  'csv_services' => '',
  'csv_staff' => '',
  'skip_blocked_clients' => false,
  'dry_run' => false,
  // Elimina dati esistenti prima di importare (per rieseguire migrazione pulita)
  'clear_existing_data' => true,
);
return FRESHA_CONFIG;
