<?php
const FRESHA_CONFIG = array (
  'business_id' => 25,
  'location_id' => 28,
  'csv_clients' => 'export_customer_list.csv',
  'csv_services' => 'export_service_list.csv',
  'csv_staff' => '',
  'skip_blocked_clients' => false,
  'dry_run' => true,
  // Elimina dati esistenti prima di importare (per rieseguire migrazione pulita)
  'clear_existing_data' => true,
);
return FRESHA_CONFIG;
