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
  CLIENT_IP=$(echo $SSH_CONNECTION | awk '{print $1}')
  SERVER_IP=$(echo "$SSH_CONNECTION" | awk '{print $3}')
  SERVER_PORT=$(echo "$SSH_CONNECTION" | awk '{print $4}')
  USER=$(whoami)
  TIME=$(date '+%Y-%m-%d %H:%M:%S')
  HOUR=$(date +%H)
  RAND=$RANDOM
  WEBHOOK_FILE="$HOME/.config/discord_webhooks/pi"

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

  MESSAGE="---SSH request detected---
$TIME
$GREETING
SSHing from: $CLIENT_IP
SSHing into: $SERVER_IP
Port: $SERVER_PORT
"

  # Escape newlines for JSON
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
