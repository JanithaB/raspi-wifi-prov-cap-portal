#!/bin/bash

SSID="$1"
PASSWORD="$2"

if [ -z "$SSID" ]; then
    echo "Usage: $0 <SSID> [PASSWORD|--open]"
    exit 1
fi

echo "Configuring WiFi credentials for: $SSID"

# Check if this is an open network
if [ "$PASSWORD" == "--open" ] || [ -z "$PASSWORD" ]; then
    echo "Configuring as OPEN network (no password)"
    
    # Create wpa_supplicant configuration for open network
    sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="$SSID"
    key_mgmt=NONE
}
EOF
else
    echo "Configuring as SECURED network"
    
    # Create wpa_supplicant configuration for secured network
    sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="$SSID"
    psk="$PASSWORD"
    key_mgmt=WPA-PSK
}
EOF
fi

echo "Credentials saved. Switching to client mode..."
/usr/local/bin/switch-to-client.sh

sleep 5

# Check connection
CONNECTED=$(iwgetid -r 2>/dev/null)
if [ -n "$CONNECTED" ]; then
    echo ""
    echo "✓ Successfully connected to: $CONNECTED"
    echo "✓ IP Address: $(hostname -I | awk '{print $1}')"
else
    echo ""
    echo "✗ Failed to connect to $SSID"
    echo "  Please check your credentials and try again"
    echo "  Or switch back to AP mode: sudo switch-to-ap.sh"
fi