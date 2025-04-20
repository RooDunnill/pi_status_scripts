#!/bin/bash
echo -e "\nNetwork: $(iwgetid -r)"
echo -e "IP Address: $(hostname -I | awk '{print $1}')"
ping -c 1 1.1.1.1 &>/dev/null && echo "Internet: Reachable" || echo "Internet: No ping fml"
ping -c google.com &>/dev/null && echo "DNS: Reachable" || echo "DNS: down"
ping -c discord.com &>/dev/null && echo "Discord connection: Reachable" || echo "Discord: down"
