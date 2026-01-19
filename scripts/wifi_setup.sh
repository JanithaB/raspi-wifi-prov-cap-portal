#!/bin/bash

SSID=$1
PASSWORD=$2

# Stop the AP services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Configure wpa_supplicant with the new credentials
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

# Bring down wlan0 and reconfigure it as a client
sudo ip addr flush dev wlan0
sudo systemctl restart dhcpcd

# Wait for connection
sleep 5

# Check if connected
if iwgetid -r; then
    echo "Successfully connected to $SSID"
else
    echo "Failed to connect. Restarting AP mode..."
    sudo systemctl start hostapd
    sudo systemctl start dnsmasq
fi