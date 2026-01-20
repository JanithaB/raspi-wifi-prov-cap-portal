#!/bin/bash

# Log file for debugging
LOG_FILE="/tmp/wifi-connect.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== WiFi Connection Attempt at $(date) ==="

SSID="$1"
PASSWORD="$2"

if [ -z "$SSID" ]; then
    echo "Error: Usage: $0 <SSID> [PASSWORD|--open]"
    exit 1
fi

echo "Configuring WiFi credentials for: $SSID"

# Switch to client mode first
echo "Switching to client mode..."
/usr/local/bin/switch-to-client.sh

# Wait for services to stop
sleep 3

# Delete existing connection if it exists
echo "Removing existing connection if any..."
sudo nmcli connection delete "$SSID" 2>/dev/null || true

# Check if this is an open network
if [ "$PASSWORD" == "--open" ] || [ -z "$PASSWORD" ]; then
    echo "Connecting to OPEN network (no password)..."
    
    # Create connection for open network
    RESULT=$(sudo nmcli device wifi connect "$SSID" 2>&1)
    echo "nmcli result: $RESULT"
else
    echo "Connecting to SECURED network..."
    
    # Create connection for secured network
    RESULT=$(sudo nmcli device wifi connect "$SSID" password "$PASSWORD" 2>&1)
    echo "nmcli result: $RESULT"
fi

# Wait for connection to establish
echo "Waiting for connection to establish..."
sleep 5

# Check connection
CONNECTED=$(iwgetid -r 2>/dev/null)
if [ -n "$CONNECTED" ]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    echo ""
    echo "✓ Successfully connected to: $CONNECTED"
    echo "✓ IP Address: $IP_ADDR"
    echo ""
    echo "Connection saved. Raspberry Pi will auto-connect on reboot."
else
    echo ""
    echo "✗ Failed to connect to $SSID"
    echo "  nmcli output: $RESULT"
    echo "  Please check your credentials and try again"
    echo "  Or switch back to AP mode: sudo /usr/local/bin/switch-to-ap.sh"
fi

echo "=== End of connection attempt ==="