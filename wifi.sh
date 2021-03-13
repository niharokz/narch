#!/bin/bash

#
#       ███╗░░██╗██╗██╗░░██╗░█████╗░██████╗░░█████╗░██╗░░██╗███████╗
#       ████╗░██║██║██║░░██║██╔══██╗██╔══██╗██╔══██╗██║░██╔╝╚════██║
#       ██╔██╗██║██║███████║███████║██████╔╝██║░░██║█████═╝░░░███╔═╝
#       ██║╚████║██║██╔══██║██╔══██║██╔══██╗██║░░██║██╔═██╗░██╔══╝░░
#       ██║░╚███║██║██║░░██║██║░░██║██║░░██║╚█████╔╝██║░╚██╗███████╗
#       ╚═╝░░╚══╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚══════╝
#
#       DRAFTED BY NIHAR SAMANTARAY ON 13-03-21. [https://nihars.com]
#       SOURCE [wifi.sh] LAST MODIFIED ON 13-03-21

nmcli device wifi list
echo WIFI NAME
read wifi_name
echo WIFI password
read wifi_pass
nmcli device wifi connect $wifi_name password $wifi_pass 
