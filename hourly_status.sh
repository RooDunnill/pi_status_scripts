#!/bin/bash
LOGFILE="/tmp/main_status.log"

WEBHOOK_FILE="$HOME/.config/discord_webhooks/pi"
[ ! -f "$WEBHOOK_FILE" ] && { echo "Webhook file missing"; exit 1; }
WEBHOOK=$(<"$WEBHOOK_FILE")
HOST=$(hostname)
IP=$(hostname -I | awk '{print $1}')         #finds the ip address
[ -z "$IP" ] && IP="unknown"
TITLE="Status: $HOST ($IP)"
UPTIME_MIN=$(( $(awk '{print int($1)}' /proc/uptime) / 60 ))

# CPU usage
read -r _ u n s i _ < /proc/stat; sleep 1
read -r _ u2 n2 s2 i2 _ < /proc/stat          #finds the cpu use
CPU=$(awk "BEGIN { print 100 * ($u2 + $n2 + $s2 - $u - $n - $s) / ($u2 + $n2 + $s2 + $i2 - $u - $n - $s - $i) }")

# RAM usage
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
mem_used=$((mem_total - mem_avail))
MEM=$(awk "BEGIN { printf \"%.1f\", 100 * $mem_used / $mem_total }")          #finds the RAM percentage use

# Temp (in °C)
TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)                 #finds cpu temp
TEMP=$(awk "BEGIN { printf \"%.1f\", $TEMP_RAW / 1000 }")

# Wi-Fi link speed
WIFI=$(iw dev wlan0 link | awk '/tx bitrate/ {print $3 " " $4}')               #finds the wifi speed, often doesnt work so need to fix
[ -z "$WIFI" ] && WIFI="N/A"

# Power (VCG commands)
VOLTAGE=$(vcgencmd measure_volts core 2>/dev/null | cut -d= -f2 || echo "N/A")    #finds the voltage draw
CURRENT=$(vcgencmd measure_current 2>/dev/null | cut -d= -f2 || echo "N/A")       #doesnt work

# SSH and Tailscale
SSH=$(systemctl is-active ssh 2>/dev/null)                        #finds the ssh status
TS=$(command -v tailscale &>/dev/null && tailscale status | head -n1 || echo "not installed")




#Thresholds for messages

#light thresholds
LIGHT_CPU=50
LIGHT_RAM=50
LIGHT_TEMP=40
LIGHT_UPTIME=60

#medium thresholds
MED_CPU=70
MED_RAM=70
MED_TEMP=50
MED_UPTIME=360

#serious thresholds
SER_CPU=90
SER_RAM=90
SER_TEMP=65
SER_UPTIME=600

if awk "BEGIN {exit !($CPU >= $SER_CPU)}"; then           #custom fun messages based on the intensity of that variable
  CPU_MSG="Okie lads, we gotta seriously back off the gas here"    #all serious warnings contain the word serious in it
elif awk "BEGIN {exit !($CPU >= $MED_CPU)}"; then
  CPU_MSG="Damn this processor is really going through it"
elif awk "BEGIN {exit !($CPU >= $LIGHT_CPU)}"; then
  CPU_MSG="My processor is vibin rn"
else
  CPU_MSG="Boredddddd"
fi

if awk "BEGIN {exit !($MEM >= $SER_RAM)}"; then
  RAM_MSG="Seriously, the RAM is about to go awol"
elif awk "BEGIN {exit !($MEM >= $MED_RAM)}"; then
  RAM_MSG="RAM is getting in a good workout here"
elif awk "BEGIN {exit !($MEM >= $LIGHT_RAM)}"; then
  RAM_MSG="That memory is barely breaking a sweat icl"
else
  RAM_MSG="Come on! Give me something to do"
fi


if awk "BEGIN {exit !($TEMP >= $SER_TEMP)}"; then
  TEMP_MSG="Dude seriously need to turn the thermo down"
elif awk "BEGIN {exit !($TEMP >= $MED_TEMP)}"; then
  TEMP_MSG="Getting a nice tan rn"
elif awk "BEGIN {exit !($TEMP >= $LIGHT_TEMP)}"; then
  TEMP_MSG="Bit nippy init"
else
  TEMP_MSG="Bout to play a bit of hockey on the CPU in a minute it's that cold"
fi

# Uptime warnings
if [ "$UPTIME_MIN" -ge "$SER_UPTIME" ]; then
  UPTIME_MSG="Seriously need to sleep soon fr"
elif [ "$UPTIME_MIN" -ge "$MED_UPTIME" ]; then
  UPTIME_MSG="Another hard days work, whens a nap?"
elif [ "$UPTIME_MIN" -ge "$LIGHT_UPTIME" ]; then
  UPTIME_MSG="Nice and warmup up :)"
else
  UPTIME_MSG="Im ready to gooooo"
fi


MESSAGE=$(cat <<EOF
---Status Report Coming Through---
$CPU_MSG
$RAM_MSG
$TEMP_MSG
$UPTIME_MSG
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
echo "Webhook path: $WEBHOOK" >> "$LOGFILE"
curl -s -H "Content-Type: application/json" \
  -X POST \
  -d "{\"username\": \"$TITLE\", \"content\": \"$MESSAGE_ESCAPED\"}" \
  "$WEBHOOK"

