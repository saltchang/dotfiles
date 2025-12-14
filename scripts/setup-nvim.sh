#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
ERROR="\033[31m"
NC="\033[0m"
# ==================================================================================================

echo
echo "Setting up Neovim..."

NVIM_CONFIG_SOURCE_REL="vim-config/nvim"
NVIM_CONFIG_SOURCE="$(pwd)/$NVIM_CONFIG_SOURCE_REL"

[ ! -d "$NVIM_CONFIG_SOURCE" ] && echo -e "${ERROR}Directory not found: \"./$NVIM_CONFIG_SOURCE_REL\". You may be in the wrong directory >>> Exit 1${NC}" && exit 1

CONFIG_DIR="$HOME/.config"
[ ! -d "$CONFIG_DIR" ] && mkdir -p "$CONFIG_DIR" && echo -e "${GREEN}Created new directory: $CONFIG_DIR${NC}"

NVIM_CONFIG_DIR="$HOME/.config/nvim"

echo "Check and remove original nvim config directory..."
echo

[ -e "$NVIM_CONFIG_DIR" ] && rm -rf "$NVIM_CONFIG_DIR" 2>/dev/null && echo -e "${GREEN}Removed original nvim config directory${NC}"

echo
echo "Check and create new symbolic link..."
echo

ln -s "$NVIM_CONFIG_SOURCE" "$NVIM_CONFIG_DIR" && echo -e "${GREEN}Created a new symbolic link from $NVIM_CONFIG_DIR to $NVIM_CONFIG_SOURCE${NC}"

echo

echo "Successfully set up Neovim."

