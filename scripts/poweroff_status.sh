#!/bin/bash
echo "Shutdown in process"
echo "Shutdown debug test $(date)" >> /home/$(whoami)/poweroff_test.log
LOG="/home/$(whoami)/poweroff_test.log"
echo "Started at $(date)" >> "$LOG"
ping -c 1 8.8.8.8 &>> "$LOG"
echo "Finished at $(date)" >> "$LOG"

LOGFILE="$HOME/poweroff_status_$(whoami).log"
echo "Script started by systemd at $(date)" >> "$LOGFILE"
HOST=$(hostname)
echo "Host name is: $HOST" >> "$LOGFILE"
TIME=$(date '+%Y-%m-%d %H:%M:%S')
WEBHOOK_FILE="$HOME/.config/discord_webhooks/pi"

if [ ! -f "$WEBHOOK_FILE" ]; then
  echo "Webhook file not found at $WEBHOOK_FILE" >> "$LOGFILE"
  exit 1
fi

WEBHOOK=$(cat "$WEBHOOK_FILE")                  #gets url from the file
echo "Webhook url is: $WEBHOOK" >> "$LOGFILE"
# Detect if a user is logged in and shutting down
ACTIVE_USER=$(who | awk '{print $1}' | sort | uniq | tr '\n' ',' | sed 's/,$//')
SSH_SESSIONS=$(who | grep -c 'pts')             #finds the number of people sshed in
TTY_SESSIONS=$(who | grep -c 'tty')             #finds the number of physical terminal users

if [ "$SSH_SESSIONS" -gt 0 ]; then              #a crude way to find the shutdown reason
  echo "Shutdown initiated by SSH" >> "$LOGFILE"
  REASON="Shutdown initiated via SSH session by: $ACTIVE_USER"
elif [ "$TTY_SESSIONS" -gt 0 ]; then
  echo "Shutdown initiated by physical console" >> "$LOGFILE"
  REASON="Shutdown initiated from physical console by: $ACTIVE_USER"
else
  echo "Shutdown initiated by an unknown process" >> "$LOGFILE"
  REASON="Shutdown was caused due to an unknown reason"
fi

ESCAPED_MESSAGE="---Powering off---\n$TIME\n$HOST is shutting down.\n$REASON"
MESSAGE=$(echo "$ESCAPED_MESSAGE" | sed ':a;N;$!ba;s/\n/\\n/g')

echo "Sending message over discord" >> "$LOGFILE"

echo "Sending message over discord"

RESPONSE=$(/usr/bin/curl -s -o /dev/null -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "{\"username\": \"$HOST\", \"content\": \"$MESSAGE\"}" \
  "$WEBHOOK")

if [ "$RESPONSE" = "204" ]; then
  echo "Discord message sent successfully"
else
  echo "Discord message failed with HTTP code: $RESPONSE"
fi
echo "Sleeping before exit..." >> "$LOGFILE"
sleep 5
echo "Script finished at $(date)" >> "$LOGFILE"

echo "Script finished"

sleep 3
echo "Script finished" >> "$LOGFILE"
