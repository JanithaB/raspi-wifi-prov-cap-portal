#!/bin/sh

# Setup WiFi management scripts and services

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Copy scripts to /usr/local/bin
sudo cp "$PROJECT_ROOT/scripts/switch-to-wifi-client.sh" /usr/local/bin/
sudo cp "$PROJECT_ROOT/scripts/wifi-connection-monitor.sh" /usr/local/bin/
sudo cp "$PROJECT_ROOT/scripts/wifi-reconnect-on-boot.sh" /usr/local/bin/
sudo cp "$PROJECT_ROOT/scripts/switch-to-ap-mode.sh" /usr/local/bin/
sudo cp "$PROJECT_ROOT/scripts/verify-wifi-config.sh" /usr/local/bin/
sudo cp "$PROJECT_ROOT/scripts/check-services.sh" /usr/local/bin/

# Make scripts executable
sudo chmod +x /usr/local/bin/switch-to-wifi-client.sh
sudo chmod +x /usr/local/bin/wifi-connection-monitor.sh
sudo chmod +x /usr/local/bin/wifi-reconnect-on-boot.sh
sudo chmod +x /usr/local/bin/switch-to-ap-mode.sh
sudo chmod +x /usr/local/bin/verify-wifi-config.sh
sudo chmod +x /usr/local/bin/check-services.sh

# Create directory for WiFi credentials
sudo mkdir -p /etc/raspi-captive-portal

# Setup systemd services
sudo cp "$SCRIPT_DIR/wifi-connection-monitor.service" /etc/systemd/system/
sudo cp "$SCRIPT_DIR/wifi-reconnect-on-boot.service" /etc/systemd/system/

# Reload systemd to recognize new services
sudo systemctl daemon-reload

# Enable WiFi reconnect on boot service
echo "Enabling wifi-reconnect-on-boot.service..."
sudo systemctl enable wifi-reconnect-on-boot.service

# Verify the service is enabled
if systemctl is-enabled wifi-reconnect-on-boot.service &> /dev/null; then
    echo "✓ wifi-reconnect-on-boot.service is enabled"
else
    echo "✗ WARNING: Failed to enable wifi-reconnect-on-boot.service"
fi

# Show service status
echo ""
echo "Service status:"
systemctl status wifi-reconnect-on-boot.service --no-pager || true

# Setup sudoers file for passwordless WiFi script execution
echo "Setting up sudoers configuration for WiFi scripts..."
# Get the current username
CURRENT_USER="${SUDO_USER:-$(whoami)}"
echo "Configuring for user: $CURRENT_USER"

# Create a temporary sudoers file with the correct username
sudo sed "s/^pi /$CURRENT_USER /" "$SCRIPT_DIR/raspi-captive-portal-sudoers" | \
    sudo tee /etc/sudoers.d/raspi-captive-portal > /dev/null

# Set correct permissions (sudoers files must be 0440)
sudo chmod 0440 /etc/sudoers.d/raspi-captive-portal

# Verify the sudoers file is valid
if sudo visudo -c -f /etc/sudoers.d/raspi-captive-portal; then
    echo "Sudoers configuration installed successfully"
else
    echo "ERROR: Sudoers configuration is invalid! Removing..."
    sudo rm /etc/sudoers.d/raspi-captive-portal
    exit 1
fi

echo "WiFi management scripts and services installed successfully"
