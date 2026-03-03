#!/bin/bash
# ================================================================
#  Module: Multi-IP Management
#  Manages multiple IP addresses on VPS
#  - List all IPs with website bindings
#  - Assign specific IP to a website
#  - Remove IP binding (revert to all-IP)
# ================================================================

IPBIND_CONF="/root/.vps-config/ip-bindings.conf"

# ── Validation (reuse from main if available) ──
_validate_ip() {
    local ip="$1"
    if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}  Invalid IP address${NC}"; return 1
    fi
    # Verify each octet is 0-255
    local IFS='.'
    read -ra octets <<< "$ip"
    for o in "${octets[@]}"; do
        if [ "$o" -gt 255 ] 2>/dev/null; then
            echo -e "${RED}  Invalid IP: octet $o > 255${NC}"; return 1
        fi
    done
    return 0
}

# ── Get all server IPs ──
get_all_ips() {
    ip -4 addr show scope global 2>/dev/null | grep -oP 'inet \K[\d.]+' | sort -u
}

# ── Get IP bound to a domain (from nginx vhost) ──
get_domain_ip() {
    local domain="$1"
    local vhost="/etc/nginx/conf.d/${domain}.conf"
    [ ! -f "$vhost" ] && return

    # Check if listen directive has an IP
    local listen_line=$(grep -m1 'listen.*80' "$vhost" 2>/dev/null)
    if [[ "$listen_line" =~ listen[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):80 ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "all"
    fi
}

# ── Menu: Multi-IP Management ──
menu_multi_ip() {
    header
    echo -e "${WHITE}${BOLD}  Multi-IP Management${NC}"
    echo -e "${GREEN}  ─────────────────────────────────${NC}"

    # List all IPs
    echo -e "  ${YELLOW}Server IPs:${NC}"
    local ALL_IPS=$(get_all_ips)
    local ip_count=0
    local ip_list=()
    while IFS= read -r ip; do
        ((ip_count++))
        ip_list+=("$ip")
        echo -e "    ${CYAN}$ip_count.${NC} $ip"
    done <<< "$ALL_IPS"

    if [ "$ip_count" -le 1 ]; then
        echo ""
        echo -e "  ${YELLOW}Only 1 IP detected. Multi-IP requires 2+ IPs on this server.${NC}"
        echo -e "  ${YELLOW}Add more IPs through your VPS provider, then return here.${NC}"
        pause
        return
    fi

    # Show current bindings
    echo ""
    echo -e "  ${YELLOW}Current IP Bindings:${NC}"
    IFS=',' read -ra DOMS <<< "$DOMAINS"
    for d in "${DOMS[@]}"; do
        d=$(echo "$d" | xargs)
        local bound_ip=$(get_domain_ip "$d")
        if [ "$bound_ip" = "all" ]; then
            echo -e "    ${GREEN}●${NC} $d → ${WHITE}All IPs (default)${NC}"
        else
            echo -e "    ${CYAN}●${NC} $d → ${GREEN}$bound_ip${NC}"
        fi
    done

    echo ""
    echo -e "  ${CYAN}1.${NC} Assign IP to website"
    echo -e "  ${CYAN}2.${NC} Remove IP binding (use all IPs)"
    echo -e "  ${CYAN}3.${NC} Verify IP bindings (test connections)"
    echo -e "  ${RED}0.${NC} Back"
    echo ""
    read -p "  Select: " IP_CHOICE

    case $IP_CHOICE in
        1) assign_ip_to_site "$ip_count" "${ip_list[@]}" ;;
        2) remove_ip_binding ;;
        3) verify_ip_bindings ;;
    esac
}

# ── Assign IP to a website ──
assign_ip_to_site() {
    local ip_count="$1"
    shift
    local ip_list=("$@")

    echo ""
    # Show domains
    IFS=',' read -ra DOMS <<< "$DOMAINS"
    echo -e "  ${YELLOW}Select website:${NC}"
    local j=1
    for d in "${DOMS[@]}"; do
        d=$(echo "$d" | xargs)
        echo -e "    $j. $d"
        ((j++))
    done
    read -p "  Site number: " SITE_NUM

    # Validate site selection
    if ! [[ "$SITE_NUM" =~ ^[0-9]+$ ]] || [ "$SITE_NUM" -lt 1 ] || [ "$SITE_NUM" -ge "$j" ]; then
        echo -e "${RED}  Invalid selection${NC}"
        pause; return
    fi

    local TARGET_DOMAIN=$(echo "${DOMS[$((SITE_NUM-1))]}" | xargs)
    validate_domain "$TARGET_DOMAIN" || { pause; return; }

    # Show IPs
    echo ""
    echo -e "  ${YELLOW}Select IP for $TARGET_DOMAIN:${NC}"
    for i in $(seq 1 $ip_count); do
        echo -e "    $i. ${ip_list[$((i-1))]}"
    done
    read -p "  IP number: " IP_NUM

    if ! [[ "$IP_NUM" =~ ^[0-9]+$ ]] || [ "$IP_NUM" -lt 1 ] || [ "$IP_NUM" -gt "$ip_count" ]; then
        echo -e "${RED}  Invalid selection${NC}"
        pause; return
    fi

    local TARGET_IP="${ip_list[$((IP_NUM-1))]}"
    _validate_ip "$TARGET_IP" || { pause; return; }

    local VHOST="/etc/nginx/conf.d/${TARGET_DOMAIN}.conf"
    if [ ! -f "$VHOST" ]; then
        echo -e "${RED}  Nginx vhost not found: $VHOST${NC}"
        pause; return
    fi

    # Backup vhost before modification
    cp "$VHOST" "${VHOST}.bak.$(date +%Y%m%d%H%M%S)"

    # Replace listen directives
    # listen 80; → listen IP:80;
    # listen 443 ssl ...; → listen IP:443 ssl ...;
    # Also handle existing IP bindings: listen OLD_IP:80; → listen NEW_IP:80;
    sed -i -E "s/listen[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:)?80;/listen ${TARGET_IP}:80;/g" "$VHOST"
    sed -i -E "s/listen[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:)?443([[:space:]]+ssl)/listen ${TARGET_IP}:443\2/g" "$VHOST"

    # Save binding to config
    touch "$IPBIND_CONF"
    chmod 600 "$IPBIND_CONF"
    # Remove old entry for this domain
    grep -v "^${TARGET_DOMAIN}=" "$IPBIND_CONF" > "${IPBIND_CONF}.tmp" 2>/dev/null
    mv "${IPBIND_CONF}.tmp" "$IPBIND_CONF"
    echo "${TARGET_DOMAIN}=${TARGET_IP}" >> "$IPBIND_CONF"

    # Test nginx config
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        echo -e "${GREEN}  ✓ $TARGET_DOMAIN now bound to $TARGET_IP${NC}"
    else
        echo -e "${RED}  ✗ Nginx config error! Restoring backup...${NC}"
        # Find latest backup
        local latest_bak=$(ls -t "${VHOST}.bak."* 2>/dev/null | head -1)
        if [ -n "$latest_bak" ]; then
            cp "$latest_bak" "$VHOST"
            systemctl reload nginx 2>/dev/null
            echo -e "${YELLOW}  Restored from backup${NC}"
        fi
    fi
    pause
}

