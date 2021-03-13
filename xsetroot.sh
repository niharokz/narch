#!/bin/sh

export SEP2="|"

dwm_battery () {
    # Change BAT1 to whatever your battery is identified as. Typically BAT0 or BAT1
    CHARGE=$(cat /sys/class/power_supply/BAT1/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT1/status)
    printf "BAT : %s $CHARGE" 
    printf "%s $SEP2 "
}

dwm_date () {
    if [ "$IDENTIFIER" = "unicode" ]; then
        printf "📆 %s$(date "+%a %d-%m-%y %T")"
    else
        printf "DATE : %s$(date "+%a %d-%m-%y %T")"
    fi
    printf "%s"
}

dwm_resources () {
    # Used and total memory
    MEMUSED=$(free -h | awk '(NR == 2) {print $3}')
    MEMTOT=$(free -h |awk '(NR == 2) {print $2}')
    # CPU temperature
    # Used and total storage in /home (rounded to 1024B)
    STOUSED=$(df -h | grep '/home$' | awk '{print $3}')
    STOTOT=$(df -h | grep '/home$' | awk '{print $2}')
    STOPER=$(df -h | grep '/home$' | awk '{print $5}')

    if [ "$IDENTIFIER" = "unicode" ]; then
        printf " RAM %s $MEMUSED" 
    else
        printf " RAM : %s $MEMUSED"
    fi
    printf "%s $SEP2 "
}

dwm_networkmanager () {
    CONNAME=$(nmcli -a | grep 'Wired connection' | awk 'NR==1{print $1}')
    if [ "$CONNAME" = "" ]; then
        CONNAME=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -c 5-)
    fi

    printf "WIFI : %s$CONNAME"
    printf "%s $SEP2 "
}

dwm_vol () {
    VOL=$(pamixer --get-volume)
    printf "VOL : %s $VOL"
    printf "%s $SEP2 "
}

while true
do
    CHARGE=$(cat /sys/class/power_supply/BAT1/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT1/status)
	XSETROOT_VALUE="$(dwm_resources)$(dwm_battery)$(dwm_vol)$(dwm_networkmanager)$(dwm_date)"
	
	if [ "$STATUS" == "Discharging" ] && [ "$CHARGE" -le 10 ]
	then
		xsetroot -solid red -name "$XSETROOT_VALUE"
		if [ "$CHARGE" -le 5 ]
		then
			xsetroot -solid white -name "Battery below 5. Connect to charger"
			sleep 5
			xsetroot -solid white -name "Backing up Dropbox files"
			rclone sync $DATA/cloud/dropbox dropbox: 
			sleep 5
			xsetroot -solid white -name "Dropbox backed up"
			sleep 5
			xsetroot -solid red -name "Shutting down in a minute"
			sleep 30
			poweroff
		fi
	else
		xsetroot -solid black -name "$XSETROOT_VALUE"
	fi
    sleep 1
done
