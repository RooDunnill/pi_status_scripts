#!/bin/bash
LOGFILE = "/tmp/boot_status.log"
HOST=$(hostname)
IP=$(hostname -I | awk '{print $1}')
echo "Hostname: $HOST and IP: $IP" >> "$LOGFILE"
PORT=$(grep '^Port ' /etc/ssh/sshd_config | awk '{print $2}')
echo "Obtained Port: $PORT" >> "LOGFILE"
PORT=${PORT:-22}  # fallbacks to 22 if Port not found
WEBHOOK=$(cat ~/.config/discord_webhooks/pi)
echo "Webhook: $WEBHOOK" >> "$LOGFILE"

curl -s -H "Content-Type: application/json" \
     -X POST \
     -d "{\"username\": \"$HOST\", \"content\": \"IP: $IP, SSH Port: $PORT\"}" \
     "$WEBHOOK"
