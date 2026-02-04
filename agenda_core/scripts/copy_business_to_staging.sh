#!/bin/bash
# =============================================================================
# Script: copy_business_to_staging.sh
# Scopo: Copia tutti i dati di un business da produzione a staging
# Uso: ./scripts/copy_business_to_staging.sh <business_id>
# =============================================================================

set -e

# Colori output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurazione
SSH_HOST="romeolab"
DB_USER="ugucggguv4ij7"
DB_PASS='I0lqrdlr@##'
PROD_DB="db5hleekkbuuhm"
STAGING_DB="dbax2noxh5jpyb"

# Directory temporanea
TMP_DIR="/tmp/business_migration_$$"
mkdir -p "$TMP_DIR"

# Cleanup on exit
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Funzioni helper per eseguire comandi MySQL via SSH
run_mysql_prod() {
    ssh $SSH_HOST "mysql -u $DB_USER -p'$DB_PASS' -N $PROD_DB -e \"$1\"" 2>/dev/null
}

run_mysql_staging() {
    ssh $SSH_HOST "mysql -u $DB_USER -p'$DB_PASS' $STAGING_DB -e \"$1\"" 2>/dev/null
}

run_mysqldump_prod() {
    ssh $SSH_HOST "mysqldump -u $DB_USER -p'$DB_PASS' --no-create-info --skip-triggers --complete-insert $@" 2>/dev/null
}

# Verifica parametri
if [ -z "$1" ]; then
    echo -e "${RED}Errore: Specificare il business_id${NC}"
    echo "Uso: $0 <business_id>"
    echo ""
    echo "Business disponibili in produzione:"
    ssh $SSH_HOST "mysql -u $DB_USER -p'$DB_PASS' $PROD_DB -e 'SELECT id, name, slug FROM businesses;'" 2>/dev/null
    exit 1
fi

BUSINESS_ID=$1

echo -e "${YELLOW}=== Copia Business ID: $BUSINESS_ID da Produzione a Staging ===${NC}"
echo ""

# Verifica che il business esista in produzione
echo -e "${GREEN}[1/12] Verifico esistenza business in produzione...${NC}"
BUSINESS_EXISTS=$(run_mysql_prod "SELECT COUNT(*) FROM businesses WHERE id = $BUSINESS_ID;")
if [ "$BUSINESS_EXISTS" -eq 0 ]; then
    echo -e "${RED}Errore: Business ID $BUSINESS_ID non trovato in produzione${NC}"
    exit 1
fi

BUSINESS_NAME=$(run_mysql_prod "SELECT name FROM businesses WHERE id = $BUSINESS_ID;")
echo "  Business trovato: $BUSINESS_NAME"

# Ottieni lista location_ids per questo business
echo -e "${GREEN}[2/12] Raccolgo location IDs...${NC}"
LOCATION_IDS=$(run_mysql_prod "SELECT GROUP_CONCAT(id) FROM locations WHERE business_id = $BUSINESS_ID;")
echo "  Locations: $LOCATION_IDS"

if [ -z "$LOCATION_IDS" ] || [ "$LOCATION_IDS" == "NULL" ]; then
    echo -e "${YELLOW}  Nessuna location trovata${NC}"
    LOCATION_IDS=""
fi

# Ottieni staff_ids per questo business
echo -e "${GREEN}[3/12] Raccolgo staff IDs...${NC}"
STAFF_IDS=$(run_mysql_prod "SELECT GROUP_CONCAT(id) FROM staff WHERE business_id = $BUSINESS_ID;")
echo "  Staff: $STAFF_IDS"

# Ottieni client_ids associati al business
echo -e "${GREEN}[4/12] Raccolgo client IDs...${NC}"
CLIENT_IDS=$(run_mysql_prod "SELECT GROUP_CONCAT(id) FROM clients WHERE business_id = $BUSINESS_ID;")
echo "  Clients: ${CLIENT_IDS:-nessuno}"

# Ottieni user_ids degli admin/owner del business
echo -e "${GREEN}[5/12] Raccolgo user IDs (admin/owner)...${NC}"
USER_IDS=$(run_mysql_prod "SELECT GROUP_CONCAT(user_id) FROM business_users WHERE business_id = $BUSINESS_ID;")
echo "  Users: ${USER_IDS:-nessuno}"

# ============= ESPORTAZIONE DATI =============
echo ""
echo -e "${YELLOW}=== Esportazione dati da produzione ===${NC}"

# 1. Business
echo -e "${GREEN}[6/12] Esporto business...${NC}"
run_mysqldump_prod "--where=\"id = $BUSINESS_ID\" $PROD_DB businesses" > "$TMP_DIR/01_businesses.sql"

