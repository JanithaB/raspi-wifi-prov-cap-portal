# WiFi Connection Setup - Complete Flow Documentation

## Overview
This document describes the complete flow of the WiFi connection system, including service startup, connection monitoring, and fallback mechanisms.

## System Components

### 1. Systemd Services

#### a. `access-point-server.service`
- **Purpose**: Runs the Node.js captive portal server
- **Status**: Enabled and started during initial setup
- **Auto-start**: Yes (on boot)
- **Port**: 3000
- **Location**: `/etc/systemd/system/access-point-server.service`

#### b. `wifi-reconnect-on-boot.service`
- **Purpose**: Attempts to reconnect to saved WiFi network on boot
- **Status**: Enabled during WiFi scripts setup
- **Type**: oneshot (runs once at boot)
- **Auto-start**: Yes (on boot)
- **Dependencies**: After network.target, dhcpcd.service, wpa_supplicant.service
- **Location**: `/etc/systemd/system/wifi-reconnect-on-boot.service`

#### c. `wifi-connection-monitor.service`
- **Purpose**: Monitors WiFi connection and falls back to AP mode if connection fails
- **Status**: Enabled and started ONLY when WiFi client mode is active
- **Type**: simple (runs continuously)
- **Auto-start**: Only when WiFi credentials exist and connection is established
- **Dependencies**: After network.target, wpa_supplicant.service
- **Location**: `/etc/systemd/system/wifi-connection-monitor.service`

### 2. Scripts

#### a. `switch-to-wifi-client.sh`
- **Location**: `/usr/local/bin/switch-to-wifi-client.sh`
- **Called by**: Backend API when user submits WiFi credentials
- **Actions**:
  1. Stops hostapd and dnsmasq (AP services)
  2. Disables hostapd and dnsmasq
  3. Stops access-point-server (but keeps it enabled)
  4. Removes static IP configuration from dhcpcd.conf
  5. Creates/updates wpa_supplicant.conf with network credentials
  6. Saves credentials to `/etc/raspi-captive-portal/wifi_ssid` and `wifi_password`
  7. Restarts dhcpcd
  8. Enables and starts wpa_supplicant
  9. Waits 10 seconds for connection
  10. Enables and starts wifi-connection-monitor.service

#### b. `wifi-reconnect-on-boot.sh`
- **Location**: `/usr/local/bin/wifi-reconnect-on-boot.sh`
- **Called by**: wifi-reconnect-on-boot.service on boot
- **Actions**:
  1. Checks if WiFi credentials exist in `/etc/raspi-captive-portal/`
  2. If no credentials found, exits (stays in AP mode)
  3. If credentials found, ensures wpa_supplicant is enabled and started
  4. Waits up to 3 minutes (180 seconds) for connection
  5. If connected, enables and starts wifi-connection-monitor.service
  6. If connection fails, calls switch-to-ap-mode.sh

#### c. `wifi-connection-monitor.sh`
- **Location**: `/usr/local/bin/wifi-connection-monitor.sh`
- **Called by**: wifi-connection-monitor.service (continuous)
- **Actions**:
  1. Checks WiFi connection and internet connectivity every 30 seconds
  2. If connection lost for 5 minutes (300 seconds), switches to AP mode
  3. Logs all activities to `/var/log/wifi-connection-monitor.log`

#### d. `switch-to-ap-mode.sh`
- **Location**: `/usr/local/bin/switch-to-ap-mode.sh`
- **Called by**: wifi-connection-monitor.sh or wifi-reconnect-on-boot.sh
- **Actions**:
  1. Stops and disables wifi-connection-monitor.service
  2. Stops wpa_supplicant
  3. Adds static IP configuration to dhcpcd.conf
  4. Restarts dhcpcd
  5. Enables and starts hostapd and dnsmasq
  6. Starts access-point-server

## Complete Flow Diagrams

