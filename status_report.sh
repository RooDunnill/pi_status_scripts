#!/bin/bash

WEBHOOK_FILE="$HOME/.config/discord_webhooks/pi"
[ ! -f "$WEBHOOK_FILE" ] && { echo "Webhook file missing"; exit 1; }
WEBHOOK=$(<"$WEBHOOK_FILE")

HOST=$(hostname)
IP=$(hostname -I | awk '{print $1}')
[ -z "$IP" ] && IP="unknown"
TITLE="Status: $HOST ($IP)"
UPTIME_MIN=$(( $(awk '{print int($1)}' /proc/uptime) / 60 ))

# CPU usage
read -r _ u n s i _ < /proc/stat; sleep 1
read -r _ u2 n2 s2 i2 _ < /proc/stat
CPU=$(awk "BEGIN { print 100 * ($u2 + $n2 + $s2 - $u - $n - $s) / ($u2 + $n2 + $s2 + $i2 - $u - $n - $s - $i) }")

# RAM usage
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
mem_used=$((mem_total - mem_avail))
MEM=$(awk "BEGIN { printf \"%.1f\", 100 * $mem_used / $mem_total }")

# Temp (in °C)
TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
TEMP=$(awk "BEGIN { printf \"%.1f\", $TEMP_RAW / 1000 }")

# Wi-Fi link speed
WIFI=$(iw dev wlan0 link | awk '/tx bitrate/ {print $3 " " $4}')
[ -z "$WIFI" ] && WIFI="N/A"

# Power (VCG commands)
VOLTAGE=$(vcgencmd measure_volts core 2>/dev/null | cut -d= -f2 || echo "N/A")
CURRENT=$(vcgencmd measure_current 2>/dev/null | cut -d= -f2 || echo "N/A")

# SSH and Tailscale
SSH=$(systemctl is-active ssh 2>/dev/null)
TS=$(command -v tailscale &>/dev/null && tailscale status | head -n1 || echo "not installed")

MESSAGE=$(cat <<EOF
CPU: ${CPU}%
RAM: ${MEM}%
Temp: ${TEMP}°C
Wi-Fi: ${WIFI}
Uptime: ${UPTIME_MIN} mins
IP: $IP
SSH: $SSH
Tailscale: $TS
Power: ${VOLTAGE}, ${CURRENT}
EOF
)

# Escape for JSON
MESSAGE_ESCAPED=$(echo "$MESSAGE" | sed ':a;N;$!ba;s/\n/\\n/g')

curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "{\"username\": \"$TITLE\", \"content\": \"$MESSAGE_ESCAPED\"}" \
  "$WEBHOOK"

