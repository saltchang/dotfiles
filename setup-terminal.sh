#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
NC="\033[0m"
# ==================================================================================================

OS_NAME=""
LINUX="Linux"
MACOS="macOS"

case $(uname) in
Darwin)
    OS_NAME=$MACOS
    ;;

Linux)
    OS_NAME=$LINUX
    ;;
esac

# ===> Arugments ===================================================================================
for i in "$@"; do
    case $i in
    --iterm2)
        SETUP_ITERM2=true
        shift
        ;;
    --kitty)
        SETUP_KITTY=true
        shift
        ;;
    --ghostty)
        SETUP_GHOSTTY=true
        shift
        ;;
    --tmux)
        SETUP_TMUX=true
        shift
        ;;
    *)
        printf '%s\n' "Unknown option $i"
        exit 1
        ;;
    esac
done
# ==================================================================================================

if [ "$SETUP_KITTY" = true ]; then
    printf '%s\n' "Ready to setup kitty"

    KITTY_LOCAL_CONFIG_PATH="./.config/kitty/local.conf"

    if [ -e "$KITTY_LOCAL_CONFIG_PATH" ]; then
        rm "$KITTY_LOCAL_CONFIG_PATH" 2>/dev/null && printf '%bRemoved original local kitty config%b\n' "$GREEN" "$NC"
    fi

    case $OS_NAME in
    "$MACOS")
        cp ./.config/kitty/local.mac.conf ./.config/kitty/local.conf
        ;;
    "$LINUX")
        cp ./.config/kitty/local.arch.conf ./.config/kitty/local.conf
        ;;
    *) ;;
    esac

    ./scripts/setup-config-dir.sh --name=Kitty --config-dir=kitty
fi

if [ "$SETUP_GHOSTTY" = true ]; then
    printf '%s\n' "Ready to setup ghostty"
    ./scripts/setup-ghostty.sh
fi

if [ "$SETUP_ITERM2" = true ]; then
    printf '%s\n' "Ready to setup iterm2"
    ./scripts/setup-iterm2.sh
fi

if [ "$SETUP_TMUX" = true ]; then
    printf '%s\n' "Ready to setup tmux"
    ./scripts/setup-config-dir.sh --name=Tmux --config-dir=tmux

    # Bootstrap TPM (tmux plugin manager) if it's not present
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$TPM_DIR" ]; then
        printf '%s\n' "Installing TPM (tmux plugin manager)..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    else
        printf '%bTPM is already installed%b\n' "$GREEN" "$NC"
    fi

    # Install declared plugins non-interactively
    if [ -x "$TPM_DIR/bin/install_plugins" ]; then
        printf '%s\n' "Installing tmux plugins..."
        "$TPM_DIR/bin/install_plugins"
    fi
fi

printf '\n'
printf '%bTerminal Setup Completed!%b\n' "$GREEN" "$NC"
