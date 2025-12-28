# Deploy Production — agenda_core

## Prerequisiti

- Server con PHP 8.2+ e PHP-FPM
- MySQL 8.0+ o MariaDB 10.6+
- Nginx o Apache
- Certificato SSL (Let's Encrypt consigliato)
- Dominio configurato (es. api.tuodominio.com)

---

## 1. Setup Server

### PHP Extensions richieste

```bash
sudo apt-get install php8.2-fpm php8.2-mysql php8.2-mbstring php8.2-xml php8.2-curl
```

### Composer dependencies

```bash
cd /var/www/agenda_core
composer install --no-dev --optimize-autoloader
```

---

## 2. Configurazione Nginx

File: `/etc/nginx/sites-available/agenda-api`

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.tuodominio.com;

    root /var/www/agenda_core/public;
    index index.php;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/api.tuodominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.tuodominio.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # CORS Headers (aggiustare origin per produzione)
    add_header Access-Control-Allow-Origin "https://app.tuodominio.com" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Idempotency-Key" always;
    add_header Access-Control-Allow-Credentials "true" always;
    add_header Access-Control-Max-Age "86400" always;

    # Handle OPTIONS preflight
    if ($request_method = 'OPTIONS') {
        return 204;
    }

    # Logging
    access_log /var/log/nginx/agenda-api-access.log;
    error_log /var/log/nginx/agenda-api-error.log;

    # PHP-FPM
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;

        # Security
        fastcgi_param PHP_VALUE "upload_max_filesize=10M \n post_max_size=10M";
        fastcgi_hide_header X-Powered-By;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Deny access to sensitive files
    location ~* \.(env|log|sql)$ {
        deny all;
    }
}

# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name api.tuodominio.com;
    return 301 https://$host$request_uri;
}
```

---

## 3. Configurazione Environment

File: `/var/www/agenda_core/.env` (NON committare!)

```bash
# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=agenda_core_prod
DB_USER=agenda_user
DB_PASS=STRONG_PASSWORD_HERE
DB_CHARSET=utf8mb4

# JWT
JWT_SECRET=GENERATE_RANDOM_256_BIT_SECRET_HERE
JWT_ACCESS_TTL=900      # 15 minutes
JWT_REFRESH_TTL=7776000  # 90 days

# Cookie Security
COOKIE_SECURE=true
COOKIE_SAME_SITE=Strict
COOKIE_DOMAIN=.tuodominio.com

# Logging
LOG_LEVEL=error
LOG_PATH=/var/log/agenda-api

# CORS
CORS_ALLOWED_ORIGINS=https://app.tuodominio.com,https://admin.tuodominio.com
```

### Generare JWT secret:

```bash
openssl rand -base64 64
```

---

## 4. Database Setup

```bash
# Creare utente dedicato
mysql -u root -p
CREATE USER 'agenda_user'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD';
CREATE DATABASE agenda_core_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON agenda_core_prod.* TO 'agenda_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Applicare schema completo (unico file)
mysql -u agenda_user -p agenda_core_prod < /var/www/agenda_core/migrations/FULL_DATABASE_SCHEMA.sql

# Seed solo se necessario (dati demo)
# mysql -u agenda_user -p agenda_core_prod < /var/www/agenda_core/migrations/seed_data.sql
```

---

## 5. Permessi

```bash
sudo chown -R www-data:www-data /var/www/agenda_core
sudo chmod -R 755 /var/www/agenda_core
sudo chmod 600 /var/www/agenda_core/.env
```

---

## 6. PHP-FPM Tuning

File: `/etc/php/8.2/fpm/pool.d/agenda.conf`

```ini
[agenda]
user = www-data
group = www-data
listen = /var/run/php/php8.2-agenda-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500

