#
#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nih.ar] ON 31-05-2025
#       SOURCE [powermenu.sh] LAST MODIFIED ON 01-06-2025
#

#!/bin/bash

# Ensure we’re in an X session

# Set DISPLAY if unset
[ -z "$DISPLAY" ] && export DISPLAY=:0

# dmenu wrapper function
run_dmenu() {
  dmenu -i -h 32 -fn 'FiraCode Nerd Font:size=12' -nb '#0f2f2f' -nf '#dcdccc' -sb '#42938C' -sf '#0f2f2f' "$@"
}

# Use dmenu to ask for action
choice=$(printf "Shutdown\nReboot\nCancel" | run_dmenu -p "Power Options:")

case "$choice" in
  Shutdown)
    echo "Shutdown in 10 seconds..." | run_dmenu -p "Info:"
    sleep 10 && systemctl poweroff
    ;;
  Reboot)
    echo "Rebooting in 10 seconds..." | run_dmenu -p "Info:"
    sleep 10 && systemctl reboot
    ;;
  Cancel|*)
    echo "Action canceled." | run_dmenu -p "Info:"
    ;;
esac
