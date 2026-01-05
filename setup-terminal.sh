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
    *)
        echo "Unknown option $i"
        exit 1
        ;;
    esac
done
# ==================================================================================================

if [ "$SETUP_KITTY" = true ]; then
    echo -e "Ready to setup kitty"

    KITTY_LOCAL_CONFIG_PATH="./.config/kitty/local.conf"

    if [ -e "$KITTY_LOCAL_CONFIG_PATH" ]; then
        rm "$KITTY_LOCAL_CONFIG_PATH" 2>/dev/null && echo -e "${GREEN}Removed original local kitty config${NC}"
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
    echo -e "Ready to setup ghostty"
    ./scripts/setup-ghostty.sh
fi

if [ "$SETUP_ITERM2" = true ]; then
    echo -e "Ready to setup iterm2"
    ./scripts/setup-iterm2.sh
fi

echo
echo -e "${GREEN}Terminal Setup Completed!${NC}"