# ── Remove IP binding ──
remove_ip_binding() {
    echo ""
    IFS=',' read -ra DOMS <<< "$DOMAINS"
    echo -e "  ${YELLOW}Select website to unbind:${NC}"

    # Only show sites with IP binding
    local bound_sites=()
    local j=1
    for d in "${DOMS[@]}"; do
        d=$(echo "$d" | xargs)
        local bound_ip=$(get_domain_ip "$d")
        if [ "$bound_ip" != "all" ]; then
            bound_sites+=("$d")
            echo -e "    $j. $d (bound to $bound_ip)"
            ((j++))
        fi
    done

    if [ ${#bound_sites[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}No sites with IP bindings found.${NC}"
        pause; return
    fi

    read -p "  Site number: " UNBIND_NUM
    if ! [[ "$UNBIND_NUM" =~ ^[0-9]+$ ]] || [ "$UNBIND_NUM" -lt 1 ] || [ "$UNBIND_NUM" -gt "${#bound_sites[@]}" ]; then
        echo -e "${RED}  Invalid selection${NC}"
        pause; return
    fi

    local UB_DOMAIN="${bound_sites[$((UNBIND_NUM-1))]}"
    validate_domain "$UB_DOMAIN" || { pause; return; }
    local VHOST="/etc/nginx/conf.d/${UB_DOMAIN}.conf"

    if [ ! -f "$VHOST" ]; then
        echo -e "${RED}  Vhost not found${NC}"
        pause; return
    fi

    # Backup
    cp "$VHOST" "${VHOST}.bak.$(date +%Y%m%d%H%M%S)"

    # Revert: listen IP:80; → listen 80;
    sed -i -E "s/listen[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:80;/listen 80;/g" "$VHOST"
    sed -i -E "s/listen[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:443([[:space:]]+ssl)/listen 443\1/g" "$VHOST"

    # Remove from config
    if [ -f "$IPBIND_CONF" ]; then
        grep -v "^${UB_DOMAIN}=" "$IPBIND_CONF" > "${IPBIND_CONF}.tmp" 2>/dev/null
        mv "${IPBIND_CONF}.tmp" "$IPBIND_CONF"
    fi

    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        echo -e "${GREEN}  ✓ $UB_DOMAIN unbound — now listening on all IPs${NC}"
    else
        echo -e "${RED}  ✗ Nginx error! Restoring backup...${NC}"
        local latest_bak=$(ls -t "${VHOST}.bak."* 2>/dev/null | head -1)
        [ -n "$latest_bak" ] && cp "$latest_bak" "$VHOST" && systemctl reload nginx 2>/dev/null
    fi
    pause
}

# ── Verify IP bindings ──
verify_ip_bindings() {
    echo ""
    echo -e "  ${YELLOW}Testing IP bindings...${NC}"
    echo ""
    IFS=',' read -ra DOMS <<< "$DOMAINS"
    for d in "${DOMS[@]}"; do
        d=$(echo "$d" | xargs)
        local bound_ip=$(get_domain_ip "$d")
        if [ "$bound_ip" != "all" ]; then
            # Test connection via specific IP
            local code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --resolve "${d}:443:${bound_ip}" "https://${d}" 2>/dev/null)
            if [ "$code" = "200" ] || [ "$code" = "301" ] || [ "$code" = "302" ]; then
                echo -e "    ${GREEN}✓${NC} $d → $bound_ip (HTTP $code)"
            else
                echo -e "    ${RED}✗${NC} $d → $bound_ip (HTTP $code)"
            fi
        else
            local code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://${d}" 2>/dev/null)
            echo -e "    ${WHITE}●${NC} $d → all IPs (HTTP $code)"
        fi
    done
    pause
}
