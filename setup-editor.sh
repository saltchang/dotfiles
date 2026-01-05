#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
NC="\033[0m"
# ==================================================================================================

# ===> Arugments ===================================================================================
for i in "$@"; do
    case $i in
    --zed)
        SETUP_ZED=true
        shift
        ;;
    --nvim)
        SETUP_NVIM=true
        shift
        ;;
    *)
        printf '%s\n' "Unknown option $i"
        exit 1
        ;;
    esac
done
# ==================================================================================================

if [ "$SETUP_ZED" = true ]; then
    printf '%s\n' "Ready to setup zed"
    ./scripts/setup-config-dir.sh --name=Zed --config-dir=zed
fi

if [ "$SETUP_NVIM" = true ]; then
    printf '%s\n' "Ready to setup nvim"
    ./scripts/setup-config-dir.sh --name=Neovim --config-dir=nvim
fi

printf '\n'
printf '%b%s%b\n' "$GREEN" "Setup Completed!" "$NC"
