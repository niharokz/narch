#!/bin/sh

export SEP2="|"

dwm_battery () {
    CHARGE=$(cat /sys/class/power_supply/BAT1/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT1/status)
    if [ "$CHARGE" -le 20 ] && [ "$STATUS" = "Discharging" ]; then
	    notify-send "Battery Remaining 20%"
    fi
}

dwm_networkmanager () {
    CONNAME=$(nmcli -a | grep 'Wired connection' | awk 'NR==1{print $1}')
    if [ "$CONNAME" = "" ]; then
        CONNAME=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -c 5-)
    fi

    echo "WIFI : %s$CONNAME"
    echo "%s $SEP2 "
}

while true
do
    $(dwm_battery)
    sleep 1
done
