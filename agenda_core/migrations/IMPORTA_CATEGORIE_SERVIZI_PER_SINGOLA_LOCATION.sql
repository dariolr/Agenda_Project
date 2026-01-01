START TRANSACTION;

SET @BUSINESS_ID := 1;
SET @LOCATION_ID := 4;

-- =========================================================
-- CLEANUP MIRATO
-- =========================================================
DELETE sv
FROM service_variants sv
JOIN services s ON s.id = sv.service_id
WHERE s.business_id = @BUSINESS_ID
  AND sv.location_id = @LOCATION_ID;

DELETE FROM services WHERE business_id = @BUSINESS_ID;
DELETE FROM service_categories WHERE business_id = @BUSINESS_ID;

-- =========================================================
-- CATEGORIE
-- =========================================================
INSERT INTO service_categories (business_id, name, sort_order) VALUES
(@BUSINESS_ID, 'AD USO INTERNO', 1),
(@BUSINESS_ID, 'PARRUCCHIERE DONNA', 2),
(@BUSINESS_ID, 'PARRUCCHIERE UOMO', 3);

-- =========================================================
-- SERVIZI + VARIANTI (ORDINE CSV)
-- =========================================================

-- 1 colore+taglio+piega lunga - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'colore+taglio+piega lunga', 1
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='AD USO INTERNO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 155, 70.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='colore+taglio+piega lunga';

-- 2 Balayage + piega - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'Balayage + piega', 2
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='AD USO INTERNO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 135, 95.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='Balayage + piega';

-- 3 trattamento condizionante con electronic master
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'trattamento condizionante con electronic master', 3
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='AD USO INTERNO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 10, 8.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='trattamento condizionante con electronic master';

-- 4 taglio+piega lunga
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'taglio+piega lunga', 4
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='AD USO INTERNO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 85, 40.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='taglio+piega lunga';

-- 5 Tonalizzante / riflessante
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'Tonalizzante / riflessante', 5
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='AD USO INTERNO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 25, 20.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='Tonalizzante / riflessante';

-- 6 Balayage - From (processing 120)
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'Balayage', 6
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='AD USO INTERNO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, processing_time, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 90, 120, 80.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='Balayage';

-- 7 colpi di sole - From (processing 50)
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'colpi di sole', 7
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='AD USO INTERNO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, processing_time, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 60, 50, 55.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='colpi di sole';

-- 8 Colore senza ammoniaca - From (processing 45)
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'Colore senza ammoniaca', 8
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='AD USO INTERNO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, processing_time, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 20, 45, 40.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='Colore senza ammoniaca';

-- 9 colore - From (processing 45)
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'colore', 9
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='AD USO INTERNO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, processing_time, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 25, 45, 30.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='colore';

-- 10 taglio donna
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'taglio donna', 10
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='AD USO INTERNO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 25, 20.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='taglio donna';

-- 11 taglio+shampoo
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'taglio+shampoo', 11
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE UOMO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 30, 15.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='taglio+shampoo';

-- 12 taglio+barba+shampoo
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'taglio+barba+shampoo', 12
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE UOMO';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 45, 25.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='taglio+barba+shampoo';

-- 13 Balayage + piega + riflessante - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'Balayage + piega + riflessante', 13
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 160, 115.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='Balayage + piega + riflessante';

-- 14 piega corta
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'piega corta', 14
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 35, 13.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='piega corta';

-- 15 Piega lunga
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'Piega lunga', 15
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 45, 15.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='Piega lunga';

-- 16 Piega twist
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'Piega twist', 16
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 45, 18.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='Piega twist';

-- 17 Tonalizzante + piega
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'Tonalizzante + piega', 17
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 70, 35.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='Tonalizzante + piega';

-- 18 trattamento condizionante con electronic master + piega
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'trattamento condizionante con electronic master + piega', 18
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 55, 23.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='trattamento condizionante con electronic master + piega';

-- 19 taglio+piega
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'taglio+piega', 19
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price)
SELECT s.id, @LOCATION_ID, 70, 35.00 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='taglio+piega';

-- 20 colore+piega - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'colore+piega', 20
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 100, 45.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='colore+piega';

-- 21 colore+taglio+piega - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'colore+taglio+piega', 21
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 140, 65.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='colore+taglio+piega';

-- 22 colore senza ammoniaca+piega - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'colore senza ammoniaca+piega', 22
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 110, 55.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='colore senza ammoniaca+piega';

-- 23 colore senza ammoniaca+ taglio+ piega - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'colore senza ammoniaca+ taglio+ piega', 23
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 135, 75.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='colore senza ammoniaca+ taglio+ piega';

-- 24 colpi di sole + piega - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'colpi di sole + piega', 24
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 155, 70.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='colpi di sole + piega';

-- 25 colpi di sole + taglio + piega - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'colpi di sole + taglio + piega', 25
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 180, 90.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='colpi di sole + taglio + piega';

-- 26 balayage + riflessante + piega - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'balayage + riflessante + piega', 26
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 280, 115.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='balayage + riflessante + piega';

-- 27 balayage + riflessante + taglio + piega - From
INSERT INTO services (business_id, category_id, name, sort_order)
SELECT @BUSINESS_ID, id, 'balayage + riflessante + taglio + piega', 27
FROM service_categories WHERE business_id=@BUSINESS_ID AND name='PARRUCCHIERE DONNA';
INSERT INTO service_variants (service_id, location_id, duration_minutes, price, is_price_starting_from)
SELECT s.id, @LOCATION_ID, 305, 135.00, 1 FROM services s WHERE s.business_id=@BUSINESS_ID AND s.name='balayage + riflessante + taglio + piega';

COMMIT;
  