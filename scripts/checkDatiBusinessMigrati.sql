SELECT 
    a.name,
    CASE WHEN NOT EXISTS (SELECT 1 FROM staff WHERE business_id = a.id) THEN 'NO STAFF' ELSE 'OK' END AS staff,
    CASE WHEN NOT EXISTS (SELECT 1 FROM services WHERE business_id = a.id) THEN 'NO SERVICES' ELSE 'OK' END AS services,
    CASE WHEN NOT EXISTS (SELECT 1 FROM clients WHERE business_id = a.id) THEN 'NO CLIENTS' ELSE 'OK' END AS clients,
    CASE WHEN NOT EXISTS (
        SELECT 1 FROM staff s 
        INNER JOIN staff_planning sp ON sp.staff_id = s.id 
        INNER JOIN staff_planning_week_template spwt ON spwt.staff_planning_id = sp.id 
        WHERE s.business_id = a.id
    ) THEN 'NO AVAILABILITY' ELSE 'OK' END AS availability
FROM businesses a
HAVING staff = 'NO STAFF' OR services = 'NO SERVICES' OR clients = 'NO CLIENTS' OR availability = 'NO AVAILABILITY';