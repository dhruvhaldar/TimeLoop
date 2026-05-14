#!/bin/bash

# Ensure the script stops on errors
set -e

echo "Starting Chrome Remote Desktop XFCE fix..."

# 1. Create the session file to launch XFCE correctly without conflicts
SESSION_FILE="$HOME/.chrome-remote-desktop-session"
echo "Creating session file at $SESSION_FILE..."
cat << 'EOF' > "$SESSION_FILE"
unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER
exec /usr/bin/startxfce4
EOF

# Ensure it is executable
chmod +x "$SESSION_FILE"

# 2. Force Chrome Remote Desktop to use Xvfb instead of the Xorg dummy driver
# This fixes the "unable to open display :20" crash loops
SERVICE_OVERRIDE_DIR="/etc/systemd/system/chrome-remote-desktop@${USER}.service.d"
OVERRIDE_FILE="$SERVICE_OVERRIDE_DIR/override.conf"

echo "Configuring systemd to force Xvfb for user $USER..."
sudo mkdir -p "$SERVICE_OVERRIDE_DIR"
echo -e "[Service]\nEnvironment=CHROME_REMOTE_DESKTOP_USE_XVFB=1" | sudo tee "$OVERRIDE_FILE" > /dev/null

# 3. Reload systemd and restart the service to apply everything
echo "Reloading systemd and restarting the Chrome Remote Desktop service..."
sudo systemctl daemon-reload
sudo systemctl restart "chrome-remote-desktop@${USER}.service"

echo "Fix applied successfully! The service should now be online."
