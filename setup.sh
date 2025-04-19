#!/bin/bash

set -e

SERVICE_NAME="boot_status.service"
INSTALL_PATH="/etc/systemd/system/$SERVICE_NAME"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing $SERVICE_NAME..."

# Replace placeholder username with actual home path
sed "s|/home/YOUR_USERNAME|$HOME|g" "$SCRIPT_DIR/$SERVICE_NAME" | sudo tee "$INSTALL_PATH" > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"

echo "Service installed and enabled."
