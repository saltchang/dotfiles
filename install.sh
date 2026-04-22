#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
WARNING="\033[33m"
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

# ===> Check lsb_release ===========================================================================
# lsb_release is required for OS detection in .zshrc and .p10k.zsh
case $OS_NAME in
"$LINUX")
    if ! command -v lsb_release &>/dev/null; then
        if command -v pacman &>/dev/null; then
            sudo pacman -S lsb-release
        elif command -v apt &>/dev/null; then
            sudo apt-get install lsb-release
        else
            printf '%b%s%b\n' "$WARNING" "Unsupported Linux Distribution, currently we only support Arch Linux, Ubuntu, and Debian." "$NC"
        fi
    fi

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

# Install paru, see: https://github.com/Morganamilo/paru?tab=readme-ov-file#installation
case $DISTRO_NAME in
"$ARCH")
    if ! command -v paru &>/dev/null; then
        printf '%s\n' "Installing paru..."
        sudo pacman -S --needed base-devel
        (git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si)
    fi
    ;;
esac

# ===> Prompt User for the repo to clone ===========================================================
printf '%s\n%s' "Please enter the dotfiles github repo to clone (default: saltchang/dotfiles):" "> "
read -r REPO </dev/tty

if [ -z "$REPO" ]; then
    REPO="saltchang/dotfiles"
fi
# ==================================================================================================

# ===> Prompt User for using kitty as terminal app =================================================
printf '\n%s\n%s' "Do you want to use Kitty (https://sw.kovidgoyal.net/kitty) as terminal app? (y/n, default: y):" "> "
read -r USE_KITTY </dev/tty

if [ -z "$USE_KITTY" ]; then
    USE_KITTY="y"
fi
# ==================================================================================================

# ===> Prompt User for installing tmux =============================================================
printf '\n%s\n%s' "Do you want to install tmux (https://github.com/tmux/tmux) terminal multiplexer? (y/n, default: y):" "> "
read -r USE_TMUX </dev/tty

if [ -z "$USE_TMUX" ]; then
    USE_TMUX="y"
fi
# ==================================================================================================

# ===> Prompt User for setup Neovim config =========================================================
printf '\n%s\n%s' "Do you want to setup Neovim (https://neovim.io) config? (y/n, default: y):" "> "
read -r USE_NVIM </dev/tty

if [ -z "$USE_NVIM" ]; then
    USE_NVIM="y"
fi
# ==================================================================================================

# Hyprland eco for Arch Linux
case $DISTRO_NAME in
"$ARCH")
    printf '\n%s\n%s' "Do you want to setup hyprland, hyprpanel, rofi, and swappy? (y/n, default: y):" "> "
    read -r USE_HYPR </dev/tty

    if [ -z "$USE_HYPR" ]; then
        USE_HYPR="y"
    fi
    ;;
esac

printf '\n'
printf '%s\n' "Check and install necessary stuffs..."
printf '\n'

# ===> Basic Setup By System =======================================================================
case $OS_NAME in
"$MACOS")
    if ! [ -x "$(command -v brew)" ]; then
        printf '%s\n' "Installing Homebrew..."
        BREW_INSTALLER=$(mktemp)
        if curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$BREW_INSTALLER"; then
            /bin/bash "$BREW_INSTALLER"
        else
            printf '%b%s%b\n' "$WARNING" "Failed to download Homebrew installer" "$NC"
        fi
        rm -f "$BREW_INSTALLER"

        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    printf '%bhomebrew is already installed%b\n' "$GREEN" "$NC"

    # install coreutils if it's not installed
    if ! [ -x "$(command -v greadlink)" ]; then
        printf '%s\n' "Installing coreutils..."
        brew install coreutils
    fi
    printf '%bcoreutils is already installed%b\n' "$GREEN" "$NC"

    # install jump if it's not installed
    if ! [ -x "$(command -v jump)" ]; then
        printf '%s\n' "Installing jump..."
        brew install jump
    fi
    printf '%bjump is already installed%b\n' "$GREEN" "$NC"

    ;;
"$LINUX")
    # install jump if it's not installed
    if ! [ -x "$(command -v jump)" ]; then
        case $DISTRO_NAME in
        "$ARCH")
            paru -S --noconfirm jump
            ;;
        "$UBUNTU" | "$DEBIAN")
            JUMP_ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
            JUMP_VERSION=$(curl -fsSL https://api.github.com/repos/gsamokovarov/jump/releases/latest 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
            if [ -z "$JUMP_VERSION" ]; then
                printf '%b%s%b\n' "$WARNING" "Failed to fetch latest jump version, falling back to v0.67.0" "$NC"
                JUMP_VERSION="0.67.0"
            fi
            JUMP_DEB=$(mktemp --suffix=.deb)
            if wget -O "$JUMP_DEB" "https://github.com/gsamokovarov/jump/releases/download/v${JUMP_VERSION}/jump_${JUMP_VERSION}_${JUMP_ARCH}.deb"; then
                sudo dpkg -i "$JUMP_DEB"
            else
                printf '%b%s%b\n' "$WARNING" "Failed to download jump .deb package" "$NC"
            fi
            rm -f "$JUMP_DEB"
            ;;
        esac
    fi
    printf '%bjump is already installed%b\n' "$GREEN" "$NC"
    ;;
*) ;;
esac
# ==================================================================================================

