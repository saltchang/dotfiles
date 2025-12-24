#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
YELLOW="\033[33m"
ERROR="\033[31m"
NC="\033[0m"
# ==================================================================================================

# ===> Arugments ===================================================================================
for i in "$@"; do
    case $i in
    --setup-iterm2)
        SETUP_ITERM2=true
        shift
        ;;
    --setup-kitty)
        SETUP_KITTY=true
        shift
        ;;
    --setup-ghostty)
        SETUP_GHOSTTY=true
        shift
        ;;
    --setup-nvim)
        SETUP_NVIM=true
        shift
        ;;
    *) ;;
    esac
done
# ==================================================================================================

TERMINAL_SETUP_LOCAL_DIR="$HOME/.local/terminal-setup/"
TERMINAL_SETUP_LOCAL_BIN_DIR="$TERMINAL_SETUP_LOCAL_DIR/bin"
TERMINAL_SETUP_REPO_BIN_DIR="$(pwd)/bin"

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

[ ! -d "$TERMINAL_SETUP_REPO_BIN_DIR" ] && echo -e "${ERROR}Directory not found: \"$TERMINAL_SETUP_REPO_BIN_DIR\". You may be in the wrong directory >>> Exit 1${NC}" && exit 1

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

[ -e "$ZPROFILE_FILE" ] && rm "$ZPROFILE_FILE" 2>/dev/null && echo -e "${GREEN}Removed original .zprofile${NC}"

[ -e "$ZSHRC_FILE" ] && rm "$ZSHRC_FILE" 2>/dev/null && echo -e "${GREEN}Removed original .zshrc${NC}"

[ -e "$ZPRESTORC_FILE" ] && rm "$ZPRESTORC_FILE" 2>/dev/null && echo -e "${GREEN}Removed original .zpreztorc${NC}"

[ -e "$P10KZSH_FILE" ] && rm "$P10KZSH_FILE" 2>/dev/null && echo -e "${GREEN}Removed original .p10k.zsh${NC}"

[ -e "$PROTOTOOLS_FILE" ] && rm "$PROTOTOOLS_FILE" 2>/dev/null && echo -e "${GREEN}Removed original .prototools${NC}"

[ -d "$TERMINAL_SETUP_LOCAL_BIN_DIR" ] && rm -rf "$TERMINAL_SETUP_LOCAL_BIN_DIR" 2>/dev/null && echo -e "${GREEN}Removed original directory: $TERMINAL_SETUP_LOCAL_BIN_DIR${NC}"

echo
echo "Check and create new symbolic links..."
echo

[ ! -d "$TERMINAL_SETUP_LOCAL_DIR" ] && mkdir -p "$TERMINAL_SETUP_LOCAL_DIR" && echo -e "${GREEN}Created new directory: $TERMINAL_SETUP_LOCAL_DIR${NC}"

ln -s "$TERMINAL_SETUP_REPO_BIN_DIR" "$TERMINAL_SETUP_LOCAL_BIN_DIR" && echo -e "${GREEN}Created a new symbolic link from $TERMINAL_SETUP_LOCAL_BIN_DIR to $TERMINAL_SETUP_REPO_BIN_DIR${NC}"

ln -s "$ZPROFILE_SOURCE" "$ZPROFILE_FILE" && echo -e "${GREEN}Created a new symbolic link from $ZPROFILE_FILE to $ZPROFILE_SOURCE${NC}"

ln -s "$ZSHRC_SOURCE" "$ZSHRC_FILE" && echo -e "${GREEN}Created a new symbolic link from $ZSHRC_FILE to $ZSHRC_SOURCE${NC}"

ln -s "$ZPREZTORC_SOURCE" "$ZPRESTORC_FILE" && echo -e "${GREEN}Created a new symbolic link from $ZPRESTORC_FILE to $ZPREZTORC_SOURCE${NC}"

ln -s "$P10K_SOURCE" "$P10KZSH_FILE" && echo -e "${GREEN}Created a new symbolic link from $P10KZSH_FILE to $P10K_SOURCE${NC}"

ln -s "$PROTOTOOLS_SOURCE" "$PROTOTOOLS_FILE" && echo -e "${GREEN}Created a new symbolic link from $PROTOTOOLS_FILE to $PROTOTOOLS_SOURCE${NC}"

if [ "$SETUP_KITTY" = true ]; then
    ./scripts/setup-kitty.sh
fi

if [ "$SETUP_GHOSTTY" = true ]; then
    ./scripts/setup-ghostty.sh
fi

if [ "$SETUP_ITERM2" = true ]; then
    ./scripts/setup-iterm2.sh
fi

if [ "$SETUP_NVIM" = true ]; then
    ./scripts/setup-nvim.sh
fi

./scripts/setup-cheat.sh.sh

echo

echo "Setup completed!"
echo
echo -e "${YELLOW}Please restart your terminal or run \`source \$HOME/.zshrc\` to reload .zshrc${NC}"
