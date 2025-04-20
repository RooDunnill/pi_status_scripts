#!/bin/bash
# Only run on SSH sessions
if [ -n "$SSH_CONNECTION" ]; then
    [ -x "$HOME/pi_status_scripts/scripts/ssh_log.sh" ] && "$HOME/pi_status_scripts/scripts/ssh_log.sh"
fi
