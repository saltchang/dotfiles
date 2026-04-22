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

ZPROFILE_SOURCE_REL="dotfiles/.zprofile"
ZPROFILE_SOURCE="$(pwd)/$ZPROFILE_SOURCE_REL"

ZSHRC_SOURCE_REL="dotfiles/.zshrc"
ZSHRC_SOURCE="$(pwd)/$ZSHRC_SOURCE_REL"

ZSHRC_LOCAL_SOURCE_REL="dotfiles/.zshrc.local"
ZSHRC_LOCAL_SOURCE="$(pwd)/$ZSHRC_LOCAL_SOURCE_REL"

ZSHRC_LOCAL_EXAMPLE_SOURCE_REL="dotfiles/.zshrc.local.example"
ZSHRC_LOCAL_EXAMPLE_SOURCE="$(pwd)/$ZSHRC_LOCAL_EXAMPLE_SOURCE_REL"

ZPREZTORC_SOURCE_REL="dotfiles/.zpreztorc"
ZPREZTORC_SOURCE="$(pwd)/$ZPREZTORC_SOURCE_REL"

P10K_SOURCE_REL="dotfiles/.p10k.zsh"
P10K_SOURCE="$(pwd)/$P10K_SOURCE_REL"

PROTOTOOLS_SOURCE_REL="dotfiles/.prototools"
PROTOTOOLS_SOURCE="$(pwd)/$PROTOTOOLS_SOURCE_REL"

case $OS_NAME in
"$MACOS")
    AEROSPACE_CONFIG_SOURCE_REL="dotfiles/.aerospace.toml"
    AEROSPACE_CONFIG_SOURCE="$(pwd)/$AEROSPACE_CONFIG_SOURCE_REL"
    ;;
esac

[ ! -d "$SOURCE_BIN_DIR" ] && printf '%b%s%b\n' "$ERROR" "Directory not found: \"$SOURCE_BIN_DIR\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1

[ ! -e "$ZPROFILE_SOURCE" ] && printf '%b%s%b\n' "$ERROR" "File not found: \"./$ZPROFILE_SOURCE_REL\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1

[ ! -e "$ZSHRC_SOURCE" ] && printf '%b%s%b\n' "$ERROR" "File not found: \"./$ZSHRC_SOURCE_REL\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1

[ ! -e "$ZPREZTORC_SOURCE" ] && printf '%b%s%b\n' "$ERROR" "File not found: \"./$ZPREZTORC_SOURCE_REL\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1

[ ! -e "$P10K_SOURCE" ] && printf '%b%s%b\n' "$ERROR" "File not found: \"./$P10K_SOURCE_REL\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1

[ ! -e "$PROTOTOOLS_SOURCE" ] && printf '%b%s%b\n' "$ERROR" "File not found: \"./$PROTOTOOLS_SOURCE_REL\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1

case $OS_NAME in
"$MACOS")
    [ ! -e "$AEROSPACE_CONFIG_SOURCE" ] && printf '%b%s%b\n' "$ERROR" "File not found: \"./$AEROSPACE_CONFIG_SOURCE_REL\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1
    ;;
esac

if [ ! -e "$ZSHRC_LOCAL_SOURCE" ]; then
    printf '%b%s%b\n' "$GREEN" "Copying .zshrc.local..." "$NC"
    cp "$ZSHRC_LOCAL_EXAMPLE_SOURCE" "$ZSHRC_LOCAL_SOURCE"
fi

chmod 600 "$ZPROFILE_SOURCE"

chmod 600 "$ZSHRC_SOURCE"

chmod 600 "$ZPREZTORC_SOURCE"

chmod 600 "$P10K_SOURCE"

chmod 600 "$PROTOTOOLS_SOURCE"

chmod 600 "$ZSHRC_LOCAL_SOURCE"

ZPROFILE_FILE="$HOME/.zprofile"

ZSHRC_FILE="$HOME/.zshrc"

ZSHRC_LOCAL_FILE="$HOME/.zshrc.local"

ZPRESTORC_FILE="$HOME/.zpreztorc"

P10KZSH_FILE="$HOME/.p10k.zsh"

PROTOTOOLS_FILE="$HOME/.prototools"

case $OS_NAME in
"$MACOS")
    AEROSPACE_CONFIG_FILE="$HOME/.aerospace.toml"
    ;;
esac

printf '%s\n' "Check and remove original files and directories..."
printf '\n'

