#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_NAME="boot_status.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
TEMPLATE_PATH="$SCRIPT_DIR/$SERVICE_NAME"
TEMP_FILE="/tmp/$SERVICE_NAME"

USER_NAME=$(whoami)                                                        #find the username
USER_HOME=$(eval echo "~$USER_NAME")                           

echo "Installing or reinstalling $SERVICE_NAME for user '$USER_NAME'..."

#Check the service template exists
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "ERROR: Service template '$TEMPLATE_PATH' not found!"
    exit 1
fi

                                          #edits the boot_statues.service file to reflect the users username
sed -e "s|__USER__|$USER_NAME|g" \
    -e "s|__HOME__|$USER_HOME|g" \
    "$TEMPLATE_PATH" > "$TEMP_FILE"


if [ -f "$SERVICE_PATH" ]; then                         #removes old files when ran after the inital ./setup.sh
    echo "Removing existing systemd service..."
    sudo systemctl disable "$SERVICE_NAME" || true
    sudo rm "$SERVICE_PATH"
fi

sudo mv "$TEMP_FILE" "$SERVICE_PATH"      #moves the new edited file over to the system folder

chmod +x "$USER_HOME/scripts/pi_status_scripts/boot_status.sh"      #makes the boot script an exe

sudo systemctl daemon-reexec                  #enables/resets daemon
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"

echo "Restarting service for immediate test..."    #restarts the .service file
sudo systemctl restart "$SERVICE_NAME"

echo "Service installed, enabled, and executed."
echo "Use: sudo systemctl status $SERVICE_NAME to check logs."
