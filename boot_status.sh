#!/bin/bash
LOGFILE="/tmp/boot_status_$(whoami).log"
USER=$(whoami)
HOST=$(hostname)
IP=$(hostname -I | awk '{print $1}')
echo "Hostname: $HOST and IP: $IP" >> "$LOGFILE"
PORT=$(grep '^Port ' /etc/ssh/sshd_config | awk '{print $2}')
echo "Obtained Port: $PORT" >> "LOGFILE"
PORT=${PORT:-22}  # fallbacks to 22 if Port not found
TIME=$(date '+%Y-%m-%d %H:%M:%S')
HOUR=$(date +%H)
WEBHOOK=$(cat ~/.config/discord_webhooks/pi)
WIFI_SSID=$(iwgetid -r)
SSH_STATUS=$(systemctl is-active ssh)

echo "Webhook: $WEBHOOK" >> "$LOGFILE"
if [ "$HOUR" -ge 5 ] && [ "$HOUR" -lt 12 ]; then
  GREETING="Morninggggggg!"
elif [ "$HOUR" -ge 12 ] && [ "$HOUR" -lt 18 ]; then
  GREETING="Afternoon, hows the work going?"
elif [ "$HOUR" -ge 18 ] && [ "$HOUR" -lt 24 ]; then
  GREETING="Nice and chill in the evening!"
else
  GREETING="Damn its late, go to sleep!"
fi
MESSAGE="---Waking up!---\n[$TIME]\n$GREETING\n$USER@$HOST waking up!\nMy IP is $IP and my SSH Port is: $PORT\nMy WIFI is $WIFI_SSID and my SSH status is $SSH_STATUS"
curl -s -H "Content-Type: application/json" \
     -X POST \
     -d "{\"username\": \"$HOST\", \"content\": \"$MESSAGE\"}" \
     "$WEBHOOK"
