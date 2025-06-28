#!/bin/bash

#
#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nih.ar] ON 05-09-2024.
#       SOURCE [dual_monitor.sh] LAST MODIFIED ON 05-09-2024.
#


# Detect connected monitors
connected_monitors=$(xrandr --listmonitors | grep Monitors | awk '{print $2}')

# Check if there are more than one monitor
if [ "$connected_monitors" -gt 1 ]; then
    xrandr --output DP1 --mode 2560x1440
    xrandr --output eDP1 --auto --right-of DP1
else
    echo "Only one monitor detected"
fi
