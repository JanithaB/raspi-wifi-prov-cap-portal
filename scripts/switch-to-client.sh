#!/bin/bash

echo "Switching to Client Mode..."

# Stop AP services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
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
sudo ip link set wlan0 up

# Re-enable NetworkManager management of wlan0
sudo rm -f /etc/NetworkManager/conf.d/unmanaged.conf
sudo systemctl reload NetworkManager

# Wait for NetworkManager to take over
sleep 2

echo "Client Mode activated!"
echo "NetworkManager will now manage wlan0"
echo "Ready to connect to WiFi network..."