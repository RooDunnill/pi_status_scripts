#!/bin/bash
LOGFILE="/tmp/ssh_logout_debug_$(whoami).log"
if [ -n "$SSH_CONNECTION" ]; then
  HOSTNAME=$(hostname)
  CLIENT_IP=$(echo "$SSH_CONNECTION" | awk '{print $1}')
  SERVER_IP=$(echo "$SSH_CONNECTION" | awk '{print $3}')
  SERVER_PORT=$(echo "$SSH_CONNECTION" | awk '{print $4}')
  TIME=$(date '+%Y-%m-%d %H:%M:%S')
  WEBHOOK_FILE="$HOME/.config/discord_webhooks/pi"

  if [ ! -f "$WEBHOOK_FILE" ]; then
    echo "Webhook file not found at $WEBHOOK_FILE"
    exit 1
  fi

  WEBHOOK=$(cat "$WEBHOOK_FILE")
  MESSAGE="---SSH logout---\\n$TIME\\nDisconnected from: $CLIENT_IP\\nPi IP: $SERVER_IP, with port: $SERVER_PORT"

  /usr/bin/curl -s -H "Content-Type: application/json" \
       -X POST \
       -d "{\"username\": \"$HOSTNAME\", \"content\": \"$MESSAGE\"}" \
  "$WEBHOOK"
fi
