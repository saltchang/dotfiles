#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
ERROR="\033[31m"
NC="\033[0m"
# ==================================================================================================

echo
echo "Setting up Kitty..."

KITTY_CONFIG_SOURCE_REL="terminal-config/kitty/kitty.conf"
KITTY_CONFIG_SOURCE="$(pwd)/$KITTY_CONFIG_SOURCE_REL"

[ ! -e "$KITTY_CONFIG_SOURCE" ] && echo -e "${ERROR}File not found: \"./$KITTY_CONFIG_SOURCE\". You may be in the wrong directory >>> Exit 1${NC}" && exit 1

chmod 600 "$KITTY_CONFIG_SOURCE"

KITTY_CONFIG_DIR="$HOME/.config/kitty"

[ ! -d "$KITTY_CONFIG_DIR" ] && mkdir -p "$KITTY_CONFIG_DIR" && echo -e "${GREEN}Created new directory: $KITTY_CONFIG_DIR${NC}"

KITTY_CONFIG_FILE="$HOME/.config/kitty/kitty.conf"

echo "Check and remove original file and directory..."
echo

[ -e "$KITTY_CONFIG_FILE" ] && rm "$KITTY_CONFIG_FILE" 2>/dev/null && echo -e "${GREEN}Removed original kitty config file${NC}"

echo
echo "Check and create new symbolic link..."
echo

ln -s "$KITTY_CONFIG_SOURCE" "$KITTY_CONFIG_FILE" && echo -e "${GREEN}Created a new symbolic link from $KITTY_CONFIG_FILE to $KITTY_CONFIG_SOURCE${NC}"

echo

echo "Successfully set up Kitty."

