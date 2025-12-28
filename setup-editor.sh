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
        echo "Unknown option $i"
        exit 1
        ;;
    esac
done
# ==================================================================================================

if [ "$SETUP_ZED" = true ]; then
    echo -e "Ready to setup zed"
    ./scripts/setup-config-dir.sh --name=Zed --config-dir=zed
fi

if [ "$SETUP_NVIM" = true ]; then
    echo -e "Ready to setup nvim"
    ./scripts/setup-config-dir.sh --name=Neovim --config-dir=nvim
fi

echo
echo -e "${GREEN}Setup Completed!${NC}"