# 2. Users (admin del business)
if [ -n "$USER_IDS" ] && [ "$USER_IDS" != "NULL" ]; then
    echo -e "${GREEN}[6b/12] Esporto users...${NC}"
    run_mysqldump_prod "--where=\"id IN ($USER_IDS)\" $PROD_DB users" > "$TMP_DIR/02_users.sql"
fi

# 3. Business Users
echo -e "${GREEN}[6c/12] Esporto business_users...${NC}"
run_mysqldump_prod "--where=\"business_id = $BUSINESS_ID\" $PROD_DB business_users" > "$TMP_DIR/03_business_users.sql"

# 4. Locations
if [ -n "$LOCATION_IDS" ] && [ "$LOCATION_IDS" != "NULL" ]; then
    echo -e "${GREEN}[7/12] Esporto locations...${NC}"
    run_mysqldump_prod "--where=\"business_id = $BUSINESS_ID\" $PROD_DB locations" > "$TMP_DIR/04_locations.sql"
fi

# 5. Categories
echo -e "${GREEN}[7b/12] Esporto categories...${NC}"
run_mysqldump_prod "--where=\"business_id = $BUSINESS_ID\" $PROD_DB categories" > "$TMP_DIR/05_categories.sql"

# 6. Staff
if [ -n "$STAFF_IDS" ] && [ "$STAFF_IDS" != "NULL" ]; then
    echo -e "${GREEN}[8/12] Esporto staff...${NC}"
    run_mysqldump_prod "--where=\"business_id = $BUSINESS_ID\" $PROD_DB staff" > "$TMP_DIR/06_staff.sql"
fi

# 7. Services e Service Variants
if [ -n "$LOCATION_IDS" ] && [ "$LOCATION_IDS" != "NULL" ]; then
    echo -e "${GREEN}[8b/12] Esporto services...${NC}"
    run_mysqldump_prod "--where=\"location_id IN ($LOCATION_IDS)\" $PROD_DB services" > "$TMP_DIR/07_services.sql"
    
    # Service Variants
    SERVICE_IDS=$(run_mysql_prod "SELECT GROUP_CONCAT(id) FROM services WHERE location_id IN ($LOCATION_IDS);")
    if [ -n "$SERVICE_IDS" ] && [ "$SERVICE_IDS" != "NULL" ]; then
        run_mysqldump_prod "--where=\"service_id IN ($SERVICE_IDS)\" $PROD_DB service_variants" > "$TMP_DIR/08_service_variants.sql"
    fi
fi

# 8. Staff Services
if [ -n "$STAFF_IDS" ] && [ "$STAFF_IDS" != "NULL" ]; then
    echo -e "${GREEN}[8c/12] Esporto staff_services...${NC}"
    run_mysqldump_prod "--where=\"staff_id IN ($STAFF_IDS)\" $PROD_DB staff_services" > "$TMP_DIR/09_staff_services.sql"
fi

# 9. Staff Availability Exceptions
if [ -n "$STAFF_IDS" ] && [ "$STAFF_IDS" != "NULL" ]; then
    echo -e "${GREEN}[8d/12] Esporto staff_availability_exceptions...${NC}"
    run_mysqldump_prod "--where=\"staff_id IN ($STAFF_IDS)\" $PROD_DB staff_availability_exceptions" > "$TMP_DIR/10_staff_availability_exceptions.sql" || true
fi

# 10. Staff Planning
if [ -n "$STAFF_IDS" ] && [ "$STAFF_IDS" != "NULL" ]; then
    echo -e "${GREEN}[8e/12] Esporto staff_planning...${NC}"
    run_mysqldump_prod "--where=\"staff_id IN ($STAFF_IDS)\" $PROD_DB staff_planning" > "$TMP_DIR/11_staff_planning.sql" || true
    
    # Staff Planning Week Template
    PLANNING_IDS=$(run_mysql_prod "SELECT GROUP_CONCAT(id) FROM staff_planning WHERE staff_id IN ($STAFF_IDS);" || echo "")
    if [ -n "$PLANNING_IDS" ] && [ "$PLANNING_IDS" != "NULL" ]; then
        run_mysqldump_prod "--where=\"staff_planning_id IN ($PLANNING_IDS)\" $PROD_DB staff_planning_week_template" > "$TMP_DIR/12_staff_planning_week_template.sql" || true
    fi
fi

