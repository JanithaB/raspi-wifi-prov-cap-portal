#!/bin/bash

# Test script to diagnose WiFi connection setup issues

echo "======================================"
echo "WiFi Connection Setup Diagnostic Test"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# Test 1: Check if scripts exist
echo "1. Checking if scripts are installed..."
if [ -f "/usr/local/bin/switch-to-wifi-client.sh" ]; then
    success "switch-to-wifi-client.sh exists"
else
    error "switch-to-wifi-client.sh NOT FOUND"
fi

if [ -f "/usr/local/bin/wifi-connection-monitor.sh" ]; then
    success "wifi-connection-monitor.sh exists"
else
    error "wifi-connection-monitor.sh NOT FOUND"
fi

if [ -f "/usr/local/bin/wifi-reconnect-on-boot.sh" ]; then
    success "wifi-reconnect-on-boot.sh exists"
else
    error "wifi-reconnect-on-boot.sh NOT FOUND"
fi

if [ -f "/usr/local/bin/switch-to-ap-mode.sh" ]; then
    success "switch-to-ap-mode.sh exists"
else
    error "switch-to-ap-mode.sh NOT FOUND"
fi

echo ""

# Test 2: Check if scripts are executable
echo "2. Checking if scripts are executable..."
if [ -x "/usr/local/bin/switch-to-wifi-client.sh" ]; then
    success "switch-to-wifi-client.sh is executable"
else
    error "switch-to-wifi-client.sh is NOT executable"
fi

echo ""

# Test 3: Check sudoers file
echo "3. Checking sudoers configuration..."
if [ -f "/etc/sudoers.d/raspi-captive-portal" ]; then
    success "Sudoers file exists"
    
    # Check permissions (should be 0440)
    PERMS=$(stat -c %a /etc/sudoers.d/raspi-captive-portal 2>/dev/null)
    if [ "$PERMS" = "440" ]; then
        success "Sudoers file has correct permissions (440)"
    else
        error "Sudoers file has incorrect permissions: $PERMS (should be 440)"
    fi
    
    # Validate sudoers file
    if sudo visudo -c -f /etc/sudoers.d/raspi-captive-portal &> /dev/null; then
        success "Sudoers file is valid"
    else
        error "Sudoers file is INVALID"
    fi
    
    # Show contents
    echo "   Contents:"
    sudo cat /etc/sudoers.d/raspi-captive-portal | sed 's/^/   /'
else
    error "Sudoers file NOT FOUND at /etc/sudoers.d/raspi-captive-portal"
    echo "   This is likely the cause of the issue!"
fi

echo ""

# Test 4: Test sudo permission
echo "4. Testing sudo permissions (you should NOT be prompted for password)..."
if sudo -n /usr/local/bin/switch-to-wifi-client.sh 2>&1 | grep -q "Usage:"; then
    success "Can execute script with sudo without password"
elif sudo -n /usr/local/bin/switch-to-wifi-client.sh &> /dev/null; then
    success "Can execute script with sudo without password"
else
    error "CANNOT execute script with sudo without password"
    echo "   Run: sudo ./access-point/setup-wifi-scripts.sh"
fi

echo ""

# Test 5: Check services
echo "5. Checking systemd services..."
if systemctl list-unit-files | grep -q "access-point-server.service"; then
    success "access-point-server.service is installed"
    if systemctl is-enabled access-point-server &> /dev/null; then
        success "access-point-server.service is enabled"
    else
        warning "access-point-server.service is NOT enabled"
    fi
    if systemctl is-active access-point-server &> /dev/null; then
        success "access-point-server.service is running"
    else
        error "access-point-server.service is NOT running"
    fi
else
    error "access-point-server.service is NOT installed"
fi

if systemctl list-unit-files | grep -q "wifi-reconnect-on-boot.service"; then
    success "wifi-reconnect-on-boot.service is installed"
else
    error "wifi-reconnect-on-boot.service is NOT installed"
fi

echo ""

# Test 6: Check network interfaces
echo "6. Checking network interfaces..."
if ip link show wlan0 &> /dev/null; then
    success "wlan0 interface exists"
else
    error "wlan0 interface NOT FOUND"
fi

# Check if blocked
if command -v rfkill &> /dev/null; then
    if rfkill list wlan | grep -q "Soft blocked: yes"; then
        error "wlan is soft blocked"
        echo "   Run: sudo rfkill unblock wlan"
    else
        success "wlan is not blocked"
    fi
fi

echo ""

# Test 7: Check AP services
echo "7. Checking Access Point services..."
if systemctl is-active hostapd &> /dev/null; then
    success "hostapd is running (AP mode active)"
else
    warning "hostapd is NOT running"
fi

if systemctl is-active dnsmasq &> /dev/null; then
    success "dnsmasq is running"
else
    warning "dnsmasq is NOT running"
fi

echo ""

# Test 8: Check credentials directory
echo "8. Checking credentials directory..."
if [ -d "/etc/raspi-captive-portal" ]; then
    success "Credentials directory exists"
    if [ -f "/etc/raspi-captive-portal/wifi_ssid" ]; then
        SAVED_SSID=$(cat /etc/raspi-captive-portal/wifi_ssid)
        warning "Found saved WiFi credentials for SSID: $SAVED_SSID"
    else
        success "No saved credentials (fresh install)"
    fi
else
    error "Credentials directory does NOT exist"
fi

echo ""

# Summary
echo "======================================"
echo "Diagnostic Summary"
echo "======================================"
echo ""
echo "To view server logs:"
echo "  sudo journalctl -u access-point-server -n 50"
echo ""
echo "To test the WiFi switch manually:"
echo "  sudo /usr/local/bin/switch-to-wifi-client.sh \"YourSSID\" \"YourPassword\""
echo ""
echo "To test the API endpoint:"
echo "  curl -X POST http://192.168.4.1:3000/api/connect-wifi \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"ssid\":\"TestNetwork\",\"password\":\"testpass\"}'"
echo ""
echo "If sudoers file is missing, run:"
echo "  cd /path/to/raspi-captive-portal/access-point"
echo "  sudo ./setup-wifi-scripts.sh"
echo ""
