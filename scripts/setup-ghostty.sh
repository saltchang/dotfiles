#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
ERROR="\033[31m"
NC="\033[0m"
# ==================================================================================================

echo
echo "Setting up Ghostty..."

GHOSTTY_CONFIG_SOURCE_REL="terminal-config/ghostty/config"
GHOSTTY_CONFIG_SOURCE="$(pwd)/$GHOSTTY_CONFIG_SOURCE_REL"
GHOSTTY_THEMES_SOURCE_REL="terminal-config/ghostty/themes"
GHOSTTY_THEMES_SOURCE="$(pwd)/$GHOSTTY_THEMES_SOURCE_REL"

[ ! -e "$GHOSTTY_CONFIG_SOURCE" ] && echo -e "${ERROR}File not found: \"./$GHOSTTY_CONFIG_SOURCE\". You may be in the wrong directory >>> Exit 1${NC}" && exit 1

chmod 600 "$GHOSTTY_CONFIG_SOURCE"

if $(uname) == "Darwin"; then
    GHOSTTY_CONFIG_FILE=$HOME/Library/Application\ Support/com.mitchellh.ghostty/config
    GHOSTTY_THEMES_DIR=$HOME/Library/Application\ Support/com.mitchellh.ghostty/themes
else
    GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
 
    [ ! -d "$GHOSTTY_CONFIG_DIR" ] && mkdir -p "$GHOSTTY_CONFIG_DIR" && echo -e "${GREEN}Created new directory: $GHOSTTY_CONFIG_DIR${NC}"
 
    GHOSTTY_CONFIG_FILE="$HOME/.config/ghostty/config"
    GHOSTTY_THEMES_DIR="$HOME/.config/ghostty/themes"
fi

echo "Check and remove original file and directory..."
echo

[ -e "$GHOSTTY_CONFIG_FILE" ] && rm "$GHOSTTY_CONFIG_FILE" 2>/dev/null && echo -e "${GREEN}Removed original ghostty config file${NC}"
[ -L "$GHOSTTY_THEMES_DIR" ] && rm "$GHOSTTY_THEMES_DIR" 2>/dev/null && echo -e "${GREEN}Removed original ghostty themes symlink${NC}"
[ -d "$GHOSTTY_THEMES_DIR" ] && [ ! -L "$GHOSTTY_THEMES_DIR" ] && rm -rf "$GHOSTTY_THEMES_DIR" 2>/dev/null && echo -e "${GREEN}Removed original ghostty themes directory${NC}"

echo
echo "Check and create new symbolic links..."
echo

ln -s "$GHOSTTY_CONFIG_SOURCE" "$GHOSTTY_CONFIG_FILE" && echo -e "${GREEN}Created a new symbolic link from $GHOSTTY_CONFIG_FILE to $GHOSTTY_CONFIG_SOURCE${NC}"
ln -s "$GHOSTTY_THEMES_SOURCE" "$GHOSTTY_THEMES_DIR" && echo -e "${GREEN}Created a new symbolic link from $GHOSTTY_THEMES_DIR to $GHOSTTY_THEMES_SOURCE${NC}"

echo

echo "Successfully set up Ghostty."
