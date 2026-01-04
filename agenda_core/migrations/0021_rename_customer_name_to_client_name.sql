-- Migration: Rinomina customer_name in client_name per coerenza con client_id
-- Data: 2026-01-04

-- Rinomina colonna nella tabella bookings
ALTER TABLE bookings CHANGE COLUMN customer_name client_name VARCHAR(200) NULL;