### Initial Setup Flow
```
1. User runs: sudo python setup.py
   ├─> Installs Node.js
   ├─> Runs setup-access-point.sh
   │   ├─> Installs packages (dhcpcd, dnsmasq, hostapd)
   │   ├─> Configures static IP (192.168.4.1/24)
   │   ├─> Enables and starts hostapd
   │   └─> Enables and starts dnsmasq
   ├─> Installs Node.js dependencies
   ├─> Builds server
   ├─> Runs setup-server.sh
   │   ├─> Copies access-point-server.service
   │   ├─> Enables access-point-server
   │   └─> Starts access-point-server
   └─> Runs setup-wifi-scripts.sh
       ├─> Copies all WiFi scripts to /usr/local/bin
       ├─> Copies service files to /etc/systemd/system
       ├─> Enables wifi-reconnect-on-boot.service
       └─> Reloads systemd

2. Device is now in AP mode
   - SSID: Captive Portal (or as configured in hostapd.conf)
   - Password: 12345678 (or as configured)
   - Captive portal running on port 3000
```

### User Connects to WiFi Flow
```
1. User connects to AP and opens captive portal
2. User enters WiFi SSID and password (optional for open networks)
3. User clicks "Connect to WiFi"
   ├─> Frontend sends POST to /api/connect-wifi
   ├─> Backend calls switch-to-wifi-client.sh
   │   ├─> Stops AP services (hostapd, dnsmasq)
   │   ├─> Disables AP services
   │   ├─> Stops access-point-server (keeps enabled)
   │   ├─> Removes static IP from dhcpcd.conf
   │   ├─> Creates/updates wpa_supplicant.conf
   │   ├─> Saves credentials to /etc/raspi-captive-portal/
   │   ├─> Restarts dhcpcd
   │   ├─> Enables and starts wpa_supplicant
   │   ├─> Waits 10 seconds
   │   ├─> Checks connection
   │   ├─> Enables wifi-connection-monitor.service
   │   └─> Starts wifi-connection-monitor.service
   └─> Returns success to frontend

4. Device is now in WiFi client mode
   - Connected to user's WiFi network
   - wifi-connection-monitor.service running
   - AP services disabled
```

### Boot After WiFi Configuration Flow
```
1. System boots
2. wifi-reconnect-on-boot.service starts
   ├─> Checks for saved credentials in /etc/raspi-captive-portal/
   ├─> If no credentials: exits (stays in AP mode)
   └─> If credentials exist:
       ├─> Ensures wpa_supplicant is enabled and started
       ├─> Waits up to 3 minutes for connection
       ├─> Checks connection every 5 seconds
       ├─> If connected:
       │   ├─> Enables wifi-connection-monitor.service
       │   ├─> Starts wifi-connection-monitor.service
       │   └─> Exits successfully
       └─> If connection fails after 3 minutes:
           └─> Calls switch-to-ap-mode.sh
               ├─> Stops wpa_supplicant
               ├─> Adds static IP to dhcpcd.conf
               ├─> Restarts dhcpcd
               ├─> Enables and starts hostapd
               ├─> Enables and starts dnsmasq
               └─> Starts access-point-server

3. Device is now either:
   - In WiFi client mode (if connection succeeded)
   - In AP mode (if connection failed)
```

### WiFi Connection Monitoring Flow
```
1. wifi-connection-monitor.service is running (only in WiFi client mode)
2. Every 30 seconds:
   ├─> Checks if wlan0 has IP address
   ├─> Checks if connected to SSID (using iwgetid)
   ├─> Checks internet connectivity (ping 8.8.8.8)
   └─> If all checks pass:
       ├─> Updates last connected time
       └─> Continues monitoring
   └─> If checks fail:
       ├─> Calculates time since last connection
       ├─> If < 5 minutes: logs warning and continues
       └─> If >= 5 minutes:
           └─> Calls switch_to_ap_mode() function
               ├─> Stops wifi-connection-monitor.service
               ├─> Stops wpa_supplicant
               ├─> Adds static IP to dhcpcd.conf
               ├─> Restarts dhcpcd
               ├─> Enables and starts hostapd
               ├─> Enables and starts dnsmasq
               ├─> Starts access-point-server
               └─> Exits monitoring loop

3. Device is back in AP mode
```

