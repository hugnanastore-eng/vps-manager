# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.5.1] - 2026-03-03

### Added
- **Inline Help System**: Type `?` in any menu for full descriptions, `N?` for specific option details
- **i18n Help Text**: 49 translated help strings across all 7 languages with safety indicators (✅/⚠)
- **SSL Expiry Alerts**: Telegram notification 7 days before certificate expiration
- **DB Size Alerts**: Telegram warning when any database exceeds threshold (default 1GB)
- **GitHub Actions CI**: ShellCheck lint on every push to `scripts/` directory
- **Nginx Log Rotation**: Automatic logrotate config for access/error logs

### Changed
- **OPcache status**: Formatted display with memory, hit rate, cached files (was raw `var_dump`)
- **Security hardening**: `set -o pipefail`, `readonly VER`, restricted `PATH`, `export LC_ALL=C`
- **Enhanced header**: Shows OS name, CPU cores, load average, PHP/Nginx versions
- **Website listing**: Main menu shows active WordPress sites with SSL status, DB, disk usage
- **Pre-update backup**: Now backs up all scripts + modules/ to timestamped directory
- **README**: Complete rewrite in English with all 13 menus and 9 modules documented

### Fixed
- `set -u` removed — caused `unbound variable` crash on config-loaded variables
- Pre-initialized config vars before sourcing `setup.conf`

## [2.5.0] - 2026-03-03

### Added — Internationalization (i18n)
- **7 Language Files** (`lang/en.sh`, `vi.sh`, `zh.sh`, `ja.sh`, `fr.sh`, `es.sh`, `pt.sh`): ~200 translated strings per language
- **`load_lang()` Function**: Auto-detects language from config → system locale → defaults to English
- **`change_language()` Menu**: Option 8 in System Settings — switch language and save to config
- **7 Landing Pages**: Full documentation in EN, VI, ZH, FR, JA, ES, PT with feature details
- **Hreflang SEO Tags**: All landing pages interlinked for Google multi-language indexing
- **Language Bar**: 7-language selector on all documentation pages

### Changed
- Version bumped from 2.1.0 to 2.5.0
- Main menu and System Settings now use `$MSG_*` variables from lang files
- `install.sh` now downloads and deploys 7 language files alongside modules
- Removed `<link rel="canonical">` tags — replaced with `hreflang` for separate language indexing

## [2.1.0] - 2026-03-03

### Added — 8 New Modules
- **Per-table Split Dump** (`backup_split.sh`): Dumps each MySQL table individually with SHA256 checksum and 3 retries. Tested: 119/119 tables, 44MB/583MB, dump 4s, restore 26s.
- **WordPress Auto-Update** (`wp_auto_update.sh`): Backup → update core/plugins/themes → verify HTTP → auto-rollback on failure. Telegram notification.
- **Resource Alert** (`resource_alert.sh`): RAM/Disk/CPU/Swap monitoring, Telegram alerts, 30-min cooldown, 1-click cron setup.
- **Disk Cleanup** (`disk_cleanup.sh`): Dry-run mode, cleans logs/revisions/transients/spam, shows recovered space.
- **SSH Key Manager** (`ssh_key_manager.sh`): CRUD SSH keys, format validation, lockout prevention, sshd_config backup + rollback.
- **Domain Health Dashboard** (`domain_health.sh`): HTTP status, SSL expiry, TTFB, DB size, disk usage for all sites.
- **WordPress Staging** (`wp_staging.sh`): Clone WP → staging.domain.com + .htpasswd protection, safe staging removal.
- **Simple Analytics** (`simple_analytics.sh`): Parse nginx access logs — top pages, IPs, bandwidth, bots, 404s, status codes.

### Changed
- Version bumped from 2.0.0 to 2.1.0
- `do_update()` now downloads all 9 modules (was only multi-ip.sh)
- `show_banner()` reads version from file instead of hardcoded `$VERSION`
- `save_component_state()` reads version from file for accuracy
- `menu_vps_update()` expanded from 5 to 9 items (Disk Cleanup, Resource Check, Domain Health, WP Auto-Update)
- Admin Menu #4 (Backup) includes Per-table Split Dump
- Admin Menu #8 (Monitoring) includes Domain Health Dashboard + Simple Analytics
- Admin Menu #10 (Quick Tools) includes WP Auto-Update, SSH Key Manager, WP Staging

### Fixed
- `vps-update update` displayed wrong version after update (stale `$VERSION` variable)
- `do_update()` banner now shows correct remote version + module count
- `save_component_state()` wrote stale version to `components.json`

### Security
- SSH key injection prevention: blocks `;&|$\`` characters
- sshd_config validation (`sshd -t`) before restart, auto-restore on failure
- Staging site deletion validated with `^staging\.[a-zA-Z0-9._-]+$` regex
- Database name sanitization with `^[a-zA-Z0-9_]+$` regex

## [2.0.0] - 2026-03-03

### Added
- **Modular Architecture**: New features are now separate `.sh` files in `modules/`
- **Multi-IP Management** (Menu #11): Assign specific IPs to websites via Nginx vhost
- **Quick Tools** (Menu #10): Common admin shortcuts
- **Domain Picker UX**: All domain prompts now show a numbered list for selection
- **39 Input Validations**: Every user input validated before use in commands
- **3-tier Domain Discovery**: Config → Nginx → `/home` directory scan
- **DNS Hijack Prevention**: Validates `curl ifconfig.me` output format
- **Smart Installer**: Detects existing setup, skips installed components

### Security
- `validate_domain()`, `validate_ip()`, `validate_dbname()`, `validate_plugin()` across all scripts
- `chmod 600` on credential files
- Nginx config test + auto-rollback before any reload
- Backup before destructive operations (site/database removal)
- No `eval`, no `exec`, no unsafe `rm` patterns

### Changed
- Version bumped from 1.0.0 to 2.0.0
- Admin menu expanded from 9 to 11 items
- `passwd` replaced with `chpasswd` for pipe-safe password changes
- `set -e` removed (causes silent exit in `curl | bash` mode)

### Fixed
- SERVER_IP auto-detection with multi-fallback (hostname → ip addr → curl)
- VPS_NAME auto-detection via `hostname -s`
- Garbled emoji characters on menu items
- NC → NCHAT variable collision
- `sed` delimiter conflicts in Telegram config
- For-loop syntax error on line 748
