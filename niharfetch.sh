#!/bin/bash
 
#
#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nih.ar] ON 23-03-2026
#       SOURCE [niharfetch.sh] LAST MODIFIED ON 23-03-2026
#

# Define the NIXAR ASCII art
NIXAR_ART=$(cat << "EOF"
      ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
      ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
      ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
      ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
      ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
      ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
EOF
)

# Get current date and time in the desired format
CURRENT_DATETIME=$(date "+%A %d %m %Y %I:%M:%S %p %Z")

# Get system info using neofetch (in a way we can parse)
SYS_INFO=$(neofetch --stdout)

# Get user and host information properly
USERNAME=$(whoami)
HOSTNAME=$(hostname)
USER_HOST="$USERNAME@$HOSTNAME"

# Extract specific information
OS_INFO=$(echo "$SYS_INFO" | grep -E "OS:" | sed 's/OS: //')
KERNEL_INFO=$(echo "$SYS_INFO" | grep -E "Kernel:" | sed 's/Kernel: //')
UPTIME_INFO=$(echo "$SYS_INFO" | grep -E "Uptime:" | sed 's/Uptime: //')
PKGS_INFO=$(echo "$SYS_INFO" | grep -E "Packages:" | sed 's/Packages: //')
SHELL_INFO=$(echo "$SYS_INFO" | grep -E "Shell:" | sed 's/Shell: //')
TERM_INFO=$(echo "$SYS_INFO" | grep -E "Terminal:" | sed 's/Terminal: //')
CPU_INFO=$(echo "$SYS_INFO" | grep -E "CPU:" | sed 's/CPU: //')
GPU_INFO=$(echo "$SYS_INFO" | grep -E "GPU:" | sed 's/GPU: //')
MEMORY_INFO=$(echo "$SYS_INFO" | grep -E "Memory:" | sed 's/Memory: //')

# Get disk space information
DISK_INFO=$(df -h / | awk 'NR==2 {print $3"B/"$2"B ("$5")"}')

# Get additional package counts
FLATPAK_PKGS=$(flatpak list 2>/dev/null | wc -l || echo "0")
PIP_PKGS=$(pip list --format=freeze 2>/dev/null | wc -l || echo "0")
CARGO_PKGS=$(cargo install --list 2>/dev/null | grep -v '^ ' | wc -l || echo "0")

# Check for system updates
if command -v apt &> /dev/null; then
    UPDATES=$(apt list --upgradable 2>/dev/null | wc -l)
    if [ "$UPDATES" -gt 1 ]; then
        UPDATE_INFO="$((UPDATES-1)) packages available"
    else
        UPDATE_INFO="System is up to date"
    fi
elif command -v dnf &> /dev/null; then
    UPDATES=$(dnf list updates -q 2>/dev/null | wc -l)
    if [ "$UPDATES" -gt 0 ]; then
        UPDATE_INFO="$UPDATES packages available"
    else
        UPDATE_INFO="System is up to date"
    fi
else
    UPDATE_INFO="Update check not supported"
fi

# Get random quote from quotes file
if [ -f "$QUOTES_FILE" ]; then
    # Count number of non-empty lines
    TOTAL_QUOTES=$(grep -v '^$' "$QUOTES_FILE" | wc -l)
    if [ "$TOTAL_QUOTES" -gt 0 ]; then
        # Get random line number (between 1 and total quotes)
        RANDOM_LINE=$((RANDOM % TOTAL_QUOTES + 1))
        # Extract the random quote
        RANDOM_QUOTE=$(sed "${RANDOM_LINE}q;d" "$QUOTES_FILE")
    else
        RANDOM_QUOTE="No quotes found in the quotes file."
    fi
else
    RANDOM_QUOTE="Quotes file not found at $QUOTES_FILE"
fi

# Print the output
echo
echo -e "\033[1;34m$NIXAR_ART\033[0m"
echo
echo -e "      \033[1;33m🕒   $CURRENT_DATETIME   🕒\033[0m"
echo
echo -e "       \033[1;32m_,met\$\$\$\$\$\gg.         \033[1;35m$USER_HOST\033[0m"
echo -e "    \033[1;32m,g\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$P.       \033[1;31m------------\033[0m"
echo -e "  \033[1;32m,g\$\$P\"     \"\"\"Y\$\$\".\"        \033[1;36mOS:\033[0m $OS_INFO"
echo -e " \033[1;32m,\$\$P'              \`\$\$\$.     \033[1;36mHost:\033[0m $HOSTNAME"
echo -e "\033[1;32m',\$\$P       ,ggs.     \`\$\$b:   \033[1;36mKernel:\033[0m $KERNEL_INFO"
echo -e "\033[1;32m\`d\$\$'     ,\$P\"'   .    \$\$\$:   \033[1;36mUptime:\033[0m $UPTIME_INFO"
echo -e "\033[1;32m \$\$P      d\$'     ,    \$\$P    \033[1;36mPackages:\033[0m $PKGS_INFO (dpkg)"
echo -e "\033[1;32m \$\$:      \$\$.   -    ,d\$\$'    \033[1;36mShell:\033[0m $SHELL_INFO"
echo -e "\033[1;32m \$\$;      Y\$b._   _,d\$P'      \033[1;36mTerminal:\033[0m $TERM_INFO"
echo -e "\033[1;32m Y\$\$.    \`.\`\"Y\$\$\$\$P\"'         \033[1;36mCPU:\033[0m $CPU_INFO"
echo -e "\033[1;32m \`\$\$b      \"-.__              \033[1;36mGPU:\033[0m $GPU_INFO"
echo -e "\033[1;32m  \`Y\$\$                        \033[1;36mMemory:\033[0m $MEMORY_INFO"
echo -e "\033[1;32m   \`Y\$\$.                      \033[1;36mDisk:\033[0m $DISK_INFO"
echo -e "\033[1;32m     \`\$\$b.                    \033[1;36mFlatpak:\033[0m $FLATPAK_PKGS"
echo -e "\033[1;32m       \`Y\$\$b.                 \033[1;36mPip:\033[0m $PIP_PKGS"
echo -e "\033[1;32m          \`\"Y\$b._             \033[1;36mCargo:\033[0m $CARGO_PKGS"
echo -e "\033[1;32m              \`\"\"\"\"           \033[1;36mUpdates:\033[0m $UPDATE_INFO"
echo
echo -e "\033[1;35m$RANDOM_QUOTE\033[0m"
echo