## Service States by Mode

### AP Mode (Default)
- ✅ hostapd: enabled, running
- ✅ dnsmasq: enabled, running
- ✅ access-point-server: enabled, running
- ✅ wifi-reconnect-on-boot: enabled (but exits if no credentials)
- ❌ wpa_supplicant: disabled, stopped
- ❌ wifi-connection-monitor: disabled, stopped

### WiFi Client Mode (After Connection)
- ❌ hostapd: disabled, stopped
- ❌ dnsmasq: disabled, stopped
- ✅ access-point-server: enabled, stopped (ready for AP fallback)
- ✅ wifi-reconnect-on-boot: enabled (will reconnect on boot)
- ✅ wpa_supplicant: enabled, running
- ✅ wifi-connection-monitor: enabled, running

## Key Files and Locations

### Configuration Files
- `/etc/dhcpcd.conf` - Network interface configuration
- `/etc/hostapd/hostapd.conf` - Access Point configuration
- `/etc/dnsmasq.conf` - DNS/DHCP server configuration
- `/etc/wpa_supplicant/wpa_supplicant.conf` - WiFi client configuration

### Credential Storage
- `/etc/raspi-captive-portal/wifi_ssid` - Saved WiFi SSID
- `/etc/raspi-captive-portal/wifi_password` - Saved WiFi password

### Log Files
- `/var/log/wifi-reconnect.log` - Boot reconnection logs
- `/var/log/wifi-connection-monitor.log` - Connection monitoring logs
- `/var/log/wifi-setup.log` - AP mode switch logs

### Scripts
- `/usr/local/bin/switch-to-wifi-client.sh`
- `/usr/local/bin/wifi-reconnect-on-boot.sh`
- `/usr/local/bin/wifi-connection-monitor.sh`
- `/usr/local/bin/switch-to-ap-mode.sh`

### Services
- `/etc/systemd/system/access-point-server.service`
- `/etc/systemd/system/wifi-reconnect-on-boot.service`
- `/etc/systemd/system/wifi-connection-monitor.service`

## Troubleshooting Commands

### Check Service Status
```bash
# Check all WiFi-related services
sudo systemctl status access-point-server
sudo systemctl status wifi-reconnect-on-boot
sudo systemctl status wifi-connection-monitor
sudo systemctl status hostapd
sudo systemctl status dnsmasq
sudo systemctl status wpa_supplicant

# Check logs
sudo journalctl -u wifi-reconnect-on-boot -n 50
sudo journalctl -u wifi-connection-monitor -n 50
tail -f /var/log/wifi-connection-monitor.log
tail -f /var/log/wifi-reconnect.log
```

### Manual Mode Switching
```bash
# Switch to WiFi client mode manually
sudo /usr/local/bin/switch-to-wifi-client.sh "YourSSID" "YourPassword"

# Switch to AP mode manually
sudo /usr/local/bin/switch-to-ap-mode.sh
```

### Check WiFi Connection
```bash
# Check if connected
iwgetid wlan0

# Check IP address
ip addr show wlan0

# Check internet connectivity
ping -c 3 8.8.8.8
```

## Important Notes

1. **wifi-connection-monitor.service** is ONLY enabled and started when in WiFi client mode
2. **access-point-server** remains enabled even in WiFi client mode for quick AP fallback
3. **wifi-reconnect-on-boot** is always enabled but only acts if credentials exist
4. Credentials are saved in plain text in `/etc/raspi-captive-portal/` - ensure proper file permissions
5. Connection timeout: 5 minutes (300 seconds) before falling back to AP mode
6. Boot reconnection timeout: 3 minutes (180 seconds) before falling back to AP mode
