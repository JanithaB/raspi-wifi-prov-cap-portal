#!/bin/bash

# Script to check all WiFi-related services status

echo "======================================"
echo "WiFi Services Status Check"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if service file exists
check_service_file() {
    SERVICE=$1
    if [ -f "/etc/systemd/system/$SERVICE" ]; then
        echo -e "${GREEN}✓${NC} Service file exists: $SERVICE"
        return 0
    else
        echo -e "${RED}✗${NC} Service file MISSING: $SERVICE"
        return 1
    fi
}

# Check service status
check_service_status() {
    SERVICE=$1
    echo ""
    echo "--- $SERVICE ---"
    
    if ! check_service_file "$SERVICE"; then
        echo -e "${RED}  Service file not installed!${NC}"
        return 1
    fi
    
    # Check if enabled
    if systemctl is-enabled "$SERVICE" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Enabled (will run on boot)"
    else
        echo -e "${YELLOW}⚠${NC} NOT enabled (won't run on boot)"
    fi
    
    # Check if active
    if systemctl is-active "$SERVICE" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Currently running"
    else
        STATUS=$(systemctl show -p ActiveState --value "$SERVICE")
        if [ "$STATUS" = "inactive" ]; then
            echo -e "${YELLOW}⚠${NC} Not running (this may be normal for oneshot services)"
        else
            echo -e "${RED}✗${NC} Not running (Status: $STATUS)"
        fi
    fi
    
    # Show last run status
    if systemctl status "$SERVICE" &> /dev/null; then
        RESULT=$(systemctl show -p Result --value "$SERVICE")
        if [ "$RESULT" = "success" ]; then
            echo -e "${GREEN}✓${NC} Last run: Success"
        elif [ "$RESULT" = "exit-code" ]; then
            echo -e "${RED}✗${NC} Last run: Failed"
        else
            echo "  Last run: $RESULT"
        fi
    fi
}

echo "1. Checking wifi-reconnect-on-boot.service"
check_service_status "wifi-reconnect-on-boot.service"

echo ""
echo "2. Checking wifi-connection-monitor.service"
check_service_status "wifi-connection-monitor.service"

echo ""
echo "3. Checking access-point-server.service"
check_service_status "access-point-server.service"

echo ""
echo "4. Checking system services"
echo ""

# hostapd
echo "--- hostapd (Access Point) ---"
if systemctl is-active hostapd &> /dev/null; then
    echo -e "${GREEN}✓${NC} Running (AP mode active)"
elif systemctl is-enabled hostapd &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Enabled but not running (WiFi client mode?)"
else
    echo "  Disabled (WiFi client mode)"
fi

# dnsmasq
echo ""
echo "--- dnsmasq (DHCP/DNS) ---"
if systemctl is-active dnsmasq &> /dev/null; then
    echo -e "${GREEN}✓${NC} Running (AP mode active)"
elif systemctl is-enabled dnsmasq &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Enabled but not running (WiFi client mode?)"
else
    echo "  Disabled (WiFi client mode)"
fi

# wpa_supplicant
echo ""
echo "--- wpa_supplicant (WiFi Client) ---"
if systemctl is-active wpa_supplicant &> /dev/null; then
    echo -e "${GREEN}✓${NC} Running (WiFi client mode active)"
elif systemctl is-enabled wpa_supplicant &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Enabled but not running"
else
    echo "  Disabled or not configured"
fi

# Check interface-specific wpa_supplicant
if systemctl list-unit-files | grep -q "wpa_supplicant@wlan0.service"; then
    if systemctl is-active wpa_supplicant@wlan0 &> /dev/null; then
        echo -e "${GREEN}✓${NC} wpa_supplicant@wlan0 running"
    fi
fi

echo ""
echo "======================================"
echo "Service Logs (Last 10 Lines Each)"
echo "======================================"

echo ""
echo "--- wifi-reconnect-on-boot.service logs ---"
if systemctl list-unit-files | grep -q "wifi-reconnect-on-boot.service"; then
    sudo journalctl -u wifi-reconnect-on-boot.service -n 10 --no-pager 2>/dev/null || echo "No logs available"
else
    echo "Service not installed"
fi

echo ""
echo "--- wifi-connection-monitor.service logs ---"
if systemctl list-unit-files | grep -q "wifi-connection-monitor.service"; then
    sudo journalctl -u wifi-connection-monitor.service -n 10 --no-pager 2>/dev/null || echo "No logs available"
else
    echo "Service not installed"
fi

echo ""
echo "--- access-point-server.service logs ---"
if systemctl list-unit-files | grep -q "access-point-server.service"; then
    sudo journalctl -u access-point-server.service -n 10 --no-pager 2>/dev/null || echo "No logs available"
else
    echo "Service not installed"
fi

echo ""
echo "======================================"
echo "Current Mode Detection"
echo "======================================"
echo ""

# Detect current mode
if systemctl is-active hostapd &> /dev/null && systemctl is-active dnsmasq &> /dev/null; then
    echo "Current Mode: ACCESS POINT (AP)"
    echo "  - hostapd is running"
    echo "  - dnsmasq is running"
    echo "  - Captive portal should be accessible"
elif systemctl is-active wpa_supplicant &> /dev/null || systemctl is-active wpa_supplicant@wlan0 &> /dev/null; then
    echo "Current Mode: WiFi CLIENT"
    echo "  - wpa_supplicant is running"
    if iwgetid wlan0 &> /dev/null; then
        SSID=$(iwgetid wlan0 -r)
        echo "  - Connected to: $SSID"
    else
        echo "  - Not connected to any network"
    fi
else
    echo "Current Mode: UNKNOWN or TRANSITIONING"
    echo "  - No clear mode detected"
fi

echo ""
echo "======================================"
echo "Quick Commands"
echo "======================================"
echo ""
echo "View full logs:"
echo "  sudo journalctl -u wifi-reconnect-on-boot.service --no-pager"
echo "  sudo journalctl -u wifi-connection-monitor.service --no-pager"
echo "  sudo journalctl -u access-point-server.service --no-pager"
echo ""
echo "Check if services are installed:"
echo "  systemctl list-unit-files | grep wifi"
echo ""
echo "Manually trigger wifi-reconnect-on-boot:"
echo "  sudo systemctl start wifi-reconnect-on-boot.service"
echo "  sudo journalctl -u wifi-reconnect-on-boot.service -f"
echo ""
echo "Enable services:"
echo "  sudo systemctl enable wifi-reconnect-on-boot.service"
echo "  sudo systemctl daemon-reload"
echo ""
