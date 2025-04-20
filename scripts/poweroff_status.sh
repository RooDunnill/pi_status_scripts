#!/bin/bash

LOGFILE="/tmp/poweroff_status_$(whoami).log"
HOST=$(hostname)
TIME=$(date '+%Y-%m-%d %H:%M:%S')
WEBHOOK_FILE="$HOME/.config/discord_webhooks/pi"

if [ ! -f "$WEBHOOK_FILE" ]; then
  echo "Webhook file not found at $WEBHOOK_FILE" >> "$LOGFILE"
  exit 1
fi

WEBHOOK=$(cat "$WEBHOOK_FILE")                  #gets url from the file

# Detect if a user is logged in and shutting down
ACTIVE_USER=$(who | awk '{print $1}' | sort | uniq | tr '\n' ',' | sed 's/,$//')
SSH_SESSIONS=$(who | grep -c 'pts')             #finds the number of people sshed in
TTY_SESSIONS=$(who | grep -c 'tty')             #finds the number of physical terminal users

if [ "$SSH_SESSIONS" -gt 0 ]; then              #a crude way to find the shutdown reason
  REASON="Shutdown initiated via SSH session by: $ACTIVE_USER"
elif [ "$TTY_SESSIONS" -gt 0 ]; then
  REASON="Shutdown initiated from physical console by: $ACTIVE_USER"
else
  REASON="Shutdown was caused due to an unknown reason"
fi

MESSAGE="---Powering off---\n$TIME\n$HOST is shutting down.\n$REASON"

curl -s -H "Content-Type: application/json" \
     -X POST \
     -d "{\"username\": \"$HOST\", \"content\": \"$MESSAGE\"}" \
     "$WEBHOOK"
