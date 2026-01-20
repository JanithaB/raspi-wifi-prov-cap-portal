#!/bin/bash

echo "Switching to Client Mode..."

# Stop AP services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sudo systemctl disable hostapd
sudo systemctl disable dnsmasq
sudo pkill -f portal_server.py

# Clear iptables rules
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo netfilter-persistent save

# Reconfigure wlan0 for client mode
sudo ip addr flush dev wlan0
sudo ip link set wlan0 down
sleep 1

# Re-enable NetworkManager management of wlan0
sudo rm -f /etc/NetworkManager/conf.d/unmanaged.conf
sudo systemctl reload NetworkManager

# Wait for NetworkManager to reload
sleep 2

# Bring up wlan0 for NetworkManager
sudo ip link set wlan0 up

# Explicitly tell NetworkManager to manage wlan0
sudo nmcli device set wlan0 managed yes

# Wait for NetworkManager to fully initialize the interface
sleep 3

echo "Client Mode activated!"
echo "NetworkManager will now manage wlan0"
echo "Ready to connect to WiFi network..."