#!/bin/bash
LOGFILE="/tmp/boot_status_$(whoami).log"
USER=$(whoami)                       #gets username
HOST=$(hostname)                     #gets the host name
IP=$(hostname -I | awk '{print $1}') #finds ip address, the main one, usually starting with 10. if on eduroam
echo "Hostname: $HOST and IP: $IP" >> "$LOGFILE"
PORT=$(grep '^Port ' /etc/ssh/sshd_config | awk '{print $2}')
echo "Obtained Port: $PORT" >> "LOGFILE"
PORT=${PORT:-22}  # fallbacks to 22 if Port not found
TIME=$(date '+%Y-%m-%d %H:%M:%S')
HOUR=$(date +%H)                                         #finds the hours of the day for the custom messages
WEBHOOK=$(cat ~/.config/discord_webhooks/pi)             #gets the discord webhook
WIFI_SSID=$(iwgetid -r)                                  #finds which wifi the pi is connected to
SSH_STATUS=$(systemctl is-active ssh)                    #finds the status of the ssh

echo "Webhook: $WEBHOOK" >> "$LOGFILE"                   #custom silly messages depending on the hour of the day
if [ "$HOUR" -ge 5 ] && [ "$HOUR" -lt 12 ]; then
  GREETING="Morninggggggg!"
elif [ "$HOUR" -ge 12 ] && [ "$HOUR" -lt 18 ]; then
  GREETING="Afternoon, hows the work going?"
elif [ "$HOUR" -ge 18 ] && [ "$HOUR" -lt 24 ]; then
  GREETING="Nice and chill in the evening!"
else
  GREETING="Damn its late, go to sleep!"
fi                                 #the actual message which it then packages nicely and sends to discord via a webhook
MESSAGE="---Waking up!---\n[$TIME]\n$GREETING\n$USER@$HOST waking up!\nMy IP is $IP and my SSH Port is: $PORT\nMy WIFI is $WIFI_SSID and my SSH status is $SSH_STATUS"
curl -s -H "Content-Type: application/json" \
     -X POST \
     -d "{\"username\": \"$HOST\", \"content\": \"$MESSAGE\"}" \
     "$WEBHOOK"
