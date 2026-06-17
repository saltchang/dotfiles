#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
YELLOW="\033[33m"
ERROR="\033[31m"
NC="\033[0m"
# ==================================================================================================

OS_NAME=""
LINUX="Linux"
MACOS="macOS"

UBUNTU="Ubuntu"
DEBIAN="Debian"
ARCH="Arch"

case $(uname) in
Darwin)
    OS_NAME=$MACOS
    ;;

Linux)
    OS_NAME=$LINUX
    ;;
esac

# ===> Detect Linux Distribution ===================================================================
case $OS_NAME in
"$LINUX")
    if command -v lsb_release &>/dev/null; then
        OS_INFO=$(lsb_release -a 2>/dev/null)

        case $OS_INFO in
        *"$UBUNTU"*)
            DISTRO_NAME=$UBUNTU
            ;;
        *"$DEBIAN"*)
            DISTRO_NAME=$DEBIAN
            ;;
        *"$ARCH"*)
            DISTRO_NAME=$ARCH
            ;;
        esac
    fi
    ;;
esac
# ==================================================================================================

# ===> Install zsh and set as default shell ========================================================
if ! [ -x "$(command -v zsh)" ]; then
    case $OS_NAME in
    "$LINUX")
        case $DISTRO_NAME in
        "$ARCH")
            paru -S --noconfirm zsh
            ;;
        "$UBUNTU" | "$DEBIAN")
            sudo apt update && sudo apt -y install zsh
            ;;
        *) ;;
        esac
        ;;
    *) ;;
    esac
fi
printf '%bzsh is already installed%b\n' "$GREEN" "$NC"

candidate_paths="/usr/bin/zsh /bin/zsh"
zsh_path=""

for path in $candidate_paths; do
    if [ -x "$path" ]; then
        zsh_path="$path"
        break
    fi
done

if [ -z "$zsh_path" ]; then
    zsh_path="$(command -v zsh)"
fi

if [ -z "$zsh_path" ]; then
    printf '%bError: Zsh not found. Please install it first (e.g., paru -S zsh)%b\n' "$ERROR" "$NC"
    exit 1
fi

if [ "$SHELL" != "$zsh_path" ]; then
    printf "Setting default shell to '%s'...\n" "$zsh_path"

    if ! grep -Fxq "$zsh_path" /etc/shells; then
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    sudo chsh -s "$zsh_path" "$USER"
    printf '\033[0;32mDone.\033[0m\n'
    printf '%bSetup zsh as default shell done.%b\n' "$GREEN" "$NC"
else
    printf '%bZsh is already your default shell.%b\n' "$GREEN" "$NC"
fi
# ==================================================================================================

LOCAL_DOTFILES_ROOT_DIR="$HOME/.local/dotfiles"
LOCAL_DOTFILES_BIN_DIR="$LOCAL_DOTFILES_ROOT_DIR/bin"
SOURCE_BIN_DIR="$(pwd)/bin"

# Dotfiles symlinked from dotfiles/<name> to $HOME/<name>.
DOTFILES=(.zprofile .zshrc .zpreztorc .p10k.zsh .prototools)
[ "$OS_NAME" = "$MACOS" ] && DOTFILES+=(.aerospace.toml)

[ ! -d "$SOURCE_BIN_DIR" ] && printf '%b%s%b\n' "$ERROR" "Directory not found: \"$SOURCE_BIN_DIR\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1

for name in "${DOTFILES[@]}"; do
    src="$(pwd)/dotfiles/$name"
    [ ! -e "$src" ] && printf '%b%s%b\n' "$ERROR" "File not found: \"./dotfiles/$name\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1
    chmod 600 "$src"
done

# .zshrc.local: machine-local, copied from the example on first run.
ZSHRC_LOCAL_SOURCE="$(pwd)/dotfiles/.zshrc.local"
if [ ! -e "$ZSHRC_LOCAL_SOURCE" ]; then
    printf '%b%s%b\n' "$GREEN" "Copying .zshrc.local..." "$NC"
    cp "$(pwd)/dotfiles/.zshrc.local.example" "$ZSHRC_LOCAL_SOURCE"
fi
chmod 600 "$ZSHRC_LOCAL_SOURCE"

printf '%s\n' "Check and remove original files and directories..."
printf '\n'

for name in "${DOTFILES[@]}"; do
    target="$HOME/$name"
    if [ -e "$target" ] || [ -L "$target" ]; then
        rm "$target" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed original $name" "$NC"
    fi
done

if [ -e "$LOCAL_DOTFILES_BIN_DIR" ] || [ -L "$LOCAL_DOTFILES_BIN_DIR" ]; then
    rm -rf "$LOCAL_DOTFILES_BIN_DIR" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed original directory: $LOCAL_DOTFILES_BIN_DIR" "$NC"
fi

printf '\n'
printf '%s\n' "Check and create new symbolic links..."
printf '\n'

[ ! -d "$LOCAL_DOTFILES_ROOT_DIR" ] && mkdir -p "$LOCAL_DOTFILES_ROOT_DIR" && printf '%b%s%b\n' "$GREEN" "Created new directory: $LOCAL_DOTFILES_ROOT_DIR" "$NC"

ln -s "$SOURCE_BIN_DIR" "$LOCAL_DOTFILES_BIN_DIR" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $LOCAL_DOTFILES_BIN_DIR to $SOURCE_BIN_DIR" "$NC"

for name in "${DOTFILES[@]}"; do
    src="$(pwd)/dotfiles/$name"
    target="$HOME/$name"
    ln -s "$src" "$target" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $target to $src" "$NC"
done

# .zshrc.local: link only if absent, so machine-local edits survive re-runs.
ZSHRC_LOCAL_FILE="$HOME/.zshrc.local"
if [ -e "$ZSHRC_LOCAL_FILE" ] || [ -L "$ZSHRC_LOCAL_FILE" ]; then
    printf '%b%s%b\n' "$YELLOW" ".zshrc.local already exists, skipping creating..." "$NC"
else
    ln -s "$ZSHRC_LOCAL_SOURCE" "$ZSHRC_LOCAL_FILE" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $ZSHRC_LOCAL_FILE to $ZSHRC_LOCAL_SOURCE" "$NC"
fi

./scripts/setup-cheat.sh

printf '\n'

printf '%s\n' "Setup completed!"
printf '\n'
printf '%b%s%b\n' "$YELLOW" "You can add the global environment variables in \$HOME/.zshrc.local" "$NC"
printf '%b%s%b\n' "$YELLOW" "Please restart your terminal or run \`source \$HOME/.zshrc\` to reload .zshrc" "$NC"