# ===> Install Fonts ===============================================================================
# download and install font if it's not installed: Meslo & Fira Code
case $OS_NAME in
"$MACOS")
    printf '%s\n' "Installing JetBrainsMono Font..."
    brew install --cask font-jetbrains-mono-nerd-font
    brew install --cask font-jetbrains-mono
    printf '%bfont \"JetBrainsMono Font\" is already installed%b\n' "$GREEN" "$NC"
    ;;
"$LINUX")
    case $DISTRO_NAME in
    "$ARCH")
        paru -S --noconfirm ttf-jetbrains-mono-nerd
        paru -S --noconfirm ttf-meslo-nerd
        ;;
    *)
        printf '%b%s%b\n' "$WARNING" "Currently we only support install fonts for Arch Linux.\nPlease visit https://github.com/ryanoasis/nerd-fonts to install fonts." "$NC"
        ;;
    esac
    ;;
*) ;;
esac
# ==================================================================================================

# ===> Install kitty ===============================================================================
if [ "$USE_KITTY" = "y" ]; then
    case $OS_NAME in
    "$MACOS")
        if ! [ -x "$(command -v kitty)" ]; then
            printf '%s\n' "Installing kitty..."
            brew install --cask kitty
        fi
        printf '%bkitty is already installed%b\n' "$GREEN" "$NC"
        ;;
    "$LINUX")
        if ! [ -x "$(command -v kitty)" ]; then
            case $DISTRO_NAME in
            "$ARCH")
                paru -S --noconfirm kitty
                ;;
            *)
                printf '%b%s%b\n' "$WARNING" "Currently we only support install kitty terminal for Arch Linux.\nPlease visit https://github.com/kovidgoyal/kitty to install kitty." "$NC"
                ;;
            esac
        fi
        printf '%bkitty is already installed%b\n' "$GREEN" "$NC"
        ;;
    *) ;;
    esac
fi
# ==================================================================================================

# ===> Install tmux ================================================================================
if [ "$USE_TMUX" = "y" ]; then
    case $OS_NAME in
    "$MACOS")
        if ! [ -x "$(command -v tmux)" ]; then
            printf '%s\n' "Installing tmux..."
            brew install tmux
        fi
        printf '%btmux is already installed%b\n' "$GREEN" "$NC"
        ;;
    "$LINUX")
        if ! [ -x "$(command -v tmux)" ]; then
            case $DISTRO_NAME in
            "$ARCH")
                paru -S --noconfirm tmux
                ;;
            "$UBUNTU" | "$DEBIAN")
                sudo apt update && sudo apt -y install tmux
                ;;
            *)
                printf '%b%s%b\n' "$WARNING" "Unsupported distro for automatic tmux install.\nPlease install tmux manually (https://github.com/tmux/tmux/wiki/Installing)." "$NC"
                ;;
            esac
        fi
        printf '%btmux is already installed%b\n' "$GREEN" "$NC"
        ;;
    *) ;;
    esac
fi
# ==================================================================================================

# ===> Setup zsh ===================================================================================
# install zsh if it's not installed
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

# set zsh as default shell if not
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

# ===> Clone and setup =============================================================================
mkdir -p "$HOME/projects/personal"
cd "$HOME/projects/personal" || exit 1

if [ -d "$HOME/projects/personal/dotfiles" ]; then
    printf '%bThe dotfiles repo is already cloned%b\n' "$GREEN" "$NC"
else
    printf '%s\n' "Cloning dotfiles..."
    # check if git ssh key is setup
    if [ -f "$HOME/.ssh/id_rsa" ] || [ -f "$HOME/.ssh/id_ed25519" ]; then
        git clone "git@github.com:$REPO.git" || (printf '\n%s\n' "Failed to clone the repo via ssh, try https.." && git clone "https://github.com/$REPO.git")
    else
        git clone "https://github.com/$REPO.git"
    fi
fi

cd dotfiles || exit 1

printf '\n'

SETUP_TERMINAL_ARGS=()

if [ "$USE_KITTY" = "y" ]; then
    printf '%s\n' "Use Kitty as terminal..."
    SETUP_TERMINAL_ARGS+=("--kitty")
fi

if [ "$USE_TMUX" = "y" ]; then
    printf '%s\n' "Use tmux as terminal multiplexer..."
    SETUP_TERMINAL_ARGS+=("--tmux")
fi

SETUP_EDITOR_ARGS=()

if [ "$USE_NVIM" = "y" ]; then
    printf '%s\n' "Use Neovim as editor..."
    SETUP_EDITOR_ARGS+=("--nvim")
fi

./setup-dotfiles.sh

printf '\n'

if ((${#SETUP_TERMINAL_ARGS[@]} > 0)); then
    ./setup-terminal.sh "${SETUP_TERMINAL_ARGS[@]}"
    printf '\n'
else
    printf '%b%s%b\n' "$WARNING" "Skipping seting up terminal..." "$NC"
fi

if ((${#SETUP_EDITOR_ARGS[@]} > 0)); then
    ./setup-editor.sh "${SETUP_EDITOR_ARGS[@]}"
    printf '\n'
else
    printf '%b%s%b\n' "$WARNING" "Skipping seting up editor..." "$NC"
fi

if [ "$USE_HYPR" = "y" ]; then
    ./setup-arch.sh
    printf '\n'
fi
