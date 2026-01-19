#!/bin/bash

echo "Switching to Client Mode..."

# Stop AP services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sudo pkill -f portal_server.py

# Reset dhcpcd to normal
sudo tee /etc/dhcpcd.conf > /dev/null <<EOF
hostname
clientid
persistent
option rapid_commit
option domain_name_servers, domain_name, domain_search, host_name
option classless_static_routes
option interface_mtu
require dhcp_server_identifier
slaac private
EOF

# Restart dhcpcd
sudo systemctl restart dhcpcd

# Reconfigure wlan0 for client mode
sudo ip addr flush dev wlan0

echo "Client Mode activated!"
echo "The device will now connect using /etc/wpa_supplicant/wpa_supplicant.conf"
echo "Restarting network..."
sudo systemctl restart dhcpcd