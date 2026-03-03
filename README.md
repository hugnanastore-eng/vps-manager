# VPS Manager v2.5.1

<div align="center">

<img src="docs/screenshots/main-menu.png" alt="VPS Manager Admin Panel" width="600">

**All-in-one VPS management toolkit for LEMP + WordPress servers**

[![Version](https://img.shields.io/badge/version-2.5.1-blue.svg)](https://github.com/hugnanastore-eng/vps-manager/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-orange.svg)]()
[![Security](https://img.shields.io/badge/security-hardened-brightgreen.svg)]()
[![Modules](https://img.shields.io/badge/modules-9-purple.svg)]()
[![Languages](https://img.shields.io/badge/languages-7-yellow.svg)]()

**13 Menus** · **9 Modules** · **7 Languages** · **40+ Security Validations** · **One-Command Install**

[Quick Install](#-quick-install) · [Features](#-features) · [Modules](#-modules) · [Security](#-security) · [Architecture](#-architecture) · [Support](#-support)

</div>

---

## ⚡ Quick Install

**Fresh VPS** (installs everything automatically):

```bash
curl -sO https://raw.githubusercontent.com/hugnanastore-eng/vps-manager/main/scripts/install.sh && bash install.sh
```

**Update existing installation:**

```bash
vps-update update
```

**Open the admin panel:**

```bash
vps-admin
```

> **Requirements**: Ubuntu 20.04/22.04 LTS or Rocky Linux 8/9, root access, clean VPS or existing LEMP stack.

---

## 🎯 Features

### 13-Menu Admin Panel

The interactive admin panel (`vps-admin`) provides a full-featured terminal UI with real-time VPS stats in the header (OS, IP, RAM, Disk, CPU, Load, PHP/Nginx versions) and a list of active WordPress sites with SSL status.

| # | Menu | What it does |
|---|------|-------------|
| 1 | **Website Management** | Add new websites with auto-configured Nginx vhost + document root. Remove sites cleanly (Nginx config + files + database). Set up domain redirects (301/302). Fix file/folder permissions (`755`/`644`). Toggle maintenance mode on/off. List, enable, and disable WordPress plugins. |
| 2 | **Database Management** | List all MySQL/MariaDB databases with sizes. Create new databases with auto-generated secure credentials. Delete databases safely (with confirmation). View stored database credentials. Run `OPTIMIZE TABLE` on all tables to reclaim disk space. Import `.sql` or `.sql.gz` files into any database. Export (dump) any database to `.sql.gz` for backup or migration. |
| 3 | **SSL Certificate** | Issue free SSL certificates from Let's Encrypt automatically via Certbot. Renew certificates (single or all). List all installed certificates with expiry dates. Force HTTPS redirect on any domain. Revoke certificates when no longer needed. |
| 4 | **Backup & Restore** | Run full backups (files + database) compressed to `.tar.gz`. List all existing backups with size and date. Restore from any backup with interactive selection. Sync backups to a remote VPS via rsync/SSH. Check total backup storage usage. **Per-table split dump** — dumps each MySQL table individually with SHA256 checksums for databases of any size. |
| 5 | **Security & WAF** | Enable/disable Web Application Firewall (WAF) rules in Nginx — blocks SQL injection, XSS, file inclusion, and exploit URIs. Check file integrity (detect unauthorized modifications). Manage Fail2Ban — view jails, status, banned IPs. Manually ban an IP address across all jails. Unban a previously blocked IP. View recent attack logs with source IPs, paths, and timestamps. Change the root or system password securely. |
| 6 | **Performance & Speed** | Run a comprehensive speed audit (TTFB, page load, caching status). Switch PHP versions (7.4, 8.0, 8.1, 8.2, 8.3). Manage OPcache (enable, disable, view stats). Restart PHP-FPM workers (clears memory leaks). Restart Nginx (applies config changes). Clear OPcache (force recompilation of PHP files). View real-time `top` process monitor for resource usage. |
| 7 | **VPS Cluster Sync** | Manage multiple VPS nodes — add, remove, list cluster members. Sync backups across nodes via SSH/rsync. Migrate entire websites between VPS instances (files + database + Nginx config + SSL). |
| 8 | **Monitoring & Logs** | View real-time resource usage (CPU, RAM, Disk, Network). Read Nginx access and error logs. Analyze slow MySQL queries from slow query log. Configure Telegram bot alerts for downtime, high resource usage, and security events. **Domain Health Dashboard** — HTTP status, SSL expiry, TTFB, DB size, disk usage for each site. **Simple Analytics** — top pages, IPs, bandwidth, bot vs human traffic, 404 errors from access logs. |
| 9 | **System Settings** | Display full system info (OS, kernel, IP, uptime, installed packages). Update system packages (`apt upgrade` / `dnf update`). Restart all services (Nginx, PHP-FPM, MariaDB, Redis). Manage crontab entries. Configure Telegram Bot token and Chat ID for alerts. |
| 10 | **Quick Tools** | **Malware Scanner** — 12-step deep scan for backdoors, webshells, suspicious PHP patterns, and unauthorized files. **Firewall Hardening** — 7-step hardening (DDoS rules, port restriction, brute-force protection). **Disk Cleanup** — remove old logs, WordPress revisions/transients/spam, unused files. **Swap Management** — create, resize, or remove swap file. **SSH Key Manager** — add/remove SSH keys with validation and lockout prevention. **WP Staging** — clone a live WordPress site to staging.domain.com with .htpasswd protection. **Credential Overview** — view all database and system credentials in one place. |
| 11 | **Multi-IP Management** | Bind specific IP addresses to individual websites — useful for SEO, separate SSL certs, or email reputation. View current IP→domain bindings. Add and remove IP assignments. |
| 12 | **Smart Update** | Check for new versions. Download and install updates for the admin panel, installer, all modules, and language files. Includes post-update health check and backup of previous files. |
| 13 | **🌍 Change Language** | Switch the interface language. Supported: English, Vietnamese (Tiếng Việt), Chinese (中文), Japanese (日本語), French (Français), Spanish (Español), Portuguese (Português). Language files are auto-downloaded if not present. |

### Inline Help System

Type `?` in any menu to see detailed descriptions of all options, or `N?` (e.g., `1?`, `a?`) to see details for a specific option. Help text is translated into all 7 supported languages and includes safety indicators:

- ✅ **Safe** — read-only or creates new resources, no risk of data loss
- ⚠ **Careful** — modifies or removes existing data, may require backup first

### Smart Installer

The installer automatically detects your existing environment and adapts:

- **Fresh VPS**: Full LEMP stack installation (Nginx, PHP 8.x, MariaDB 10.x, Redis, Fail2Ban, Certbot, WP-CLI, and more)
- **Existing Setup**: Detects what's already installed, skips duplicates, adds only missing components
- **Update Mode**: Compares versions, downloads only changed files, runs health check after update
- **Compatible with**: HocVPS, aaPanel, CyberPanel, manual LEMP setups
- **Post-update display**: Shows WordPress sites with SSL status, DB name, and disk usage; VPS statistics (RAM, Disk, CPU, Load); and running services status

---

## 📦 Modules

Each module is a standalone `.sh` file in the `modules/` directory, automatically loaded by the admin panel at startup.

### 🗄️ Per-table Split Dump (`backup_split.sh`)

Dumps each MySQL table individually instead of one monolithic dump. Essential for large databases (100MB+) where a single `mysqldump` might timeout or corrupt.

- Dumps each table to a separate `.sql.gz` file with SHA256 checksum
- Automatic retry (3 attempts) for each table on failure
- Interactive restore — pick specific tables to restore instead of the entire database
- Verification: compares row counts before and after restore
- Tested with real production data: 119 tables, 583MB uncompressed, dumped in 4 seconds

### 🔄 WordPress Auto-Update (`wp_auto_update.sh`)

Safely updates WordPress core, plugins, and themes with automatic rollback on failure.

- Creates a full backup before any update
- Updates core → plugins → themes sequentially
- Verifies the site still returns HTTP 200 after each step
- If the site goes down: automatic rollback to the pre-update backup
- Supports updating all sites on the server in one command

### 📟 Resource Alert (`resource_alert.sh`)

Monitors VPS resources and sends Telegram alerts when thresholds are exceeded.

- Monitors: RAM usage, disk usage, CPU load, swap usage
- Configurable thresholds (default: RAM 85%, Disk 90%, CPU 90%, Swap 50%)
- 30-minute cooldown between alerts to prevent spam
- Auto-configures as a cron job (runs every 5 minutes)
- Requires Telegram Bot Token and Chat ID (configured in System Settings)

### 🧹 Disk Cleanup (`disk_cleanup.sh`)

Reclaims disk space by cleaning up temporary and unnecessary files.

- **Dry-run mode** first — shows what would be deleted and estimated space savings before actually deleting
- Cleans: old log files (>30 days), rotated logs, package manager cache
- WordPress-specific: removes post revisions, expired transients, spam/trash comments
- Displays exact bytes recovered after cleanup

### 🔑 SSH Key Manager (`ssh_key_manager.sh`)

Manages SSH public keys for password-less login with safety guards.

- Add SSH keys with format validation (ssh-rsa, ssh-ed25519, ecdsa-sha2)
- Remove specific keys by selection
- Blocks injection characters (`; & | $ \` \`) in key data
- **Lockout prevention**: if disabling password auth, verifies at least one SSH key exists first
- Auto-rollback: if `sshd -t` config test fails, restores the original config

### 🩺 Domain Health Dashboard (`domain_health.sh`)

One-command overview of all WordPress sites on the server.

- HTTP status code (200, 301, 403, 500, etc.)
- SSL certificate expiry date and days remaining
- TTFB (Time To First Byte) performance metric
- Database size for each site's WordPress database
- Disk usage for each site's document root
- Color-coded output: green for healthy, yellow for warnings, red for critical

### 🚧 WordPress Staging (`wp_staging.sh`)

Clone a live WordPress site into a staging environment for testing.

- Creates `staging.yourdomain.com` with a separate database copy
- Automatically updates WordPress `siteurl` and `home` options
- Protects staging with `.htpasswd` authentication (auto-generated credentials)
- One-command teardown: removes staging files, database, Nginx config, and DNS entry
- Staging domain validated with `^staging\.[a-zA-Z0-9._-]+$` regex before any deletion

### 📊 Simple Analytics (`simple_analytics.sh`)

Analyze Nginx access logs without any external tools or services.

- **Top Pages**: Most visited URLs with hit counts
- **Top IPs**: Most active IP addresses with request counts
- **Bandwidth**: Total data transferred per day
- **Bot Detection**: Distinguishes bot traffic from human visitors
- **404 Errors**: Most common "not found" URLs (useful for finding broken links)
- **User Agents**: Browser and device breakdown
- Configurable date range (today, last 7 days, last 30 days, custom)

### 🌐 Multi-IP Management (`multi-ip.sh`)

Assign specific IP addresses to individual websites for SEO, email reputation, or SSL isolation.

- List all available IPs on the server
- Bind a specific IP to a website's Nginx `listen` directive
- View current IP→domain bindings
- Unbind and revert to default IP

---

## 🌍 Internationalization (i18n)

The entire admin panel supports 7 languages with full translation coverage:

| Code | Language | Status |
|------|----------|--------|
| `en` | English | ✅ Complete (default) |
| `vi` | Tiếng Việt (Vietnamese) | ✅ Complete |
| `zh` | 中文 (Chinese) | ✅ Complete |
| `ja` | 日本語 (Japanese) | ✅ Complete |
| `fr` | Français (French) | ✅ Complete |
| `es` | Español (Spanish) | ✅ Complete |
| `pt` | Português (Portuguese) | ✅ Complete |

- All menu labels, prompts, error messages, and inline help text are translated
- Language files are auto-downloaded from the repository when switching
- Language preference is saved in `/root/.vps-config/setup.conf`
- Switch language from the admin panel: Menu 13 → select language code

---

## 🔐 Security

This project is security-hardened for production VPS use:

### Shell Hardening
- `set -uo pipefail` — script exits on undefined variables and pipe failures
- `readonly VER` — version variable is immutable, cannot be overwritten
- `export PATH=` — restricted to standard system directories only
- `export LC_ALL=C` — prevents locale-based injection attacks

### Input Validation (40+ checks)
- **Domain names**: `validate_domain()` — prevents path traversal & shell injection
- **IP addresses**: `validate_ip()` — octet range validation (0-255)
- **Database names**: `validate_dbname()` — `^[a-zA-Z0-9_]+$` only
- **SSH keys**: Format validation + injection character blocking (`;& | $ \\ \``)
- **Plugin names**: `validate_plugin()` — alphanumeric + hyphen/underscore only
- **`_sanitize()`** — strips dangerous characters (`| ; & \` $ \\ "  '`) before use in sed/shell commands

### Credential Protection
- MySQL passwords never appear in `ps aux` — uses `--defaults-extra-file` with temp config
- Temp files created with `mktemp` (random suffix) — prevents race condition attacks
- `trap 'rm -f' EXIT` — cleanup on exit ensures no credential files left behind
- Config files protected with `chmod 600` — readable only by root
- Staging site regex validation before deletion — prevents directory traversal

### Service Safety
- **Nginx**: `nginx -t` config test before every reload, auto-rollback on failure
- **SSH**: `sshd -t` validation before restart, auto-restore on failure
- **Backup before destructive ops**: auto-backup before removing sites/databases
- **No `eval` or `exec`** — no dynamic code execution anywhere
- **Quoted variables** everywhere in `rm` commands — prevents accidental wildcard expansion

---

## 🏗 Architecture

```
vps-manager/
├── scripts/
│   ├── install.sh              # Smart installer (detect → install → update)
│   ├── vps-admin.sh            # 13-menu admin panel (~1,750 lines)
│   ├── vps-setup.sh            # WordPress/LEMP automated setup
│   ├── version.txt             # Current version (2.5.1)
│   ├── lang/                   # Language files (i18n)
│   │   ├── en.sh               # English (default)
│   │   ├── vi.sh               # Vietnamese
│   │   ├── zh.sh               # Chinese
│   │   ├── ja.sh               # Japanese
│   │   ├── fr.sh               # French
│   │   ├── es.sh               # Spanish
│   │   └── pt.sh               # Portuguese
│   └── modules/
│       ├── backup_split.sh     # Per-table MySQL dump
│       ├── wp_auto_update.sh   # WordPress auto-update + rollback
│       ├── resource_alert.sh   # Resource monitoring + Telegram alerts
│       ├── disk_cleanup.sh     # Disk cleanup (dry-run first)
│       ├── ssh_key_manager.sh  # SSH key management + lockout prevention
│       ├── domain_health.sh    # Domain health dashboard
│       ├── wp_staging.sh       # WordPress staging environments
│       ├── simple_analytics.sh # Nginx log analytics
│       └── multi-ip.sh         # Multi-IP management
├── docs/
│   └── screenshots/            # Terminal screenshots
├── CHANGELOG.md                # Version history
├── LICENSE                     # MIT License
└── README.md                   # This file
```

### On-Server File Locations

After installation, files are placed at:

```
/usr/local/bin/
├── vps-admin.sh            → symlinked as 'vps-admin'
├── vps-update              → symlinked from install.sh
└── vps-modules/
    ├── *.sh                # All modules
    └── lang/*.sh           # Language files

/root/.vps-config/
├── setup.conf              # Main config (SERVER_IP, DOMAINS, DB_ROOT_PASS, VPS_LANG)
├── version                 # Installed version number
├── components.json         # Installed components tracking
├── db-credentials.txt      # Database credentials (chmod 600)
├── backup/                 # Pre-update script backups
└── cluster/
    └── nodes.conf          # Cluster node definitions
```

### Modular Design

New features are developed as separate `.sh` files in the `modules/` directory. The admin panel automatically loads all modules at startup:

```bash
for _mod in /usr/local/bin/vps-modules/*.sh; do
    [ -f "$_mod" ] && source "$_mod"
done
```

This allows:
- ✅ Independent development and testing of each module
- ✅ Easy feature toggling (add/remove the `.sh` file)
- ✅ Graceful fallback if a module isn't installed
- ✅ Zero-downtime updates for individual features

---

## 📊 Comparison

| Feature | Manual Setup | Other Scripts | **VPS Manager** |
|---------|:---:|:---:|:---:|
| One-command install | ❌ | ✅ | ✅ |
| Smart detection (existing setup) | ❌ | ❌ | ✅ |
| Admin panel menus | ❌ | 3-5 | **13** |
| Modular plugin system | ❌ | ❌ | **9 modules** |
| Multi-language support | ❌ | ❌ | **7 languages** |
| Inline help system (? / N?) | ❌ | ❌ | ✅ |
| Input validation | ❌ | ❌ | **40+ checks** |
| Per-table DB split dump | ❌ | ❌ | ✅ |
| WP auto-update + rollback | ❌ | ❌ | ✅ |
| SSH key manager + lockout prevention | ❌ | ❌ | ✅ |
| Domain health dashboard | ❌ | ❌ | ✅ |
| Nginx log analytics | ❌ | ❌ | ✅ |
| WP staging with .htpasswd | ❌ | ❌ | ✅ |
| Multi-IP binding | ❌ | ❌ | ✅ |
| Malware scanner (12-step) | ❌ | Basic | ✅ |
| Cluster sync + migration | ❌ | ❌ | ✅ |
| Telegram alerts | ❌ | ❌ | ✅ |
| Security hardening (set -uo, readonly, PATH) | ❌ | ❌ | ✅ |

---

## 💻 CLI Mode

Run features directly from the command line without the interactive menu:

```bash
vps-admin                     # Open interactive admin panel
vps-admin backup-split        # Per-table split dump
vps-admin health              # Domain health dashboard
vps-admin analytics           # Nginx access log analytics
vps-admin cleanup             # Disk cleanup (dry-run first)
vps-admin resource-check      # Resource monitoring check
vps-admin wp-update           # WordPress auto-update for all sites
vps-update update             # Update all scripts and modules
vps-update audit              # Run VPS system audit
vps-update malware-scan       # Run malware scan
vps-update firewall           # Apply firewall hardening
```

---

## 📋 Changelog

See [CHANGELOG.md](CHANGELOG.md) for full version history.

### Recent Changes (v2.5.1)

- **Security hardening**: `set -uo pipefail`, `readonly VER`, restricted `PATH`, `export LC_ALL=C`
- **Enhanced header**: Shows OS name, CPU cores, load average, version number
- **Website listing**: Main menu shows active WordPress sites with SSL status
- **Inline help system**: Type `?` or `N?` in any menu for detailed descriptions
- **i18n help text**: 49 translated help strings across all 7 languages
- **Post-update display**: VPS stats, services status, WordPress sites with DB/disk info

---

## ☕ Support

If this tool saves you time, consider supporting the project!

<div align="center">

[![PayPal](https://img.shields.io/badge/PayPal-Support_this_project-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/HoangDuong)

</div>

> Every contribution helps maintain and improve this project. Thank you! 🙏

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Made with ❤️ for the VPS community**

⭐ Star this repo if you find it useful!

</div>
