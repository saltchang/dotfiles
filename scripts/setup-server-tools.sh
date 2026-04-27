#!/bin/bash
set -e

# ===> Colors ======================================================================================
GREEN="\033[32m"
WARNING="\033[33m"
ERROR="\033[31m"
NC="\033[0m"
# ==================================================================================================

# Tools that headless / server hosts need but desktops typically already get
# from brew or pacman. Safe to run on desktops too — every step is idempotent
# and skips when the tool is already on PATH.

# ===> uv ==========================================================================================
# Astral's Python project & script runner. Required for any script in this
# org that uses a `#!/usr/bin/env -S uv run --script` shebang + PEP 723
# inline metadata (e.g. homelab-deploy/scripts/audit-secrets.py).
if command -v uv >/dev/null 2>&1; then
    printf '%buv is already installed: %s%b\n' "$GREEN" "$(uv --version)" "$NC"
else
    printf '%s\n' "Installing uv..."

    # If dotfiles owns ~/.zshrc (symlink), PATH for ~/.local/bin is already
    # set centrally there — don't let the installer append to a symlinked
    # rc file (that would write into the dotfiles repo). On bare servers,
    # let the installer modify the appropriate rc (.bashrc / .profile) so
    # new shells pick uv up automatically.
    if [ -L "$HOME/.zshrc" ]; then
        export INSTALLER_NO_MODIFY_PATH=1
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://astral.sh/uv/install.sh | sh
    else
        printf '%bcurl/wget not found, cannot install uv%b\n' "$ERROR" "$NC"
        exit 1
    fi

    printf '%buv installed at ~/.local/bin/uv. New shells will pick it up automatically.%b\n' "$GREEN" "$NC"
    printf '%bFor this shell only, run: export PATH="$HOME/.local/bin:$PATH"%b\n' "$WARNING" "$NC"
fi
