# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
