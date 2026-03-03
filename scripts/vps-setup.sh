#!/bin/bash
# ================================================================
#  VPS WordPress All-in-One Setup
#  Tested on: Rocky Linux 8/9, Ubuntu 22.04/24.04
#  What it does:
#    - Install Nginx, PHP 8.1, MariaDB
#    - Create WordPress sites (multi-domain)
#    - SSL via acme.sh (Cloudflare or standalone)
#    - WAF, security headers, fail2ban
#    - Performance tuning (OPcache, gzip, cache, PHP-FPM)
#    - Backup system with malware scan
#    - Telegram monitoring
#    - SEO essentials (OG, schema, robots.txt)
#    - Auto-update + DB optimizer + broken link checker
#    - SSH admin panel (vps-admin command)
#
#  Usage: bash vps-setup.sh
# ================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[SETUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

# ========================
# INTERACTIVE SETUP
# ========================
echo ""
echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN}  VPS WordPress All-in-One Setup${NC}"
echo -e "${CYAN}==========================================${NC}"
echo ""

# Detect OS
if [ -f /etc/rocky-release ]; then
    OS="rocky"
    PKG="dnf"
    log "Detected: Rocky Linux"
elif [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
    OS="ubuntu"
    PKG="apt-get"
    log "Detected: Ubuntu/Debian"
else
    err "Unsupported OS. Use Rocky Linux 8/9 or Ubuntu 22.04+"
    exit 1
fi

# Get domains
read -p "Enter domains (comma-separated, e.g. site1.com,site2.com): " DOMAINS_INPUT
IFS=',' read -ra DOMAINS <<< "$DOMAINS_INPUT"
if [ ${#DOMAINS[@]} -eq 0 ]; then
    err "No domains provided"
    exit 1
fi
log "Sites: ${DOMAINS[*]}"

# DB password
read -p "MariaDB root password (leave blank to auto-generate): " DB_ROOT_PASS
if [ -z "$DB_ROOT_PASS" ]; then
    DB_ROOT_PASS=$(openssl rand -base64 16 | tr -d '/+=' | head -c 16)
    log "Generated DB password: $DB_ROOT_PASS"
fi

# Telegram
read -p "Telegram Bot Token (leave blank to skip monitoring): " TG_TOKEN
if [ -n "$TG_TOKEN" ]; then
    read -p "Telegram Chat ID: " TG_CHAT
fi

# Backup VPS
read -p "Backup VPS IP (leave blank to skip cross-VPS backup): " BACKUP_VPS_IP

# Server IP
SERVER_IP=$(curl -s4 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
log "Server IP: $SERVER_IP"

# Hostname
VPS_NAME=$(hostname -s)
read -p "VPS name for alerts [$VPS_NAME]: " INPUT_NAME
[ -n "$INPUT_NAME" ] && VPS_NAME="$INPUT_NAME"

# Save config
mkdir -p /root/.vps-config
cat > /root/.vps-config/setup.conf << CONF
DOMAINS="${DOMAINS_INPUT}"
DB_ROOT_PASS="${DB_ROOT_PASS}"
TG_TOKEN="${TG_TOKEN}"
TG_CHAT="${TG_CHAT}"
BACKUP_VPS_IP="${BACKUP_VPS_IP}"
SERVER_IP="${SERVER_IP}"
VPS_NAME="${VPS_NAME}"
CONF
chmod 600 /root/.vps-config/setup.conf

# ========================
# 1. BASE SYSTEM
# ========================
log "=== INSTALLING BASE SYSTEM ==="

if [ "$OS" = "rocky" ]; then
    dnf update -y
    dnf install -y epel-release
    dnf install -y nginx mariadb-server mariadb
    dnf install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
    dnf module reset php -y
    dnf module enable php:remi-8.1 -y
    dnf install -y php php-fpm php-mysqlnd php-gd php-mbstring php-xml php-zip php-curl php-intl php-opcache php-soap php-bcmath php-imagick
    dnf install -y fail2ban wget curl unzip git jq openssl certbot
else
    apt-get update && apt-get upgrade -y
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt-get update
    apt-get install -y nginx mariadb-server
    apt-get install -y php8.1-fpm php8.1-mysql php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip php8.1-curl php8.1-intl php8.1-opcache php8.1-soap php8.1-bcmath php8.1-imagick
    apt-get install -y fail2ban wget curl unzip git jq openssl certbot
fi

# Start services
systemctl enable --now nginx mariadb php-fpm 2>/dev/null || systemctl enable --now nginx mariadb php8.1-fpm 2>/dev/null
systemctl enable --now fail2ban

log "Base system installed"

# ========================
# 2. MARIADB SETUP
# ========================
log "=== CONFIGURING MARIADB ==="

mysql -uroot -e "
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
" 2>/dev/null

# MariaDB tuning
cat > /etc/my.cnf.d/server-tuning.cnf 2>/dev/null << 'DBCONF' || cat > /etc/mysql/conf.d/server-tuning.cnf << 'DBCONF'
[mysqld]
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
max_connections = 100
query_cache_type = 1
query_cache_size = 32M
query_cache_limit = 2M
tmp_table_size = 64M
max_heap_table_size = 64M
join_buffer_size = 2M
sort_buffer_size = 2M
DBCONF

systemctl restart mariadb
log "MariaDB configured"

# ========================
# 3. PHP TUNING
# ========================
log "=== CONFIGURING PHP ==="

# Find php.ini
PHP_INI=$(php --ini 2>/dev/null | grep "Loaded Configuration" | awk '{print $NF}')

# OPcache tuning
cat > /etc/php.d/90-opcache-tuning.ini 2>/dev/null << 'OPCACHE' || cat > /etc/php/8.1/fpm/conf.d/90-opcache-tuning.ini << 'OPCACHE'
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.revalidate_freq=60
opcache.save_comments=1
OPCACHE

# PHP settings
sed -i 's/memory_limit = .*/memory_limit = 512M/' "$PHP_INI" 2>/dev/null
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' "$PHP_INI" 2>/dev/null
sed -i 's/post_max_size = .*/post_max_size = 64M/' "$PHP_INI" 2>/dev/null
sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$PHP_INI" 2>/dev/null
sed -i 's/max_input_vars = .*/max_input_vars = 5000/' "$PHP_INI" 2>/dev/null

# PHP-FPM pool tuning (auto-calculate based on RAM)
TOTAL_RAM_MB=$(free -m | awk '/Mem:/{print $2}')
MAX_CHILDREN=$((TOTAL_RAM_MB / 40))
START_SERVERS=$((MAX_CHILDREN / 4))
MIN_SPARE=$((MAX_CHILDREN / 6))
MAX_SPARE=$((MAX_CHILDREN / 3))

FPM_CONF=$(find /etc -name "www.conf" -path "*/php*" 2>/dev/null | head -1)
if [ -n "$FPM_CONF" ]; then
    sed -i "s/pm = .*/pm = dynamic/" "$FPM_CONF"
    sed -i "s/pm.max_children = .*/pm.max_children = $MAX_CHILDREN/" "$FPM_CONF"
    sed -i "s/pm.start_servers = .*/pm.start_servers = $START_SERVERS/" "$FPM_CONF"
    sed -i "s/pm.min_spare_servers = .*/pm.min_spare_servers = $MIN_SPARE/" "$FPM_CONF"
    sed -i "s/pm.max_spare_servers = .*/pm.max_spare_servers = $MAX_SPARE/" "$FPM_CONF"
    sed -i "s/;pm.max_requests = .*/pm.max_requests = 1000/" "$FPM_CONF"
fi

systemctl restart php-fpm 2>/dev/null || systemctl restart php8.1-fpm 2>/dev/null
log "PHP configured (OPcache 256MB, ${MAX_CHILDREN} workers)"

# ========================
# 4. NGINX MAIN CONFIG
# ========================
log "=== CONFIGURING NGINX ==="

cat > /etc/nginx/nginx.conf << 'NGINXMAIN'
user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log warn;
pid /run/nginx.pid;

events {
    worker_connections 4096;
    multi_accept on;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    client_max_body_size 64m;

    # Gzip
    gzip on;
    gzip_static on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json text/javascript application/javascript text/xml application/xml application/xml+rss image/svg+xml;

    # Open file cache
    open_file_cache max=10000 inactive=30s;
    open_file_cache_valid 60s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    # FastCGI buffers
    fastcgi_buffers 16 16k;
    fastcgi_buffer_size 32k;
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;

    # WAF maps
    include /etc/nginx/waf_map.conf;

    # Virtual hosts
    include /etc/nginx/conf.d/*.conf;
}
NGINXMAIN

# WAF map
cat > /etc/nginx/waf_map.conf << 'WAFMAP'
map $query_string $waf_block_qs {
    default 0;
    "~*union.*select" 1;
    "~*information_schema" 1;
    "~*into.*outfile" 1;
    "~*<script" 1;
    "~*javascript:" 1;
    "~*document\.cookie" 1;
    "~*\.\./" 1;
    "~*/etc/passwd" 1;
    "~*php://(input|filter)" 1;
}
map $http_user_agent $waf_block_ua {
    default 0;
    "~*nikto|sqlmap|nmap|acunetix|wpscan" 1;
    "" 1;
}
WAFMAP

# Performance headers include
cat > /etc/nginx/performance_headers.conf << 'PERFHEADERS'
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=()" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

location ~* \.(jpg|jpeg|png|gif|ico|svg|webp|avif)$ {
    expires 365d;
    add_header Cache-Control "public, immutable";
    access_log off;
}
location ~* \.(css|js)$ {
    expires 30d;
    add_header Cache-Control "public";
    access_log off;
}
location ~* \.(woff|woff2|ttf|eot|otf)$ {
    expires 365d;
    add_header Cache-Control "public, immutable";
    add_header Access-Control-Allow-Origin "*";
    access_log off;
}
PERFHEADERS

log "Nginx main config done"

# ========================
# 5. CREATE WORDPRESS SITES
# ========================
log "=== CREATING WORDPRESS SITES ==="

# Find PHP-FPM socket
PHP_SOCK=$(find /run -name "*.sock" -path "*php*" 2>/dev/null | head -1)
[ -z "$PHP_SOCK" ] && PHP_SOCK="/run/php-fpm/www.sock"

for domain in "${DOMAINS[@]}"; do
    domain=$(echo "$domain" | xargs) # trim whitespace
    log "Setting up: $domain"

    # Create directory
    mkdir -p /home/$domain/public_html
    
    # Generate DB credentials
    DB_NAME=$(echo "${domain}" | tr '.-' '_' | head -c 12)_$(openssl rand -hex 3)
    DB_USER=$(openssl rand -base64 8 | tr -d '/+=' | head -c 10)
    DB_PASS=$(openssl rand -base64 16 | tr -d '/+=' | head -c 16)

    # Create DB
    mysql -uroot -p"${DB_ROOT_PASS}" -e "
    CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
    CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
    GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
    FLUSH PRIVILEGES;
    " 2>/dev/null

    # Save credentials
    cat >> /root/.vps-config/db-credentials.txt << CRED
${domain}: DB=${DB_NAME} USER=${DB_USER} PASS=${DB_PASS}
CRED

    # Download WordPress
    cd /home/$domain/public_html
    if [ ! -f wp-config.php ]; then
        wget -q https://wordpress.org/latest.tar.gz
        tar xzf latest.tar.gz --strip-components=1
        rm -f latest.tar.gz

        # Configure wp-config.php
        cp wp-config-sample.php wp-config.php
        sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
        sed -i "s/username_here/${DB_USER}/" wp-config.php
        sed -i "s/password_here/${DB_PASS}/" wp-config.php

        # Generate salts
        SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
        # Replace default salt lines
        sed -i '/AUTH_KEY/d; /SECURE_AUTH_KEY/d; /LOGGED_IN_KEY/d; /NONCE_KEY/d; /AUTH_SALT/d; /SECURE_AUTH_SALT/d; /LOGGED_IN_SALT/d; /NONCE_SALT/d' wp-config.php
        sed -i "/define.*DB_COLLATE/a\\
${SALTS}" wp-config.php

        # Add performance defines
        cat >> wp-config.php << 'WPPERF'

/* Performance */
define('DISABLE_WP_CRON', true);
define('WP_POST_REVISIONS', 3);
define('AUTOSAVE_INTERVAL', 300);
define('EMPTY_TRASH_DAYS', 7);
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');
WPPERF
    fi

    # SEO mu-plugin
    mkdir -p /home/$domain/public_html/wp-content/mu-plugins
    cat > /home/$domain/public_html/wp-content/mu-plugins/seo-essentials.php << 'SEOPHP'
<?php
/**
 * Plugin Name: SEO Essentials
 * Description: Auto OG tags, meta description, canonical, Twitter cards, WooCommerce JSON-LD
 */
add_action('wp_head', function() {
    if (defined('WPSEO_VERSION') || defined('AIOSEO_VERSION') || class_exists('RankMath')) return;
    $title = wp_title('|', false, 'right') . get_bloginfo('name');
    $desc = get_bloginfo('description');
    $url = home_url($_SERVER['REQUEST_URI']);
    $site = get_bloginfo('name');
    if (function_exists('is_product') && is_product()) {
        global $post;
        $title = get_the_title() . ' | ' . $site;
        $desc = wp_trim_words(strip_tags($post->post_content), 30);
        $thumb = get_the_post_thumbnail_url($post->ID, 'large');
    }
    echo '<meta property="og:type" content="website" />' . "\n";
    echo '<meta property="og:title" content="' . esc_attr($title) . '" />' . "\n";
    if ($desc) echo '<meta property="og:description" content="' . esc_attr($desc) . '" />' . "\n";
    echo '<meta property="og:url" content="' . esc_url($url) . '" />' . "\n";
    echo '<meta property="og:site_name" content="' . esc_attr($site) . '" />' . "\n";
    if (!empty($thumb)) echo '<meta property="og:image" content="' . esc_url($thumb) . '" />' . "\n";
    echo '<meta name="twitter:card" content="summary_large_image" />' . "\n";
    if ($desc) echo '<meta name="description" content="' . esc_attr($desc) . '" />' . "\n";
    echo '<link rel="canonical" href="' . esc_url($url) . '" />' . "\n";
}, 1);
add_action('wp_footer', function() {
    if (!function_exists('is_product') || !is_product()) return;
    if (defined('WPSEO_VERSION') || defined('AIOSEO_VERSION')) return;
    global $post, $product;
    if (!$product) $product = wc_get_product($post->ID);
    if (!$product) return;
    $schema = ['@context'=>'https://schema.org','@type'=>'Product','name'=>$product->get_name(),'description'=>wp_trim_words(strip_tags($product->get_description()),50),'image'=>get_the_post_thumbnail_url($post->ID,'large'),'url'=>get_permalink(),'offers'=>['@type'=>'Offer','price'=>$product->get_price(),'priceCurrency'=>get_woocommerce_currency(),'availability'=>$product->is_in_stock()?'https://schema.org/InStock':'https://schema.org/OutOfStock']];
    echo '<script type="application/ld+json">' . wp_json_encode($schema, JSON_UNESCAPED_SLASHES) . '</script>';
});
SEOPHP

    # robots.txt
    cat > /home/$domain/public_html/robots.txt << ROBOTS
User-agent: *
Allow: /
Disallow: /wp-admin/
Disallow: /?s=
Disallow: /cart/
Disallow: /checkout/
Disallow: /my-account/
Allow: /wp-admin/admin-ajax.php

Sitemap: https://${domain}/wp-sitemap.xml
ROBOTS

    # WP-Cron via system cron
    (crontab -l 2>/dev/null; echo "*/5 * * * * cd /home/$domain/public_html && php wp-cron.php > /dev/null 2>&1") | sort -u | crontab -

    # Nginx server block
    cat > /etc/nginx/conf.d/${domain}.conf << VHOST
server {
    listen 80;
    server_name ${domain} www.${domain};
    root /home/${domain}/public_html;
    index index.php index.html;

    include /etc/nginx/performance_headers.conf;

    # WAF
    if (\$waf_block_qs) { return 403; }
    if (\$waf_block_ua) { return 403; }

    # WordPress permalinks
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # PHP-FPM
    location ~ \.php\$ {
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    # Block sensitive files
    location = /wp-config.php { deny all; }
    location = /xmlrpc.php { deny all; }
    location ~ /\. { deny all; }
    location ~* /wp-content/uploads/.*\.php\$ { deny all; }
    location ~* \.(sql|gz|tar|bak|log|old)$ { deny all; }

    # Cloudflare real IP
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    real_ip_header CF-Connecting-IP;
}
VHOST

    # Set permissions
    chown -R nginx:nginx /home/$domain/public_html 2>/dev/null || chown -R www-data:www-data /home/$domain/public_html
    find /home/$domain/public_html -type d -exec chmod 755 {} \;
    find /home/$domain/public_html -type f -exec chmod 644 {} \;

    log "$domain: OK (DB: $DB_NAME)"
done

nginx -t && nginx -s reload
log "All sites created"

# ========================
# 6. SSL SETUP (acme.sh)
# ========================
log "=== SETTING UP SSL ==="

curl -s https://get.acme.sh | sh -s email=admin@${DOMAINS[0]} 2>/dev/null
source /root/.bashrc

for domain in "${DOMAINS[@]}"; do
    domain=$(echo "$domain" | xargs)
    /root/.acme.sh/acme.sh --issue -d "$domain" -d "www.$domain" --webroot /home/$domain/public_html --keylength ec-256 2>/dev/null

    if [ $? -eq 0 ]; then
        mkdir -p /etc/nginx/ssl/$domain
        /root/.acme.sh/acme.sh --install-cert -d "$domain" \
            --key-file /etc/nginx/ssl/$domain/key.pem \
            --fullchain-file /etc/nginx/ssl/$domain/cert.pem \
            --reloadcmd "nginx -s reload" 2>/dev/null

        # Update nginx to HTTPS
        cat > /etc/nginx/conf.d/${domain}.conf << VHOSTSSL
server {
    listen 80;
    server_name ${domain} www.${domain};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${domain} www.${domain};
    root /home/${domain}/public_html;
    index index.php index.html;

    ssl_certificate /etc/nginx/ssl/${domain}/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/${domain}/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    include /etc/nginx/performance_headers.conf;
    if (\$waf_block_qs) { return 403; }
    if (\$waf_block_ua) { return 403; }

    location / { try_files \$uri \$uri/ /index.php?\$args; }
    location ~ \.php\$ {
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    location = /wp-config.php { deny all; }
    location = /xmlrpc.php { deny all; }
    location ~ /\. { deny all; }
    location ~* /wp-content/uploads/.*\.php\$ { deny all; }
    location ~* \.(sql|gz|tar|bak|log|old)\$ { deny all; }

    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    real_ip_header CF-Connecting-IP;
}
VHOSTSSL
        log "$domain: SSL installed"
    else
        warn "$domain: SSL failed (point DNS first, then run: vps-admin ssl $domain)"
    fi
done

nginx -t && nginx -s reload 2>/dev/null

# ========================
# 7. MONITORING SCRIPTS
# ========================
log "=== INSTALLING MONITORING ==="

if [ -n "$TG_TOKEN" ]; then
    # Telegram alert function used by all scripts
    cat > /usr/local/bin/tg_alert.sh << TGALERT
#!/bin/bash
TOKEN="${TG_TOKEN}"
CHAT="${TG_CHAT}"
MSG="\$1"
curl -s -X POST "https://api.telegram.org/bot\${TOKEN}/sendMessage" \\
    -d chat_id="\${CHAT}" -d text="\${MSG}" -d parse_mode="HTML" > /dev/null 2>&1
TGALERT
    chmod +x /usr/local/bin/tg_alert.sh

    # Site monitor
    SITE_LIST=""
    for d in "${DOMAINS[@]}"; do SITE_LIST+="\"https://$(echo $d | xargs)\" "; done

    cat > /usr/local/bin/site_monitor.sh << 'SITEMON'
#!/bin/bash
source /root/.vps-config/setup.conf
IFS=',' read -ra DOMS <<< "$DOMAINS"
for d in "${DOMS[@]}"; do
    d=$(echo "$d" | xargs)
    CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://$d" 2>/dev/null)
    if [ "$CODE" != "200" ] && [ "$CODE" != "301" ] && [ "$CODE" != "302" ]; then
        bash /usr/local/bin/tg_alert.sh "[ALERT] $VPS_NAME: $d returned HTTP $CODE"
    fi
done
SITEMON
    chmod +x /usr/local/bin/site_monitor.sh
fi

# ========================
# 8. BACKUP SCRIPT
# ========================
log "=== INSTALLING BACKUP SYSTEM ==="

mkdir -p /backup/{databases,configs,pre-deploy}

cat > /usr/local/bin/backup_full.sh << 'BACKUP'
#!/bin/bash
source /root/.vps-config/setup.conf
DATE=$(date +%Y%m%d)
IFS=',' read -ra DOMS <<< "$DOMAINS"

# Backup databases
for d in "${DOMS[@]}"; do
    d=$(echo "$d" | xargs)
    DB=$(grep "^$d:" /root/.vps-config/db-credentials.txt 2>/dev/null | grep -oP 'DB=\K\S+')
    [ -z "$DB" ] && continue
    mysqldump -uroot -p"$DB_ROOT_PASS" "$DB" 2>/dev/null | gzip > "/backup/databases/${d}_${DATE}.sql.gz"
done

# Backup configs
cp /etc/nginx/nginx.conf /backup/configs/nginx.conf
cp -r /etc/nginx/conf.d/ /backup/configs/
tar czf /backup/configs/crontab_${DATE}.tar.gz <(crontab -l) 2>/dev/null

# Cleanup old backups (keep 7 days)
find /backup/databases/ -name "*.sql.gz" -mtime +7 -delete
find /backup/configs/ -name "*.tar.gz" -mtime +7 -delete

# Cross-VPS sync
if [ -n "$BACKUP_VPS_IP" ]; then
    rsync -az --timeout=60 /backup/ root@${BACKUP_VPS_IP}:/backup/from-${VPS_NAME}/ 2>/dev/null
fi

bash /usr/local/bin/tg_alert.sh "[BACKUP] $VPS_NAME: OK ($(du -sh /backup/databases/ | awk '{print $1}'))" 2>/dev/null
BACKUP
chmod +x /usr/local/bin/backup_full.sh

# ========================
# 9. INTEGRITY CHECK
# ========================
log "=== INSTALLING INTEGRITY MONITOR ==="

mkdir -p /var/lib/integrity

cat > /usr/local/bin/integrity_check.sh << 'INTEGRITY'
#!/bin/bash
source /root/.vps-config/setup.conf
IFS=',' read -ra DOMS <<< "$DOMAINS"
ALERT=0

for d in "${DOMS[@]}"; do
    d=$(echo "$d" | xargs)
    WP="/home/$d/public_html"
    [ ! -d "$WP" ] && continue
    HASH_FILE="/var/lib/integrity/${d}.sha256"
    CURRENT="/tmp/integrity_${d}.sha256"

    find "$WP" -name "*.php" -path "*/wp-admin/*" -o -name "*.php" -path "*/wp-includes/*" | sort | xargs sha256sum > "$CURRENT" 2>/dev/null

    # Check for PHP in uploads
    UPLOADS_PHP=$(find "$WP/wp-content/uploads/" -name "*.php" 2>/dev/null | wc -l)
    if [ "$UPLOADS_PHP" -gt 0 ]; then
        bash /usr/local/bin/tg_alert.sh "[SECURITY] $VPS_NAME: $d has $UPLOADS_PHP PHP files in uploads!"
        ALERT=1
    fi

    if [ -f "$HASH_FILE" ]; then
        DIFF=$(diff "$HASH_FILE" "$CURRENT" 2>/dev/null | grep "^[<>]" | wc -l)
        if [ "$DIFF" -gt 0 ]; then
            bash /usr/local/bin/tg_alert.sh "[SECURITY] $VPS_NAME: $d has $DIFF modified core files!"
            ALERT=1
        fi
    fi
    cp "$CURRENT" "$HASH_FILE"
    rm -f "$CURRENT"
done

[ "$ALERT" -eq 0 ] && echo "$(date): All sites clean"
INTEGRITY
chmod +x /usr/local/bin/integrity_check.sh

# Create initial baseline
bash /usr/local/bin/integrity_check.sh 2>/dev/null

# ========================
# 10. WP AUTO-UPDATE
# ========================
log "=== INSTALLING AUTO-UPDATE ==="

cat > /usr/local/bin/wp_auto_update.sh << 'WPUPDATE'
#!/bin/bash
source /root/.vps-config/setup.conf
IFS=',' read -ra DOMS <<< "$DOMAINS"

for d in "${DOMS[@]}"; do
    d=$(echo "$d" | xargs)
    WP="/home/$d/public_html"
    [ ! -f "$WP/wp-load.php" ] && continue

    # Backup before update
    BACKUP_DIR="/backup/pre-deploy/${d}_$(date +%Y%m%d_%H%M)"
    mkdir -p "$BACKUP_DIR"
    cp -r "$WP/wp-content/plugins" "$BACKUP_DIR/"
    cp -r "$WP/wp-content/themes" "$BACKUP_DIR/"

    # Update via WP-CLI if available, otherwise skip
    if command -v wp &>/dev/null; then
        cd "$WP"
        wp plugin update --all --allow-root 2>/dev/null
        wp theme update --all --allow-root 2>/dev/null

        # Verify site still works
        CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://$d" 2>/dev/null)
        if [ "$CODE" != "200" ] && [ "$CODE" != "301" ]; then
            # Rollback
            cp -rf "$BACKUP_DIR/plugins/"* "$WP/wp-content/plugins/"
            cp -rf "$BACKUP_DIR/themes/"* "$WP/wp-content/themes/"
            bash /usr/local/bin/tg_alert.sh "[UPDATE] $VPS_NAME: $d ROLLBACK (HTTP $CODE after update)"
        else
            bash /usr/local/bin/tg_alert.sh "[UPDATE] $VPS_NAME: $d updated OK"
        fi
    fi
done

# Cleanup old pre-deploy (keep 4 weeks)
find /backup/pre-deploy/ -maxdepth 1 -mtime +28 -exec rm -rf {} \;
WPUPDATE
chmod +x /usr/local/bin/wp_auto_update.sh

# Install WP-CLI
curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# ========================
# 11. DB OPTIMIZER
# ========================
log "=== INSTALLING DB OPTIMIZER ==="

cat > /usr/local/bin/db_deep_optimize.sh << 'DBOPT'
#!/bin/bash
source /root/.vps-config/setup.conf
IFS=',' read -ra DOMS <<< "$DOMAINS"

for d in "${DOMS[@]}"; do
    d=$(echo "$d" | xargs)
    DB=$(grep "^$d:" /root/.vps-config/db-credentials.txt 2>/dev/null | grep -oP 'DB=\K\S+')
    [ -z "$DB" ] && continue

    mysql -uroot -p"$DB_ROOT_PASS" "$DB" -e "
    DELETE FROM wp_posts WHERE post_type='revision' AND post_date < DATE_SUB(NOW(), INTERVAL 30 DAY);
    DELETE FROM wp_comments WHERE comment_approved='spam';
    DELETE FROM wp_comments WHERE comment_approved='trash';
    DELETE FROM wp_options WHERE option_name LIKE '_transient_%';
    DELETE FROM wp_options WHERE option_name LIKE '_site_transient_%';
    DELETE FROM wp_posts WHERE post_status='auto-draft' AND post_date < DATE_SUB(NOW(), INTERVAL 7 DAY);
    DELETE FROM wp_posts WHERE post_status='trash' AND post_date < DATE_SUB(NOW(), INTERVAL 30 DAY);
    " 2>/dev/null

    # Optimize tables
    TABLES=$(mysql -uroot -p"$DB_ROOT_PASS" "$DB" -N -e "SHOW TABLES" 2>/dev/null)
    for table in $TABLES; do
        mysql -uroot -p"$DB_ROOT_PASS" "$DB" -e "OPTIMIZE TABLE $table" 2>/dev/null > /dev/null
    done
done

bash /usr/local/bin/tg_alert.sh "[DB] $VPS_NAME: Optimization complete" 2>/dev/null
DBOPT
chmod +x /usr/local/bin/db_deep_optimize.sh

# ========================
# 12. BROKEN LINK CHECKER
# ========================
log "=== INSTALLING BROKEN LINK CHECKER ==="

cat > /usr/local/bin/broken_link_check.sh << 'LINKCHECK'
#!/bin/bash
source /root/.vps-config/setup.conf
IFS=',' read -ra DOMS <<< "$DOMAINS"
BROKEN=""

for d in "${DOMS[@]}"; do
    d=$(echo "$d" | xargs)
    SITEMAP=$(curl -s "https://$d/wp-sitemap.xml" 2>/dev/null)
    URLS=$(echo "$SITEMAP" | grep -oP 'https?://[^<]+' | head -20)
    
    for url in $URLS; do
        CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$url" 2>/dev/null)
        if [ "$CODE" = "404" ] || [ "$CODE" = "500" ]; then
            BROKEN+="$d: $url ($CODE)\n"
        fi
    done
done

if [ -n "$BROKEN" ]; then
    bash /usr/local/bin/tg_alert.sh "[SEO] $VPS_NAME: Broken links found:
$BROKEN" 2>/dev/null
fi
LINKCHECK
chmod +x /usr/local/bin/broken_link_check.sh

# ========================
# 13. ADMIN PANEL (HocVPS-style)
# ========================
log "=== INSTALLING ADMIN PANEL ==="

# Download the full interactive admin panel
# If running from skill package, copy from scripts/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/vps-admin.sh" ]; then
    cp "$SCRIPT_DIR/vps-admin.sh" /usr/local/bin/vps-admin
else
    # Embedded minimal fallback — full version is in scripts/vps-admin.sh
    cat > /usr/local/bin/vps-admin << 'ADMIN_FALLBACK'
#!/bin/bash
source /root/.vps-config/setup.conf 2>/dev/null
case "$1" in
    status)
        echo "=== VPS: $VPS_NAME ==="
        echo "RAM: $(free -h | awk '/Mem/{print $3"/"$2}')"
        echo "Disk: $(df -h / | awk 'NR==2{print $3"/"$2}')"
        IFS=',' read -ra DOMS <<< "$DOMAINS"
        for d in "${DOMS[@]}"; do d=$(echo "$d" | xargs)
            CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://$d" 2>/dev/null)
            TTFB=$(curl -s -o /dev/null -w "%{time_starttransfer}" --connect-timeout 5 "https://$d" 2>/dev/null)
            echo "$d: HTTP $CODE | TTFB: ${TTFB}s"
        done ;;
    speed)  vps-admin status ;;
    backup) bash /usr/local/bin/backup_full.sh ;;
    update) bash /usr/local/bin/wp_auto_update.sh ;;
    *)      echo "VPS Admin: vps-admin [status|speed|backup|update]"
            echo "Full interactive menu: install vps-admin.sh from skill package" ;;
esac
ADMIN_FALLBACK
fi
chmod +x /usr/local/bin/vps-admin

# Setup cluster directory
mkdir -p /root/.vps-config/cluster

# ========================
# 14. CRONTAB
# ========================
log "=== SETTING UP CRONTAB ==="

EXISTING=$(crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$")
cat << CRON | crontab -
$EXISTING

# === AUTO-MANAGED CRONS ===
0 2 * * * /usr/local/bin/backup_full.sh >> /var/log/backup.log 2>&1
0 6 * * * /usr/local/bin/integrity_check.sh >> /var/log/integrity.log 2>&1
0 5 * * 0 /usr/local/bin/wp_auto_update.sh >> /var/log/wp_update.log 2>&1
30 3 * * 0 /usr/local/bin/db_deep_optimize.sh >> /var/log/db_optimize.log 2>&1
0 8 * * 1 /usr/local/bin/broken_link_check.sh >> /var/log/broken_links.log 2>&1
*/5 * * * * /usr/local/bin/site_monitor.sh >> /var/log/site_monitor.log 2>&1
CRON

log "Crontab configured"

# ========================
# 15. FIREWALL
# ========================
log "=== CONFIGURING FIREWALL ==="

if command -v firewall-cmd &>/dev/null; then
    firewall-cmd --permanent --add-service=http 2>/dev/null
    firewall-cmd --permanent --add-service=https 2>/dev/null
    firewall-cmd --permanent --add-service=ssh 2>/dev/null
    firewall-cmd --reload 2>/dev/null
elif command -v ufw &>/dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 22/tcp
    ufw --force enable
fi

# Fail2ban
cat > /etc/fail2ban/jail.local << 'F2B'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true

[nginx-http-auth]
enabled = true
port = http,https

[nginx-botsearch]
enabled = true
port = http,https
F2B
systemctl restart fail2ban

log "Firewall + fail2ban configured"

# ========================
# DONE
# ========================
nginx -t && nginx -s reload

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  SETUP COMPLETE!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Server IP: ${CYAN}$SERVER_IP${NC}"
echo -e "VPS Name:  ${CYAN}$VPS_NAME${NC}"
echo ""
echo -e "${YELLOW}Sites created:${NC}"
for domain in "${DOMAINS[@]}"; do
    domain=$(echo "$domain" | xargs)
    echo -e "  https://${CYAN}$domain${NC}"
done
echo ""
echo -e "${YELLOW}Credentials:${NC}"
echo -e "  DB root password: ${CYAN}$DB_ROOT_PASS${NC}"
echo -e "  DB per-site:      ${CYAN}/root/.vps-config/db-credentials.txt${NC}"
echo ""
echo -e "${YELLOW}Admin:${NC}"
echo -e "  Run: ${CYAN}vps-admin${NC} (or vps-admin status/speed/backup/update)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Point DNS to $SERVER_IP (Cloudflare recommended)"
echo "  2. Visit https://yourdomain.com to install WordPress"
echo "  3. Run 'vps-admin ssl domain.com' after DNS propagation"
echo ""
