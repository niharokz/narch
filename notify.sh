#!/bin/zsh
 
#
#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nih.ar] ON 28-05-2026
#       SOURCE [notify.sh] LAST MODIFIED ON 28-05-2026
#

set -euo pipefail

source "$HOME/.config/.secrets"

MESSAGE="${1:-No message provided}"

curl -fsS -X POST  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${TELEGRAM_CHAT_ID}" --data-urlencode "text=${MESSAGE}"  > /dev/null

echo "Notification sent"
