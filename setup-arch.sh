#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
NC="\033[0m"
# ==================================================================================================

printf '%bStart setting up Arch Linux config files...%b\n' "$GREEN" "$NC"

# Dependencies for the scripts in bin/ that the Hyprland keybinds call
# (close-window needs jq + notify-send; steam-ime needs patchelf). Format: "<command>:<package>".
ARCH_PACKAGES=(jq:jq notify-send:libnotify patchelf:patchelf)

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

# Install elephant's systemd user unit; hypr autostart starts it with `systemctl --user start elephant`.
if command -v elephant &>/dev/null; then
    elephant service enable
fi

./scripts/setup-config-dir.sh --name=Swappy --config-dir=swappy

# Steam: launch through bin/steam-ime so fcitx5 works in the Steam UI (scripts/steam-fcitx5/README.md).
# The override survives steam package upgrades; GDK_SCALE=2 matches the autostart in hypr/config/autostart.lua.
if [ -f /usr/share/applications/steam.desktop ]; then
    mkdir -p "$HOME/.local/share/applications"
    sed "0,/^Exec=/s|^Exec=.*|Exec=env GDK_SCALE=2 $HOME/.local/dotfiles/bin/steam-ime %U|" \
        /usr/share/applications/steam.desktop >"$HOME/.local/share/applications/steam.desktop"
    printf '%bSteam desktop entry now launches steam-ime%b\n' "$GREEN" "$NC"
fi

printf '\n%bSetup completed!%b\n' "$GREEN" "$NC"