# 11. Clients
if [ -n "$CLIENT_IDS" ] && [ "$CLIENT_IDS" != "NULL" ]; then
    echo -e "${GREEN}[9/12] Esporto clients...${NC}"
    run_mysqldump_prod "--where=\"business_id = $BUSINESS_ID\" $PROD_DB clients" > "$TMP_DIR/13_clients.sql"
    
    # Client Sessions
    run_mysqldump_prod "--where=\"client_id IN ($CLIENT_IDS)\" $PROD_DB client_sessions" > "$TMP_DIR/14_client_sessions.sql" || true
fi

# 12. Resources
if [ -n "$LOCATION_IDS" ] && [ "$LOCATION_IDS" != "NULL" ]; then
    echo -e "${GREEN}[10/12] Esporto resources...${NC}"
    run_mysqldump_prod "--where=\"location_id IN ($LOCATION_IDS)\" $PROD_DB resources" > "$TMP_DIR/15_resources.sql" || true
fi

# 13. Time Blocks
if [ -n "$LOCATION_IDS" ] && [ "$LOCATION_IDS" != "NULL" ]; then
    echo -e "${GREEN}[10b/12] Esporto time_blocks...${NC}"
    run_mysqldump_prod "--where=\"location_id IN ($LOCATION_IDS)\" $PROD_DB time_blocks" > "$TMP_DIR/16_time_blocks.sql" || true
    
    # Time Block Staff
    BLOCK_IDS=$(run_mysql_prod "SELECT GROUP_CONCAT(id) FROM time_blocks WHERE location_id IN ($LOCATION_IDS);" || echo "")
    if [ -n "$BLOCK_IDS" ] && [ "$BLOCK_IDS" != "NULL" ]; then
        run_mysqldump_prod "--where=\"time_block_id IN ($BLOCK_IDS)\" $PROD_DB time_block_staff" > "$TMP_DIR/17_time_block_staff.sql" || true
    fi
fi

# 14. Bookings e Appointments
echo -e "${GREEN}[11/12] Esporto bookings e appointments...${NC}"
if [ -n "$STAFF_IDS" ] && [ "$STAFF_IDS" != "NULL" ]; then
    # Bookings attraverso appointments -> staff -> location
    run_mysqldump_prod "$PROD_DB bookings --where=\"id IN (SELECT DISTINCT booking_id FROM appointments WHERE staff_id IN ($STAFF_IDS) AND booking_id IS NOT NULL)\"" > "$TMP_DIR/18_bookings.sql" || true
    
    # Appointments
    run_mysqldump_prod "--where=\"staff_id IN ($STAFF_IDS)\" $PROD_DB appointments" > "$TMP_DIR/19_appointments.sql"
    
    # Appointment Services
    APPT_IDS=$(run_mysql_prod "SELECT GROUP_CONCAT(id) FROM appointments WHERE staff_id IN ($STAFF_IDS);")
    if [ -n "$APPT_IDS" ] && [ "$APPT_IDS" != "NULL" ]; then
        run_mysqldump_prod "--where=\"appointment_id IN ($APPT_IDS)\" $PROD_DB appointment_services" > "$TMP_DIR/20_appointment_services.sql"
    fi
fi

# ============= IMPORTAZIONE IN STAGING =============
echo ""
echo -e "${YELLOW}=== Importazione dati in staging ===${NC}"

# Prima elimino i dati esistenti per questo business in staging (in ordine inverso per FK)
echo -e "${GREEN}[12/12] Pulisco dati esistenti in staging...${NC}"

# Creo script di pulizia
cat > "$TMP_DIR/00_cleanup.sql" << EOF
SET FOREIGN_KEY_CHECKS = 0;

-- Elimina notification_queue per appointments del business
DELETE FROM notification_queue WHERE appointment_id IN (
    SELECT id FROM appointments WHERE staff_id IN (
        SELECT id FROM staff WHERE business_id = $BUSINESS_ID
    )
);

-- Elimina appointment_services per appointments del business
DELETE FROM appointment_services WHERE appointment_id IN (
    SELECT id FROM appointments WHERE staff_id IN (
        SELECT id FROM staff WHERE business_id = $BUSINESS_ID
    )
);

-- Elimina appointments
DELETE FROM appointments WHERE staff_id IN (
    SELECT id FROM staff WHERE business_id = $BUSINESS_ID
);

-- Elimina bookings orfani (solo quelli senza appointments)
DELETE FROM bookings WHERE id NOT IN (SELECT DISTINCT booking_id FROM appointments WHERE booking_id IS NOT NULL);

