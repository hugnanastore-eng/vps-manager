# VPS Manager v2.0.0

<div align="center">

<img src="docs/screenshots/main-menu.png" alt="VPS Manager Admin Panel" width="600">

**All-in-one VPS management toolkit for LEMP + WordPress servers**

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/hugnanastore-eng/vps-manager/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-orange.svg)]()
[![Docker Tested](https://img.shields.io/badge/docker-tested-2496ED.svg)]()

**11 Menus** · **39 Security Validations** · **Modular Architecture** · **One-Command Install**

[Quick Install](#-quick-install) · [Features](#-features) · [Screenshots](#-screenshots) · [Architecture](#-architecture) · [Support](#-support)

</div>

---

## ⚡ Quick Install

```bash
curl -sO https://raw.githubusercontent.com/hugnanastore-eng/vps-manager/main/scripts/install.sh && bash install.sh
```

Or update an existing installation:

```bash
vps-update update
```

> **Requirements**: Ubuntu 20.04/22.04 LTS, root access, clean VPS or existing LEMP stack.

---

## 🎯 Features

### 11-Menu Admin Panel

| # | Menu | Description |
|---|------|-------------|
| 1 | **Website Management** | Add/remove sites, redirects, fix permissions, toggle maintenance, manage plugins |
| 2 | **Database Management** | Create, delete, import, export MySQL databases with auto-credential generation |
| 3 | **SSL Certificate** | Let's Encrypt auto-issue, renew, list, and expiry checking |
| 4 | **Backup & Restore** | Daily automated backups, Google Drive sync, point-in-time restore |
| 5 | **Security & WAF** | Malware scanner (12-step), firewall hardening (7-step), IP ban/unban, fail2ban |
| 6 | **Performance & Speed** | Redis/Memcached toggle, PHP OPcache, Nginx fastcgi cache, Gzip/Brotli |
| 7 | **VPS Cluster Sync** | Multi-VPS backup sync, cross-server migration, cluster node management |
| 8 | **Monitoring & Logs** | Real-time health checks, TTFB monitoring, debug logs, disk usage, Telegram alerts |
| 9 | **System Settings** | PHP version switch, Nginx config, SSH security, swap management |
| 10 | **Quick Tools** | Common admin shortcuts and utilities |
| 11 | **Multi-IP Management** | Assign specific IPs to websites, view IP→domain bindings |

### Smart Installer

The installer automatically detects your existing environment and adapts:

- **Fresh VPS**: Full LEMP stack installation (Nginx, PHP 8.x, MariaDB, Redis, etc.)
- **Existing Setup**: Detects what's already installed, skips duplicates, adds missing components
- **Update Mode**: Compares versions, updates only changed components
- **Compatible with**: HocVPS, aaPanel, CyberPanel, manual LEMP setups

### Domain Picker UX

No more manual domain typing! All domain-related operations now show a numbered list:

```
  Available domains:
    1) example.com ●
    2) blog.example.com ●
    3) shop.example.com ●

  Select domain [1-3]: _
```

### 39 Security Validations

Every user input that touches commands, file paths, database names, or config files is validated:

- **Domain names**: `validate_domain()` — prevents path traversal & injection
- **IP addresses**: `validate_ip()` — octet range validation (0-255)
- **Database names**: `validate_dbname()` — alphanumeric + underscore only
- **Plugin names**: `validate_plugin()` — alphanumeric + hyphen/underscore only
- **curl output**: DNS hijack prevention on external IP detection
- **File permissions**: `chmod 600` on all credential files

---

## 📸 Screenshots

<div align="center">

### Main Admin Panel
<img src="docs/screenshots/main-menu.png" alt="Main Menu" width="600">

### Website Management
<img src="docs/screenshots/website-menu.png" alt="Website Management" width="600">

### Domain Picker
<img src="docs/screenshots/domain-picker.png" alt="Domain Picker UX" width="600">

### Security & WAF
<img src="docs/screenshots/security-menu.png" alt="Security & WAF" width="600">

### Multi-IP Management
<img src="docs/screenshots/multi-ip.png" alt="Multi-IP Management" width="600">

</div>

---

## 🏗 Architecture

```
vps-manager/
├── scripts/
│   ├── install.sh          # Smart installer (detect → install → update)
│   ├── vps-admin.sh        # 11-menu admin panel (1,359 lines)
│   ├── vps-setup.sh        # WordPress/LEMP automated setup
│   └── modules/
│       └── multi-ip.sh     # Multi-IP management module
└── version.txt             # Current version (2.0.0)
```

### Modular Design

New features are developed as separate `.sh` files in the `modules/` directory. The admin panel automatically loads all modules at startup:

```bash
# Module auto-loader in vps-admin.sh
for _mod in /usr/local/bin/vps-modules/*.sh; do
    [ -f "$_mod" ] && source "$_mod"
done
```

This allows:
- ✅ Independent development and testing of each module
- ✅ Easy feature toggling (just add/remove the `.sh` file)
- ✅ Graceful fallback if a module isn't installed
- ✅ Zero downtime updates for individual features

---

## 📊 Comparison

| Feature | Manual Setup | Other Scripts | **VPS Manager** |
|---------|:---:|:---:|:---:|
| One-command install | ❌ | ✅ | ✅ |
| Smart detection (existing setup) | ❌ | ❌ | ✅ |
| 11 admin menus | ❌ | 3-5 | **11** |
| Input validation (39 checks) | ❌ | ❌ | ✅ |
| Multi-IP binding | ❌ | ❌ | ✅ |
| Domain picker UX | ❌ | ❌ | ✅ |
| Modular architecture | ❌ | ❌ | ✅ |
| Malware scanner (12-step) | ❌ | Basic | ✅ |
| Cluster sync | ❌ | ❌ | ✅ |
| Auto backup + GDrive | ❌ | Partial | ✅ |

---

## 🔧 Configuration

After installation, config files are stored in `/root/.vps-config/`:

```
/root/.vps-config/
├── setup.conf          # Main config (SERVER_IP, DOMAINS, DB_ROOT_PASS)
├── version             # Installed version
├── components.json     # Installed components tracking
├── db-credentials.txt  # Database credentials (chmod 600)
└── cluster/
    └── nodes.conf      # Cluster node definitions
```

---

## 🔐 Security

This project takes security seriously:

- **No `eval` or `exec`** — no dynamic code execution
- **No `rm -rf /`** — safe deletion patterns only
- **All inputs validated** before use in any command
- **Backup before destructive operations** — auto-backup before removing sites/databases
- **Nginx config test** (`nginx -t`) before any reload, with auto-rollback on failure
- **Credential files** protected with `chmod 600`
- **curl output validation** — prevents DNS hijack injection

---

## 📋 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## ☕ Support

If this tool saves you time, consider buying me a coffee!

<div align="center">

[![PayPal](https://img.shields.io/badge/PayPal-Support_this_project-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/HoangDuong)

</div>

> Every contribution helps maintain and improve this project. Thank you! 🙏

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Made with ❤️ for the VPS community**

⭐ Star this repo if you find it useful!

</div>
