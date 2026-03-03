#!/bin/bash
# Demo script to render menus for screenshots

# Simulate config
export DOMAINS='example.com,blog.example.com,shop.example.com'
export SERVER_IP='103.92.28.15'
export VPS_NAME='vps-prod-01'
export DB_ROOT_PASS='secret'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

echo "=== MAIN MENU ==="
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${WHITE}${BOLD}         VPS ADMIN PANEL - $VPS_NAME          ${NC}${CYAN}║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC} IP: ${GREEN}$SERVER_IP${NC}  |  up 45 days, 12 hours"
echo -e "${CYAN}║${NC} RAM: 1.2G/4.0G (30%)"
echo -e "${CYAN}║${NC} Disk: 18G/80G (22%)"
echo -e "${CYAN}║${NC} PHP: 8.1.34  |  Nginx: 1.24.0"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WHITE}${BOLD}  MAIN MENU${NC}"
echo -e "${GREEN}  ─────────────────────────────────${NC}"
echo -e "  ${CYAN}1.${NC} Website Management"
echo -e "  ${CYAN}2.${NC} Database Management"
echo -e "  ${CYAN}3.${NC} SSL Certificate"
echo -e "  ${CYAN}4.${NC} Backup & Restore"
echo -e "  ${CYAN}5.${NC} Security & WAF"
echo -e "  ${CYAN}6.${NC} Performance & Speed"
echo -e "  ${CYAN}7.${NC} VPS Cluster Sync"
echo -e "  ${CYAN}8.${NC} Monitoring & Logs"
echo -e "  ${CYAN}9.${NC} System Settings"
echo -e "  ${MAGENTA}10.${NC} Quick Tools"
echo -e "  ${MAGENTA}11.${NC} Multi-IP Management"
echo -e "  ${RED}0.${NC} Exit"
echo ""
echo -e "  Select [0-11]: "

echo ""
echo "=== WEBSITE MANAGEMENT ==="
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${WHITE}${BOLD}         VPS ADMIN PANEL - $VPS_NAME          ${NC}${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WHITE}${BOLD}  WEBSITE MANAGEMENT${NC}"
echo -e "${GREEN}  ─────────────────────────────────${NC}"
echo -e "  ${YELLOW}Current sites:${NC}"
echo -e "    1. ${GREEN}●${NC} example.com (HTTP 200)"
echo -e "    2. ${GREEN}●${NC} blog.example.com (HTTP 200)"
echo -e "    3. ${GREEN}●${NC} shop.example.com (HTTP 301)"
echo ""
echo -e "  ${CYAN}1.${NC} Add new website"
echo -e "  ${CYAN}2.${NC} Remove website"
echo -e "  ${CYAN}3.${NC} Add redirect domain"
echo -e "  ${CYAN}4.${NC} Fix permissions"
echo -e "  ${CYAN}5.${NC} Enable/Disable maintenance"
echo -e "  ${CYAN}6.${NC} List plugins (per site)"
echo -e "  ${CYAN}7.${NC} Disable plugin"
echo -e "  ${CYAN}8.${NC} Enable plugin"
echo -e "  ${RED}0.${NC} Back"
echo ""

echo ""
echo "=== DOMAIN PICKER ==="
echo ""
echo -e "  ${WHITE}${BOLD}Available domains:${NC}"
echo -e "    ${GREEN}1)${NC} example.com ${GREEN}●${NC}"
echo -e "    ${GREEN}2)${NC} blog.example.com ${GREEN}●${NC}"
echo -e "    ${GREEN}3)${NC} shop.example.com ${GREEN}●${NC}"
echo ""
echo -e "  Issue SSL for [1-3]: "

echo ""
echo "=== SECURITY & WAF ==="
echo ""
echo -e "${WHITE}${BOLD}  SECURITY & WAF${NC}"
echo -e "${GREEN}  ─────────────────────────────────${NC}"
echo -e "  ${CYAN}1.${NC} Malware Scanner (12-step deep scan)"
echo -e "  ${CYAN}2.${NC} Firewall Hardening (7-step)"
echo -e "  ${CYAN}3.${NC} Ban IP address"
echo -e "  ${CYAN}4.${NC} Unban IP address"
echo -e "  ${CYAN}5.${NC} View banned IPs"
echo -e "  ${CYAN}6.${NC} Check file integrity"
echo -e "  ${CYAN}7.${NC} WordPress bulk security"
echo -e "  ${RED}0.${NC} Back"
echo ""

echo ""
echo "=== MULTI-IP MANAGEMENT ==="
echo ""
echo -e "${WHITE}${BOLD}  MULTI-IP MANAGEMENT${NC}"
echo -e "${GREEN}  ─────────────────────────────────${NC}"
echo -e "  ${YELLOW}Server IPs:${NC}"
echo -e "    ${GREEN}●${NC} 103.92.28.15 (primary)"
echo -e "    ${GREEN}●${NC} 103.92.28.16"
echo -e "    ${GREEN}●${NC} 103.92.28.17"
echo ""
echo -e "  ${YELLOW}Current bindings:${NC}"
echo -e "    example.com       → ${GREEN}103.92.28.15${NC}"
echo -e "    blog.example.com  → ${GREEN}103.92.28.16${NC}"
echo -e "    shop.example.com  → ${CYAN}All IPs${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} List all IPs"
echo -e "  ${CYAN}2.${NC} Show IP bindings"
echo -e "  ${CYAN}3.${NC} Assign IP to website"
echo -e "  ${CYAN}4.${NC} Remove IP binding"
echo -e "  ${CYAN}5.${NC} Verify connection"
echo -e "  ${RED}0.${NC} Back"
echo ""
