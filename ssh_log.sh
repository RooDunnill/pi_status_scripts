#!/bin/bash
LOGFILE="/tmp/ssh_alert_debug_$(whoami).log"
if [ -e "$LOGFILE" ] && [ ! -w "$LOGFILE" ]; then
  rm -f "$LOGFILE"
fi
exec 2>>"$LOGFILE"
echo -e "\n--- ENV @ $(date) ---" >> "$LOGFILE"
env >> "$LOGFILE"

echo "SSH alert script ran at $(date)" >> "$LOGFILE"
if [ -n "$SSH_CONNECTION" ]; then
  echo "registered SSH connection!" >> "$LOGFILE"
  HOSTNAME=$(hostname)
  CLIENT_IP=$(echo "$SSH_CONNECTION" | awk '{print $1}')      #finds the computers ip
  SERVER_IP=$(echo "$SSH_CONNECTION" | awk '{print $3}')      #finds the pis ip
  SERVER_PORT=$(echo "$SSH_CONNECTION" | awk '{print $4}')    #finds the ssh port, normally 22
  USER=$(whoami)
  TIME=$(date '+%Y-%m-%d %H:%M:%S')
  HOUR=$(date +%H)
  RAND=$RANDOM
  WEBHOOK_FILE="$HOME/.config/discord_webhooks/pi"        #finds the webhook for discord

  echo "Reading webhook file: $WEBHOOK_FILE" >> "$LOGFILE"

  if [ ! -f "$WEBHOOK_FILE" ]; then
    echo "Webhook file not found" >> "$LOGFILE"
    exit 0
  fi

  WEBHOOK_URL=$(cat "$WEBHOOK_FILE")                 
  echo "Webhook url: $WEBHOOK_URL" >> "$LOGFILE"

  if [ "$HOUR" -ge 5 ] && [ "$HOUR" -lt 12 ]; then
    GREETING="Uh Oh, incoming call from the boss!"
  elif [ "$HOUR" -ge 12 ] && [ "$HOUR" -lt 18 ]; then
    GREETING="Interrupting my afternoon tea smh"
  elif [ "$HOUR" -ge 18 ]; then
    GREETING="Evening! What can I help ya with"
  else
    GREETING="Im tryna sleep, go awayyyyy"
  fi
#the message over multiple lines
  MESSAGE="---SSH request detected---
$TIME
$GREETING
SSHing from: $CLIENT_IP
SSHing into: $SERVER_IP
Port: $SERVER_PORT
"

  #packages the message up correctly so json doesnt go apeshit
  MESSAGE_ESCAPED=$(echo "$MESSAGE" | sed ':a;N;$!ba;s/\n/\\n/g')
  echo "Escaped message: $MESSAGE_ESCAPED" >> "$LOGFILE"

  echo "Sending message..." >> "$LOGFILE"

  curl -s -H "Content-Type: application/json" \
       -X POST \
       -d "{\"username\": \"$HOSTNAME\", \"content\": \"$MESSAGE_ESCAPED\"}" \
       "$WEBHOOK_URL" >> "$LOGFILE" 2>&1

  echo "Curl finished at $(date)" >> "$LOGFILE"                  
else
  echo "No SSH connection detected" >> "$LOGFILE"
fi