; PHP config
php_admin_value[error_log] = /var/log/php-fpm/agenda-error.log
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 256M
php_admin_value[upload_max_filesize] = 10M
php_admin_value[post_max_size] = 10M
```

```bash
sudo systemctl reload php8.2-fpm
```

---

## 7. Monitoraggio

### Health Check

```bash
curl https://api.tuodominio.com/health
```

Risposta attesa:
```json
{
  "status": "ok",
  "timestamp": "2025-12-27T10:00:00+01:00",
  "version": "1.0.0"
}
```

### Log Monitoring

```bash
# Nginx
tail -f /var/log/nginx/agenda-api-error.log

# PHP-FPM
tail -f /var/log/php-fpm/agenda-error.log

# Application (se configurato)
tail -f /var/log/agenda-api/app.log
```

---

## 8. Backup

### Database Backup Script

File: `/opt/scripts/backup-agenda-db.sh`

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/agenda-db"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/agenda_core_$DATE.sql.gz"

mkdir -p $BACKUP_DIR

mysqldump -u agenda_user -p'PASSWORD' agenda_core_prod | gzip > $BACKUP_FILE

# Keep only last 30 days
find $BACKUP_DIR -type f -mtime +30 -delete
```

Cron: `0 2 * * * /opt/scripts/backup-agenda-db.sh`

---

## 9. SSL Certificate (Let's Encrypt)

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d api.tuodominio.com
```

Auto-renewal:
```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

## 10. Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

---

## 11. Testing Deployment

```bash
# Health check
curl https://api.tuodominio.com/health

# Login test
curl -X POST https://api.tuodominio.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Services test
curl https://api.tuodominio.com/v1/services?location_id=1
```

---

## 12. Deploy SiteGround (Effettivo - 28/12/2025)

### Infrastruttura Produzione

| Componente | URL | Note |
|------------|-----|------|
| API Backend | https://api.romeolab.it | PHP 8.2 su SiteGround |
| Frontend Booking | https://prenota.romeolab.it | Flutter Web |
| Gestionale | https://gestionale.romeolab.it | Flutter Web (da deployare) |

### SSH Configuration (~/.ssh/config)

```
Host siteground
    HostName ssh.romeolab.it
    User u123-xxxxx
    Port 18765
    IdentityFile ~/.ssh/id_ed25519_siteground
```

### CORS (.env)

```
CORS_ALLOWED_ORIGINS=https://prenota.romeolab.it,https://gestionale.romeolab.it,http://localhost:8080
```

### Comandi Deploy

```bash
# API Backend (agenda_core)
rsync -avz --delete \
  --exclude='.env' \
  --exclude='logs/' \
  --exclude='.git/' \
  --exclude='tests/' \
  /path/to/agenda_core/ \
  siteground:www/api.romeolab.it/

# Frontend Booking (agenda_frontend)
cd agenda_frontend
flutter build web --release --dart-define=API_BASE_URL=https://api.romeolab.it
rsync -avz --delete build/web/ siteground:www/prenota.romeolab.it/public_html/

# Gestionale (agenda_backend)
cd agenda_backend
flutter build web --release --dart-define=API_BASE_URL=https://api.romeolab.it
rsync -avz --delete build/web/ siteground:www/gestionale.romeolab.it/public_html/
```

### Verifica Deploy

```bash
# Test API
curl https://api.romeolab.it/v1/services?location_id=1

# Test CORS
curl -I -X OPTIONS https://api.romeolab.it/v1/services \
  -H "Origin: https://prenota.romeolab.it"
```

---

## Checklist Pre-Launch

- [x] Database migrations applicate (0001-0014)
- [x] .env configurato con valori produzione
- [x] JWT secret generato e configurato
- [x] CORS limitato ai domini reali
- [x] HTTPS obbligatorio (SiteGround SSL)
- [x] Certificato SSL valido (Let's Encrypt)
- [ ] Backup database configurato
- [ ] Log monitoring attivo
- [x] Health check funzionante
- [x] Permessi file corretti (600 per .env)
- [x] Frontend deployato e funzionante
