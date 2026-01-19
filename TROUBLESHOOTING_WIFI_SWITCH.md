# Troubleshooting: WiFi Switch Not Executing

## Issue
The switch to WiFi client mode is not executing when submitting credentials through the captive portal.

## Common Causes and Solutions

### 1. Sudo Permission Issues (Most Common)

**Problem**: The Node.js server doesn't have permission to execute sudo commands without a password.

**Solution**: Install the sudoers configuration file.

```bash
# Check if the sudoers file exists
ls -la /etc/sudoers.d/raspi-captive-portal

# If it doesn't exist, run the setup again
cd /path/to/raspi-captive-portal
sudo python setup.py
# Or specifically run the WiFi scripts setup
cd access-point
sudo ./setup-wifi-scripts.sh

# Verify the sudoers file is valid
sudo visudo -c -f /etc/sudoers.d/raspi-captive-portal

# Check the contents
sudo cat /etc/sudoers.d/raspi-captive-portal
```

**Expected sudoers file content:**
```
# Replace 'pi' with your actual username
pi ALL=(ALL) NOPASSWD: /usr/local/bin/switch-to-wifi-client.sh
pi ALL=(ALL) NOPASSWD: /usr/local/bin/switch-to-ap-mode.sh
pi ALL=(ALL) NOPASSWD: /usr/local/bin/wifi-connection-monitor.sh
pi ALL=(ALL) NOPASSWD: /usr/local/bin/wifi-reconnect-on-boot.sh
```

**Test sudo permissions:**
```bash
# Should run without prompting for password
sudo /usr/local/bin/switch-to-wifi-client.sh "TestSSID" "TestPassword"
```

### 2. Script Not Installed

**Problem**: The script file doesn't exist in `/usr/local/bin/`.

**Solution**: Check and install scripts.

```bash
# Check if scripts exist
ls -la /usr/local/bin/switch-to-wifi-client.sh
ls -la /usr/local/bin/wifi-connection-monitor.sh
ls -la /usr/local/bin/wifi-reconnect-on-boot.sh
ls -la /usr/local/bin/switch-to-ap-mode.sh

# If missing, copy them
cd /path/to/raspi-captive-portal
sudo cp scripts/*.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/switch-to-wifi-client.sh
sudo chmod +x /usr/local/bin/wifi-connection-monitor.sh
sudo chmod +x /usr/local/bin/wifi-reconnect-on-boot.sh
sudo chmod +x /usr/local/bin/switch-to-ap-mode.sh
```

### 3. Server Not Running or Crashed

**Problem**: The Node.js server is not running or has crashed.

**Solution**: Check server status and restart.

```bash
# Check server status
sudo systemctl status access-point-server

# View recent logs
sudo journalctl -u access-point-server -n 50 --no-pager

# Restart server
sudo systemctl restart access-point-server

# Follow logs in real-time
sudo journalctl -u access-point-server -f
```

### 4. Script Execution Errors

**Problem**: The script is executing but failing due to errors.

**Solution**: Check logs and test manually.

```bash
# Check system logs for errors
sudo journalctl -n 100 --no-pager | grep -i wifi
sudo journalctl -n 100 --no-pager | grep -i switch

# Test script manually with debug output
sudo bash -x /usr/local/bin/switch-to-wifi-client.sh "YourSSID" "YourPassword"

# Check if required services are available
systemctl status hostapd
systemctl status dnsmasq
systemctl status dhcpcd
```

### 5. Network Interface Issues

**Problem**: The `wlan0` interface is not available or in a bad state.

**Solution**: Check interface status.

```bash
# List network interfaces
ip link show

# Check wlan0 specifically
ip addr show wlan0

# Check if wlan0 is blocked
sudo rfkill list

# Unblock if needed
sudo rfkill unblock wlan

# Restart network services
sudo systemctl restart dhcpcd
```

### 6. Frontend Not Sending Request

**Problem**: The form is not actually sending the request to the backend.

**Solution**: Check browser console and network tab.

**Browser Developer Console:**
1. Open browser developer tools (F12)
2. Go to Console tab
3. Look for error messages
4. Go to Network tab
5. Submit the form
6. Check if POST request to `/api/connect-wifi` is sent
7. Check the response status and body

