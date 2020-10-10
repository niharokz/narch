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

dwm_alsa () {
    VOL=$(amixer get Master | tail -n1 | sed -r "s/.*\[(.*)%\].*/\1/")
    if [ "$IDENTIFIER" = "unicode" ]; then
        if [ "$VOL" -eq 0 ]; then
            printf "🔇"
        elif [ "$VOL" -gt 0 ] && [ "$VOL" -le 33 ]; then
            printf "🔈 %s%%$VOL"
        elif [ "$VOL" -gt 33 ] && [ "$VOL" -le 66 ]; then
            printf "🔉 %s%%$VOL"
        else
            printf "🔊 %s%%$VOL"
        fi
    else
        if [ "$VOL" -eq 0 ]; then
            printf "MUTE"
        elif [ "$VOL" -gt 0 ] && [ "$VOL" -le 33 ]; then
            printf "VOL %s%%$VOL"
        elif [ "$VOL" -gt 33 ] && [ "$VOL" -le 66 ]; then
            printf "VOL %s%%$VOL"
        else
            printf "VOL %s%%$VOL"
        fi
    fi
    printf "%s $SEP2 "
}

while true
do
    xsetroot -name "$(dwm_resources)$(dwm_battery)$(dwm_alsa)$(dwm_networkmanager)$(dwm_date)"
    sleep 1
done
