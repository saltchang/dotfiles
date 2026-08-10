#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
NC="\033[0m"
# ==================================================================================================

printf '%bStart setting up Arch Linux config files...%b\n' "$GREEN" "$NC"

# Dependencies for the scripts in bin/ that the Hyprland keybinds call
# (close-window needs jq + notify-send). Format: "<command>:<package>".
ARCH_PACKAGES=(jq:jq notify-send:libnotify)

if command -v paru &>/dev/null; then
    for entry in "${ARCH_PACKAGES[@]}"; do
        cmd="${entry%%:*}"
        pkg="${entry##*:}"
        if ! command -v "$cmd" &>/dev/null; then
            printf '%bInstalling %s...%b\n' "$GREEN" "$pkg" "$NC"
            paru -S --noconfirm "$pkg"
        fi
    done
fi

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

./scripts/setup-config-dir.sh --name=Walker --config-dir=walker

./scripts/setup-config-dir.sh --name=Elephant --config-dir=elephant

./scripts/setup-config-dir.sh --name=Swappy --config-dir=swappy

printf '\n%bSetup completed!%b\n' "$GREEN" "$NC"
