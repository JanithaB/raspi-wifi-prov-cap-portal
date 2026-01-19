#!/bin/bash

echo "Switching to AP Mode..."

# Stop any existing wpa_supplicant
sudo killall wpa_supplicant 2>/dev/null

# Configure static IP for wlan0
sudo tee /etc/dhcpcd.conf > /dev/null <<EOF
interface wlan0
static ip_address=192.168.5.1/24
nohook wpa_supplicant
EOF

# Restart dhcpcd
sudo systemctl restart dhcpcd
sleep 2

# Bring up wlan0
sudo ip link set wlan0 up
sudo ip addr flush dev wlan0
sudo ip addr add 192.168.5.1/24 dev wlan0

# Start services
sudo systemctl start dnsmasq
sudo systemctl start hostapd

# Start web portal
sudo pkill -f portal_server.py
sudo /usr/local/bin/portal_server.py &

echo "AP Mode activated!"
echo "SSID: RPi-Setup"
echo "Password: raspberry123"
echo "Portal: http://192.168.5.1"