-- Elimina time_block_staff
DELETE FROM time_block_staff WHERE time_block_id IN (
    SELECT id FROM time_blocks WHERE location_id IN (
        SELECT id FROM locations WHERE business_id = $BUSINESS_ID
    )
);

-- Elimina time_blocks
DELETE FROM time_blocks WHERE location_id IN (
    SELECT id FROM locations WHERE business_id = $BUSINESS_ID
);

-- Elimina resources
DELETE FROM resources WHERE location_id IN (
    SELECT id FROM locations WHERE business_id = $BUSINESS_ID
);

-- Elimina staff_planning_week_template
DELETE FROM staff_planning_week_template WHERE staff_planning_id IN (
    SELECT id FROM staff_planning WHERE staff_id IN (
        SELECT id FROM staff WHERE business_id = $BUSINESS_ID
    )
);

-- Elimina staff_planning
DELETE FROM staff_planning WHERE staff_id IN (
    SELECT id FROM staff WHERE business_id = $BUSINESS_ID
);

-- Elimina staff_availability_exceptions
DELETE FROM staff_availability_exceptions WHERE staff_id IN (
    SELECT id FROM staff WHERE business_id = $BUSINESS_ID
);

-- Elimina staff_services
DELETE FROM staff_services WHERE staff_id IN (
    SELECT id FROM staff WHERE business_id = $BUSINESS_ID
);

-- Elimina service_variants
DELETE FROM service_variants WHERE service_id IN (
    SELECT id FROM services WHERE location_id IN (
        SELECT id FROM locations WHERE business_id = $BUSINESS_ID
    )
);

-- Elimina services
DELETE FROM services WHERE location_id IN (
    SELECT id FROM locations WHERE business_id = $BUSINESS_ID
);

-- Elimina staff
DELETE FROM staff WHERE business_id = $BUSINESS_ID;

-- Elimina password_reset_token_clients
DELETE FROM password_reset_token_clients WHERE client_id IN (
    SELECT id FROM clients WHERE business_id = $BUSINESS_ID
);

-- Elimina client_sessions
DELETE FROM client_sessions WHERE client_id IN (
    SELECT id FROM clients WHERE business_id = $BUSINESS_ID
);

-- Elimina clients
DELETE FROM clients WHERE business_id = $BUSINESS_ID;

-- Elimina categories
DELETE FROM categories WHERE business_id = $BUSINESS_ID;

-- Elimina locations
DELETE FROM locations WHERE business_id = $BUSINESS_ID;

-- Elimina business_users
DELETE FROM business_users WHERE business_id = $BUSINESS_ID;

-- Non elimino users perché potrebbero essere condivisi con altri business

-- Elimina business
DELETE FROM businesses WHERE id = $BUSINESS_ID;

SET FOREIGN_KEY_CHECKS = 1;
EOF

# Copia file su server ed esegui
echo "  Carico script di pulizia..."
scp -q "$TMP_DIR/00_cleanup.sql" "$SSH_HOST:/tmp/cleanup_$BUSINESS_ID.sql"
ssh $SSH_HOST "mysql -u $DB_USER -p'$DB_PASS' $STAGING_DB < /tmp/cleanup_$BUSINESS_ID.sql && rm /tmp/cleanup_$BUSINESS_ID.sql" 2>/dev/null

# Importa i dump in ordine corretto
echo "  Importo dati..."
for sql_file in "$TMP_DIR"/*.sql; do
    if [ -f "$sql_file" ] && [ -s "$sql_file" ]; then
        filename=$(basename "$sql_file")
        # Salta il cleanup già eseguito
        if [ "$filename" == "00_cleanup.sql" ]; then
            continue
        fi
        echo "    -> $filename"
        # Aggiungo SET per evitare problemi con FK
        (echo "SET FOREIGN_KEY_CHECKS = 0;" && cat "$sql_file" && echo "SET FOREIGN_KEY_CHECKS = 1;") | \
            ssh $SSH_HOST "mysql -u $DB_USER -p'$DB_PASS' $STAGING_DB" 2>/dev/null
    fi
done

echo ""
echo -e "${GREEN}=== Migrazione completata! ===${NC}"
echo ""
echo "Business '$BUSINESS_NAME' (ID: $BUSINESS_ID) copiato in staging."
echo ""
echo "URL di test:"
BUSINESS_SLUG=$(run_mysql_prod "SELECT slug FROM businesses WHERE id = $BUSINESS_ID;")
echo "  Frontend: https://prenota-staging.romeolab.it/$BUSINESS_SLUG/booking"
echo "  API:      https://api-staging.romeolab.it/v1/businesses/by-slug/$BUSINESS_SLUG"
echo ""
