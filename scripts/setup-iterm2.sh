#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
ERROR="\033[31m"
NC="\033[0m"
# ==================================================================================================

printf '\n'
printf '%s\n' "Setting up iTerm2..."

ITERM2_CONFIG_SOURCE="$(pwd)/terminal-config/iTerm/com.googlecode.iterm2.plist"
ITERM2_CONFIG_FILE="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

[ ! -e "$ITERM2_CONFIG_SOURCE" ] && printf '%b%s%b\n' "$ERROR" "File not found: \"./$ITERM2_CONFIG_SOURCE\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1

printf '%s\n' "Check and remove original file"
printf '\n'

[ -e "$ITERM2_CONFIG_FILE" ] && rm "$ITERM2_CONFIG_FILE" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed original iTerm2 config file" "$NC"

cp -f "$ITERM2_CONFIG_SOURCE" "$ITERM2_CONFIG_FILE"

printf '%b%s%b\n' "$GREEN" "Copied new iTerm2 config file" "$NC"

printf '\n'

printf '%s\n' "Successfully set up iTerm2."