### 7. Server Not Receiving Request

**Problem**: Request is not reaching the backend endpoint.

**Solution**: Check server logs and test endpoint.

```bash
# Watch server logs while submitting form
sudo journalctl -u access-point-server -f

# Test endpoint manually with curl
curl -X POST http://192.168.4.1:3000/api/connect-wifi \
  -H "Content-Type: application/json" \
  -d '{"ssid":"TestNetwork","password":"testpass123"}'
```

## Debug Checklist

Run through this checklist to diagnose the issue:

1. **Check if server is running:**
   ```bash
   sudo systemctl status access-point-server
   ```

2. **Check if sudoers file exists and is valid:**
   ```bash
   sudo visudo -c -f /etc/sudoers.d/raspi-captive-portal
   ```

3. **Check if script exists and is executable:**
   ```bash
   ls -la /usr/local/bin/switch-to-wifi-client.sh
   ```

4. **Test sudo permission:**
   ```bash
   sudo /usr/local/bin/switch-to-wifi-client.sh "TestSSID" "TestPass"
   ```

5. **Check server logs for errors:**
   ```bash
   sudo journalctl -u access-point-server -n 50
   ```

6. **Test the API endpoint:**
   ```bash
   curl -X POST http://192.168.4.1:3000/api/connect-wifi \
     -H "Content-Type: application/json" \
     -d '{"ssid":"TestNetwork","password":"testpass"}'
   ```

7. **Check if services are conflicting:**
   ```bash
   systemctl status hostapd dnsmasq wpa_supplicant
   ```

## Manual Fix for Sudoers

If the sudoers file is not working, manually create it:

```bash
# Get your username
whoami

# Create the sudoers file (replace 'pi' with your username)
sudo tee /etc/sudoers.d/raspi-captive-portal > /dev/null << 'EOF'
pi ALL=(ALL) NOPASSWD: /usr/local/bin/switch-to-wifi-client.sh
pi ALL=(ALL) NOPASSWD: /usr/local/bin/switch-to-ap-mode.sh
pi ALL=(ALL) NOPASSWD: /usr/local/bin/wifi-connection-monitor.sh
pi ALL=(ALL) NOPASSWD: /usr/local/bin/wifi-reconnect-on-boot.sh
EOF

# Set correct permissions
sudo chmod 0440 /etc/sudoers.d/raspi-captive-portal

# Verify it's valid
sudo visudo -c -f /etc/sudoers.d/raspi-captive-portal

# Test it
sudo /usr/local/bin/switch-to-wifi-client.sh "TestSSID" "TestPass"
```

## View Enhanced Logs

The server now has enhanced logging. Check the logs after submitting the form:

```bash
# View all server logs
sudo journalctl -u access-point-server --no-pager

# View last 50 lines
sudo journalctl -u access-point-server -n 50

# Follow in real-time
sudo journalctl -u access-point-server -f

# Search for errors
sudo journalctl -u access-point-server | grep -i error
sudo journalctl -u access-point-server | grep -i "WiFi Connection"
```

## Expected Log Output

When the switch is working correctly, you should see:

```
=== WiFi Connection Request ===
SSID: YourNetworkName
Command: sudo /usr/local/bin/switch-to-wifi-client.sh 'YourNetworkName' '****'
Executing WiFi connection script...
=== Script Output ===
STDOUT: Switching from AP mode to WiFi client mode...
Connecting to network: YourNetworkName
...
=== End Script Output ===
```

## Still Not Working?

If none of the above solutions work:

1. **Reinstall everything:**
   ```bash
   cd /path/to/raspi-captive-portal
   sudo python setup.py
   ```

2. **Check for conflicting services:**
   ```bash
   systemctl list-units --type=service | grep -i wifi
   systemctl list-units --type=service | grep -i network
   ```

3. **Reboot the Raspberry Pi:**
   ```bash
   sudo reboot
   ```

4. **Check the logs after reboot:**
   ```bash
   sudo journalctl -b -u access-point-server
   ```

5. **Create an issue on GitHub** with:
   - Output of all diagnostic commands above
   - Server logs
   - Browser console errors
   - Description of what happens when you submit the form
