#!/bin/bash
LOGFILE="/tmp/ssh_alert_debug.log"
echo -e "\n--- ENV @ $(date) ---" >> "$LOGFILE"
env >> "$LOGFILE"

echo "SSH alert script ran at $(date)" >> "$LOGFILE"
if [ -n "$SSH_CONNECTION" ]; then
  echo "registered SSH connection!" >> "$LOGFILE"
  HOSTNAME=$(hostname)
  CLIENT_IP=$(echo $SSH_CONNECTION | awk '{print $1}')
  SERVER_IP=$(hostname -I | awk '{print $1}')
  USERNAME=$(whoami)
  TIME=$(date '+%Y-%m-%d %H:%M:%S')
  RAND=$RANDOM
  WEBHOOK_FILE="$HOME/.config/discord_webhooks/pi"
  
  echo "Reading webhook file: $WEBHOOK_FILE" >> "$LOGFILE"

  if [ ! -f "$WEBHOOK_FILE" ]; then
    echo "Webhook file not found" >> "$LOGFILE"
    exit 0
  fi
  [ -f "$WEBHOOK_FILE" ] || exit 0
  WEBHOOK_URL=$(cat "$WEBHOOK_FILE")
  echo "Webhook url: $WEBHOOK_URL" >> "$LOGFILE"
  MESSAGE="[$HOSTNAME SSH ALERT]

User: $USERNAME
From: $CLIENT_IP
To: $SERVER_IP
Time: $TIME
ID: $RAND"

  echo "Sending message..." >> "$LOGFILE"

  curl -s -H "Content-Type: application/json" \
       -X POST \
       -d "{\"username\": \"$HOSTNAME\", \"content\": \"$MESSAGE\"}" \
       "$WEBHOOK_URL" > /dev/null
  echo "Curl finished at $(date)" >> "$LOGFILE"
else
  echo "No SSH connection detected" >> "$LOGFILE"
fi
