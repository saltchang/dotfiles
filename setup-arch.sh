#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
NC="\033[0m"
# ==================================================================================================

echo -e "${GREEN}Start setting up Arch Linux config files...${NC}"

./scripts/setup-config-dir.sh --name=Hyprland --config-dir=hypr

if command -v hyprpanel &>/dev/null; then
    sleep 1
    hyprctl reload
fi

./scripts/setup-config-dir.sh --name=HyprPanel --config-dir=hyprpanel

if command -v hyprpanel &>/dev/null; then
    sleep 1
    hyprpanel -q
    PATH=/usr/bin:$PATH hyprpanel &
    disown
fi

./scripts/setup-config-dir.sh --name=Rofi --config-dir=rofi

./scripts/setup-config-dir.sh --name=Swappy --config-dir=swappy

echo
echo -e "${GREEN}Setup completed!${NC}"
