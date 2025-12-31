#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
YELLOW="\033[33m"
ERROR="\033[31m"
NC="\033[0m"
# ==================================================================================================

LOCAL_DOTFILES_ROOT_DIR="$HOME/.local/dotfiles/"
LOCAL_DOTFILES_BIN_DIR="$LOCAL_DOTFILES_ROOT_DIR/bin"
SOURCE_BIN_DIR="$(pwd)/bin"

ZPROFILE_SOURCE_REL="dotfiles/.zprofile"
ZPROFILE_SOURCE="$(pwd)/$ZPROFILE_SOURCE_REL"

ZSHRC_SOURCE_REL="dotfiles/.zshrc"
ZSHRC_SOURCE="$(pwd)/$ZSHRC_SOURCE_REL"

ZPREZTORC_SOURCE_REL="dotfiles/.zpreztorc"
ZPREZTORC_SOURCE="$(pwd)/$ZPREZTORC_SOURCE_REL"

P10K_SOURCE_REL="dotfiles/.p10k.zsh"
P10K_SOURCE="$(pwd)/$P10K_SOURCE_REL"

PROTOTOOLS_SOURCE_REL="dotfiles/.prototools"
PROTOTOOLS_SOURCE="$(pwd)/$PROTOTOOLS_SOURCE_REL"

[ ! -d "$SOURCE_BIN_DIR" ] && echo -e "${ERROR}Directory not found: \"$SOURCE_BIN_DIR\". You may be in the wrong directory >>> Exit 1${NC}" && exit 1

[ ! -e "$ZPROFILE_SOURCE" ] && echo -e "${ERROR}File not found: \"./$ZPROFILE_SOURCE_REL\". You may be in the wrong directory >>> Exit 1${NC}" && exit 1

[ ! -e "$ZSHRC_SOURCE" ] && echo -e "${ERROR}File not found: \"./$ZSHRC_SOURCE_REL\". You may be in the wrong directory >>> Exit ${NC}" && exit 1

[ ! -e "$ZPREZTORC_SOURCE" ] && echo -e "${ERROR}File not found: \"./$ZPREZTORC_SOURCE_REL\". You may be in the wrong directory >>> Exit 1${NC}" && exit 1

[ ! -e "$P10K_SOURCE" ] && echo -e "${ERROR}File not found: \"./$P10K_SOURCE_REL\". You may be in the wrong directory >>> Exit 1${NC}" && exit 1

[ ! -e "$PROTOTOOLS_SOURCE" ] && echo -e "${ERROR}File not found: \"./$PROTOTOOLS_SOURCE_REL\". You may be in the wrong directory >>> Exit 1${NC}" && exit 1

chmod 600 "$ZPROFILE_SOURCE"

chmod 600 "$ZSHRC_SOURCE"

chmod 600 "$ZPREZTORC_SOURCE"

chmod 600 "$P10K_SOURCE"

chmod 600 "$PROTOTOOLS_SOURCE"

ZPROFILE_FILE="$HOME/.zprofile"

ZSHRC_FILE="$HOME/.zshrc"

ZPRESTORC_FILE="$HOME/.zpreztorc"

P10KZSH_FILE="$HOME/.p10k.zsh"

PROTOTOOLS_FILE="$HOME/.prototools"

echo "Check and remove original files and directories..."
echo

if [ -e "$ZPROFILE_FILE" ] || [ -L "$ZPROFILE_FILE" ]; then
    rm "$ZPROFILE_FILE" 2>/dev/null && echo -e "${GREEN}Removed original .zprofile${NC}"
fi

if [ -e "$ZSHRC_FILE" ] || [ -L "$ZSHRC_FILE" ]; then
    rm "$ZSHRC_FILE" 2>/dev/null && echo -e "${GREEN}Removed original .zshrc${NC}"
fi

if [ -e "$ZPRESTORC_FILE" ] || [ -L "$ZPRESTORC_FILE" ]; then
    rm "$ZPRESTORC_FILE" 2>/dev/null && echo -e "${GREEN}Removed original .zpreztorc${NC}"
fi

if [ -e "$P10KZSH_FILE" ] || [ -L "$P10KZSH_FILE" ]; then
    rm "$P10KZSH_FILE" 2>/dev/null && echo -e "${GREEN}Removed original .p10k.zsh${NC}"
fi

if [ -e "$PROTOTOOLS_FILE" ] || [ -L "$PROTOTOOLS_FILE" ]; then
    rm "$PROTOTOOLS_FILE" 2>/dev/null && echo -e "${GREEN}Removed original .prototools${NC}"
fi

if [ -e "$LOCAL_DOTFILES_BIN_DIR" ] || [ -L "$LOCAL_DOTFILES_BIN_DIR" ]; then
    rm -rf "$LOCAL_DOTFILES_BIN_DIR" 2>/dev/null && echo -e "${GREEN}Removed original directory: $LOCAL_DOTFILES_BIN_DIR${NC}"
fi

echo
echo "Check and create new symbolic links..."
echo

[ ! -d "$LOCAL_DOTFILES_ROOT_DIR" ] && mkdir -p "$LOCAL_DOTFILES_ROOT_DIR" && echo -e "${GREEN}Created new directory: $LOCAL_DOTFILES_ROOT_DIR${NC}"

ln -s "$SOURCE_BIN_DIR" "$LOCAL_DOTFILES_BIN_DIR" && echo -e "${GREEN}Created a new symbolic link from $LOCAL_DOTFILES_BIN_DIR to $SOURCE_BIN_DIR${NC}"

ln -s "$ZPROFILE_SOURCE" "$ZPROFILE_FILE" && echo -e "${GREEN}Created a new symbolic link from $ZPROFILE_FILE to $ZPROFILE_SOURCE${NC}"

ln -s "$ZSHRC_SOURCE" "$ZSHRC_FILE" && echo -e "${GREEN}Created a new symbolic link from $ZSHRC_FILE to $ZSHRC_SOURCE${NC}"

ln -s "$ZPREZTORC_SOURCE" "$ZPRESTORC_FILE" && echo -e "${GREEN}Created a new symbolic link from $ZPRESTORC_FILE to $ZPREZTORC_SOURCE${NC}"

ln -s "$P10K_SOURCE" "$P10KZSH_FILE" && echo -e "${GREEN}Created a new symbolic link from $P10KZSH_FILE to $P10K_SOURCE${NC}"

ln -s "$PROTOTOOLS_SOURCE" "$PROTOTOOLS_FILE" && echo -e "${GREEN}Created a new symbolic link from $PROTOTOOLS_FILE to $PROTOTOOLS_SOURCE${NC}"

./scripts/setup-cheat.sh.sh

echo

echo "Setup completed!"
echo
echo -e "${YELLOW}Please restart your terminal or run \`source \$HOME/.zshrc\` to reload .zshrc${NC}"