if [ -e "$ZPROFILE_FILE" ] || [ -L "$ZPROFILE_FILE" ]; then
    rm "$ZPROFILE_FILE" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed original .zprofile" "$NC"
fi

if [ -e "$ZSHRC_FILE" ] || [ -L "$ZSHRC_FILE" ]; then
    rm "$ZSHRC_FILE" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed original .zshrc" "$NC"
fi

if [ -e "$ZPRESTORC_FILE" ] || [ -L "$ZPRESTORC_FILE" ]; then
    rm "$ZPRESTORC_FILE" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed original .zpreztorc" "$NC"
fi

if [ -e "$P10KZSH_FILE" ] || [ -L "$P10KZSH_FILE" ]; then
    rm "$P10KZSH_FILE" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed original .p10k.zsh" "$NC"
fi

if [ -e "$PROTOTOOLS_FILE" ] || [ -L "$PROTOTOOLS_FILE" ]; then
    rm "$PROTOTOOLS_FILE" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed original .prototools" "$NC"
fi

case $OS_NAME in
"$MACOS")
    if [ -e "$AEROSPACE_CONFIG_FILE" ] || [ -L "$AEROSPACE_CONFIG_FILE" ]; then
        rm "$AEROSPACE_CONFIG_FILE" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed original .aerospace.toml" "$NC"
    fi
    ;;
esac

if [ -e "$LOCAL_DOTFILES_BIN_DIR" ] || [ -L "$LOCAL_DOTFILES_BIN_DIR" ]; then
    rm -rf "$LOCAL_DOTFILES_BIN_DIR" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed original directory: $LOCAL_DOTFILES_BIN_DIR" "$NC"
fi

printf '\n'
printf '%s\n' "Check and create new symbolic links..."
printf '\n'

[ ! -d "$LOCAL_DOTFILES_ROOT_DIR" ] && mkdir -p "$LOCAL_DOTFILES_ROOT_DIR" && printf '%b%s%b\n' "$GREEN" "Created new directory: $LOCAL_DOTFILES_ROOT_DIR" "$NC"

ln -s "$SOURCE_BIN_DIR" "$LOCAL_DOTFILES_BIN_DIR" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $LOCAL_DOTFILES_BIN_DIR to $SOURCE_BIN_DIR" "$NC"

ln -s "$ZPROFILE_SOURCE" "$ZPROFILE_FILE" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $ZPROFILE_FILE to $ZPROFILE_SOURCE" "$NC"

ln -s "$ZSHRC_SOURCE" "$ZSHRC_FILE" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $ZSHRC_FILE to $ZSHRC_SOURCE" "$NC"

ln -s "$ZPREZTORC_SOURCE" "$ZPRESTORC_FILE" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $ZPRESTORC_FILE to $ZPREZTORC_SOURCE" "$NC"

ln -s "$P10K_SOURCE" "$P10KZSH_FILE" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $P10KZSH_FILE to $P10K_SOURCE" "$NC"

ln -s "$PROTOTOOLS_SOURCE" "$PROTOTOOLS_FILE" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $PROTOTOOLS_FILE to $PROTOTOOLS_SOURCE" "$NC"

case $OS_NAME in
"$MACOS")
    ln -s "$AEROSPACE_CONFIG_SOURCE" "$AEROSPACE_CONFIG_FILE" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $AEROSPACE_CONFIG_FILE to $AEROSPACE_CONFIG_SOURCE" "$NC"
    ;;
esac

if [ -e "$ZSHRC_LOCAL_FILE" ] || [ -L "$ZSHRC_LOCAL_FILE" ]; then
    printf '%b%s%b\n' "$YELLOW" ".zshrc.local already exists, skipping creating..." "$NC"
else
    ln -s "$ZSHRC_LOCAL_SOURCE" "$ZSHRC_LOCAL_FILE" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $ZSHRC_LOCAL_FILE to $ZSHRC_LOCAL_SOURCE" "$NC"
fi

./scripts/setup-cheat.sh.sh

printf '\n'

printf '%s\n' "Setup completed!"
printf '\n'
printf '%b%s%b\n' "$YELLOW" "You can add the global environment variables in \$HOME/.zshrc.local" "$NC"
printf '%b%s%b\n' "$YELLOW" "Please restart your terminal or run \`source \$HOME/.zshrc\` to reload .zshrc" "$NC"
