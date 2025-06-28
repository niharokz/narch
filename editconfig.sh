#!/bin/bash

#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nih.ar] ON 01-06-2025
#       SOURCE [editconfig.sh] LAST MODIFIED ON 01-06-2025.

# Debug: Print PATH for troubleshooting
echo "PATH inside script: $PATH"

# Ensure PATH includes /usr/local/bin for dmenu
export PATH="$PATH:/usr/local/bin:/usr/bin"

# Set DISPLAY if unset
[ -z "$DISPLAY" ] && export DISPLAY=:0

# Configurable terminal and editor
# # Default to kitty if available, else try xterm or gnome-terminal
TERMINAL="/usr/bin/kitty"
# [ ! -x "$(command -v kitty)" ] && TERMINAL="xterm -e"
# [ ! -x "$(command -v xterm)" ] && TERMINAL="gnome-terminal --"
# 
# # Configurable editor (default to nvim, fallback to vim or nano)
# EDITOR="${EDITOR:-nvim}"
# [ ! -x "$(command -v nvim)" ] && EDITOR="vim"
# [ ! -x "$(command -v vim)" ] && EDITOR="nano"

# Debug: Check if commands are available
command -v dmenu >/dev/null 2>&1 || { echo "Error: dmenu not found. Install it with 'sudo apt install dmenu'."; exit 1; }
command -v "$EDITOR" >/dev/null 2>&1 || { echo "Error: editor ($EDITOR) not found. Install it with 'sudo apt install $EDITOR'."; exit 1; }
command -v "$(echo $TERMINAL | cut -d' ' -f1)" >/dev/null 2>&1 || { echo "Error: terminal ($TERMINAL) not found. Ninety
# Install it with 'sudo apt install $(echo $TERMINAL | cut -d' ' -f1)'."; exit 1; }

# dmenu wrapper function
run_dmenu() {
  /usr/local/bin/dmenu -i -h 32 -fn 'FiraCode Nerd Font:size=12' -nb '#0f2f2f' -nf '#dcdccc' -sb '#42938C' -sf '#0f2f2f' "$@"
}

# Configuration: name:path
# Format: "display_name|full_path"
CONFIGS=(
  "xmonad|$HOME/.config/xmonad/xmonad.hs"
  "xmobar|$HOME/.config/xmobar/.xmobarrc"
  "kitty|$HOME/.config/kitty/kitty.conf"
  "alacritty|$HOME/.config/alacritty/alacritty.toml"
  "zsh|$HOME/.config/zsh/.zshrc"
  "alias|$HOME/.config/.alias"
  "thisfile|$WORK/narch/editconfig.sh"
  "nvim|$HOME/.config/nvim/init.vim"
)

# Extract display names for dmenu
CONFIG_NAMES=()
for config in "${CONFIGS[@]}"; do
  IFS='|' read -r name _ <<< "$config"
  CONFIG_NAMES+=("$name")
done

# Use dmenu to select a config file
choice=$(printf '%s\n' "${CONFIG_NAMES[@]}" | run_dmenu -p "Edit Config:")

# Find the corresponding full path
file=""
for config in "${CONFIGS[@]}"; do
  IFS='|' read -r name path <<< "$config"
  if [ "$choice" = "$name" ]; then
    file="$path"
    break
  fi
done

# Open the selected file in the editor using the specified terminal
if [ -n "$file" ] && [ -f "$file" ]; then
  $TERMINAL $EDITOR "$file" &
  echo "Opening $choice in $EDITOR..." | run_dmenu -p "Info:"
else
  echo "File $choice not found or no file selected." | run_dmenu -p "Info:"
  exit 1
fi
