#!/bin/bash


if [ -n "$SSH_CONNECTION" ]; then
  HOSTNAME=$(hostname)
  CLIENT_IP=$(echo $SSH_CONNECTION | awk '{print $1}')
  SERVER_IP=$(hostname -I | awk '{print $1}')
  USERNAME=$(whoami)
  TIME=$(date '+%Y-%m-%d %H:%M:%S')
  WEBHOOK_FILE="$HOME/.config/discord_webhooks/pi"
  
  [ -f "$WEBHOOK_FILE" ] || exit 0
  WEBHOOK_URL=$(cat "$WEBHOOK_FILE")

  MESSAGE="[$HOSTNAME SSH ALERT]

User: $USERNAME
From: $CLIENT_IP
To: $SERVER_IP
Time: $TIME"

  curl -s -H "Content-Type: application/json" \
       -X POST \
       -d "{\"username\": \"$HOSTNAME\", \"content\": \"$MESSAGE\"}" \
       "$WEBHOOK_URL" > /dev/null
fi
