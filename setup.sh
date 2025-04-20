#!/bin/bash

set -e

USER_NAME=$(whoami)
USER_HOME=$(eval echo "~$USER_NAME")

echo "Running installation process..."

#===boot_status.service setup===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_NAME="boot_status.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
TEMPLATE_PATH="$SCRIPT_DIR/services/$SERVICE_NAME"
TEMP_FILE="/tmp/$SERVICE_NAME"


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

chmod +x "$USER_HOME/pi_status_scripts/scripts/boot_status.sh"      #makes the boot script an exe

sudo systemctl daemon-reexec                  #enables/resets daemon
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"

sudo systemctl enable "$SERVICE_NAME"
echo "$SERVICE_NAME enabled. Will run on next boot."

echo "Service installed, enabled, and executed."
echo "Use: sudo systemctl status $SERVICE_NAME to check logs."


#===poweroff_status.service setup===
PO_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PO_SERVICE_NAME="poweroff_status.service"
PO_SERVICE_PATH="/etc/systemd/system/$PO_SERVICE_NAME"
PO_TEMPLATE_PATH="$SCRIPT_DIR/services/$PO_SERVICE_NAME"
PO_TEMP_FILE="/tmp/$PO_SERVICE_NAME"

echo "Installing or reinstalling $PO_SERVICE_NAME for user '$USER_NAME'..."

#Check the service template exists
if [ ! -f "$PO_TEMPLATE_PATH" ]; then
    echo "ERROR: Service template '$PO_TEMPLATE_PATH' not found!"
    exit 1
fi

                                          #edits the poweroff_statues.service file to reflect the users username
sed -e "s|__USER__|$USER_NAME|g" \
    -e "s|__HOME__|$USER_HOME|g" \
    "$PO_TEMPLATE_PATH" > "$PO_TEMP_FILE"


if [ -f "$PO_SERVICE_PATH" ]; then                         #removes old files when ran after the inital ./setup.sh
    echo "Removing existing systemd service..."
    sudo systemctl disable "$PO_SERVICE_NAME" || true
    sudo rm "$PO_SERVICE_PATH"
fi

sudo mv "$PO_TEMP_FILE" "$PO_SERVICE_PATH"      #moves the new edited file over to the system folder

chmod +x "$USER_HOME/pi_status_scripts/scripts/poweroff_status.sh"      #makes the poweroff script an exe

sudo systemctl daemon-reexec                  #enables/resets daemon
sudo systemctl daemon-reload
sudo systemctl enable "$PO_SERVICE_NAME"

sudo systemctl enable "$PO_SERVICE_NAME"
echo "$PO_SERVICE_NAME enabled. Will run on shutdown or reboot."


echo "Service installed, enabled, and executed."
echo "Use: sudo systemctl status $PO_SERVICE_NAME to check logs."


#===SSH login wrapper setup===
WRAPPER_SRC="$SCRIPT_DIR/wrappers/ssh_log_wrapper.sh"
WRAPPER_DEST="/etc/profile.d/ssh_log_wrapper.sh"

echo "Installing SSH login wrapper..."

if [ ! -f "$WRAPPER_SRC" ]; then
    echo "ERROR: Wrapper file '$WRAPPER_SRC' not found!"
    exit 1
fi

if cmp -s "$WRAPPER_SRC" "$WRAPPER_DEST"; then
    echo "SSH login wrapper already up to date."
else
    echo "Updating SSH login wrapper at $WRAPPER_DEST"
    cp "$WRAPPER_SRC" "$WRAPPER_DEST"
    chmod +x "$WRAPPER_DEST"
fi

echo "SSH login wrapper installed to $WRAPPER_DEST"

#===SSH logout wrapper setup===
LOGOUT_WRAPPER_SRC="$SCRIPT_DIR/wrappers/ssh_logout_wrapper.sh"
LOGOUT_WRAPPER_DEST="$USER_HOME/.bash_logout"

echo "Installing SSH logout wrapper..."

if [ ! -f "$LOGOUT_WRAPPER_SRC" ]; then
    echo "ERROR: Logout wrapper '$LOGOUT_WRAPPER_SRC' not found!"
    exit 1
fi

if cmp -s "$LOGOUT_WRAPPER_SRC" "$LOGOUT_WRAPPER_DEST"; then
    echo "SSH logout wrapper already up to date."
else
    echo "Updating SSH logout wrapper at $LOGOUT_WRAPPER_DEST"
    cp "$LOGOUT_WRAPPER_SRC" "$LOGOUT_WRAPPER_DEST"
    chmod +x "$LOGOUT_WRAPPER_DEST"
fi
echo "SSH logout wrapper installed to $LOGOUT_WRAPPER_DEST"

echo "Installation process finished!"
