#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
WARNING="\033[33m"
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
            echo -e "${WARNING}Unsupported Linux Distribution, currently we only support Arch Linux, Ubuntu, and Debian.${NC}"
        fi
    else
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
        echo "Installing paru..."
        sudo pacman -S --needed base-devel
        git clone https://aur.archlinux.org/paru.git
        cd paru || exit
        makepkg -si
    fi
    ;;
esac

# ===> Prompt User for the repo to clone ===========================================================
printf "Please enter the dotfiles github repo to clone (default: saltchang/dotfiles): \n> "
read -r REPO </dev/tty

if [ -z "$REPO" ]; then
    REPO="saltchang/dotfiles"
fi
# ==================================================================================================

# ===> Prompt User for using iTerm2 as terminal app ================================================
case $OS_NAME in
"$MACOS")
    printf "\nDo you want to use iTerm2(https://iterm2.com) as terminal app? (y/n, default: n): \n> "
    read -r USE_ITERM2 </dev/tty

    if [ -z "$USE_ITERM2" ]; then
        USE_ITERM2="n"
    fi
    ;;
esac
# ==================================================================================================

# ===> Prompt User for using kitty as terminal app =================================================
if [ "$USE_ITERM2" != "y" ]; then
    printf "\nDo you want to use Kitty(https://sw.kovidgoyal.net/kitty/) as terminal app? (y/n, default: y): \n> "
    read -r USE_KITTY </dev/tty

    if [ -z "$USE_KITTY" ]; then
        USE_KITTY="y"
    fi
fi
# ==================================================================================================

# ===> Prompt User for using ghostty as terminal app ===============================================
if [ "$USE_ITERM2" != "y" ] && [ "$USE_KITTY" != "y" ]; then
    printf "\nDo you want to use Ghostty(https://ghostty.org) as terminal app? (y/n, default: y): \n> "
    read -r USE_GHOSTTY </dev/tty

    if [ -z "$USE_GHOSTTY" ]; then
        USE_GHOSTTY="y"
    fi
fi
# ==================================================================================================

# ===> Prompt User for setup Neovim config =========================================================
printf "\nDo you want to setup Neovim(https://neovim.io) config? (y/n, default: y): \n> "
read -r USE_NVIM </dev/tty

if [ -z "$USE_NVIM" ]; then
    USE_NVIM="y"
fi
# ==================================================================================================

# ===> Prompt User for setup Zed config =========================================================
printf "\nDo you want to setup Zed(https://zed.dev) config? (y/n, default: y): \n> "
read -r USE_ZED </dev/tty

if [ -z "$USE_ZED" ]; then
    USE_ZED="y"
fi
# ==================================================================================================

# Hyprland eco for Arch Linux
case $DISTRO_NAME in
"$ARCH")
    printf "\nDo you want to setup hyprland, hyprpanel, rofi, and swappy? (y/n, default: y): \n> "
    read -r USE_HYPR </dev/tty

    if [ -z "$USE_HYPR" ]; then
        USE_HYPR="y"
    fi
    ;;
esac

echo
echo "Check and install necessary stuffs..."
echo

# ===> Basic Setup By System =======================================================================
case $OS_NAME in
"$MACOS")
    if ! [ -x "$(command -v brew)" ]; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo -e "${GREEN}homebrew is already installed${NC}"

    # install coreutils if it's not installed
    if ! [ -x "$(command -v greadlink)" ]; then
        echo "Installing coreutils..."
        brew install coreutils
    fi
    echo -e "${GREEN}coreutils is already installed${NC}"

    # install jump if it's not installed
    if ! [ -x "$(command -v jump)" ]; then
        echo "Installing jump..."
        brew install jump
    fi
    echo -e "${GREEN}jump is already installed${NC}"

    # install python3 if it's not installed via homebrew
    BREW_PYTHON_PATH=$(brew --prefix python3 2>/dev/null)
    if ! [ -x "$(command -v python3)" ] || [ -z "$BREW_PYTHON_PATH" ]; then
        echo "Installing python3..."
        brew install python3
    fi
    echo -e "${GREEN}python3 is already installed via homebrew${NC}"
    ;;
"$LINUX")
    # install jump if it's not installed
    if ! [ -x "$(command -v jump)" ]; then
        case $DISTRO_NAME in
        "$ARCH")
            paru -S jump
            ;;
        "$UBUNTU" | "$DEBIAN")
            wget https://github.com/gsamokovarov/jump/releases/download/v0.67.0/jump_0.67.0_amd64.deb && sudo dpkg -i jump_0.67.0_amd64.deb
            ;;
        esac
    fi
    echo -e "${GREEN}jump is already installed${NC}"
    ;;
*) ;;
esac
# ==================================================================================================

# ===> Install Fonts ===============================================================================
# download and install font if it's not installed: Meslo & Fira Code
case $OS_NAME in
"$MACOS")
    if ! [ -f "/Library/Fonts/MesloLGLNerdFont-Regular.ttf" ]; then
        echo "Installing Meslo..."
        curl -s -L -o /tmp/Meslo.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip
        unzip /tmp/Meslo.zip -d /tmp/Meslo
        cp /tmp/Meslo/*.ttf /Library/Fonts
    fi
    echo -e "${GREEN}font \"Meslo\" is already installed${NC}"

    if ! [ -f "/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf" ]; then
        curl -s -L -o /tmp/JetBrainsMono.zip https://github.com/tonsky/FiraCode/releases/latest/download/JetBrainsMono.zip
        unzip /tmp/JetBrainsMono.zip -d /tmp/JetBrainsMono
        cp /tmp/JetBrainsMono/ttf/*.ttf /Library/Fonts
    fi
    echo -e "${GREEN}font \"JetBrains Mono\" is already installed${NC}"
    ;;
"$LINUX")
    case $DISTRO_NAME in
    "$ARCH")
        paru -S ttf-jetbrains-mono-nerd
        paru -S ttf-meslo-nerd
        ;;
    *)
        echo -e "${WARNING}Currently we only support install fonts for Arch Linux.\nPlease visit https://github.com/ryanoasis/nerd-fonts to install fonts.${NC}"
        ;;
    esac
    ;;
*) ;;
esac
# ==================================================================================================

# ===> Install iTerm2 ==============================================================================
if [ "$USE_ITERM2" = "y" ]; then
    case $OS_NAME in
    "$MACOS")
        ITERM2_APP_PATH=$(mdfind "kMDItemCFBundleIdentifier == com.googlecode.iterm2")
        if [ -z "$ITERM2_APP_PATH" ]; then
            echo "Installing iTerm2..."
            brew install --cask iterm2
        fi
        echo -e "${GREEN}iTerm2 is already installed${NC}"
        ;;
    *) ;;
    esac
fi
# ==================================================================================================

# ===> Install kitty ===============================================================================
if [ "$USE_KITTY" = "y" ]; then
    case $OS_NAME in
    "$MACOS")
        if ! [ -x "$(command -v kitty)" ]; then
            echo "Installing kitty..."
            brew install --cask kitty
        fi
        echo -e "${GREEN}kitty is already installed${NC}"
        ;;
    "$LINUX")
        if ! [ -x "$(command -v kitty)" ]; then
            case $DISTRO_NAME in
            "$ARCH")
                paru -S kitty
                ;;
            *)
                echo -e "${WARNING}Currently we only support install kitty terminal for Arch Linux.\nPlease visit https://github.com/kovidgoyal/kitty to install kitty.${NC}"
                ;;
            esac
        fi
        echo -e "${GREEN}kitty is already installed${NC}"
        ;;
    *) ;;
    esac
fi
# ==================================================================================================

# ===> Install ghostty =============================================================================
if [ "$USE_GHOSTTY" = "y" ]; then
    case $OS_NAME in
    "$MACOS")
        if ! [ -x "$(command -v ghostty)" ]; then
            echo "Installing ghostty..."
            brew install --cask ghostty
        fi
        echo -e "${GREEN}ghostty is already installed${NC}"
        ;;
    "$LINUX")
        if ! [ -x "$(command -v ghostty)" ]; then
            case $DISTRO_NAME in
            "$ARCH")
                paru -S ghostty
                ;;
            *)
                echo -e "${WARNING}Currently we only support install ghostty terminal for Arch Linux.\nPlease visit https://ghostty.org to install ghostty.${NC}"
                ;;
            esac
        fi
        echo -e "${GREEN}ghostty is already installed${NC}"
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
            paru -S zsh
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
echo -e "${GREEN}zsh is already installed${NC}"

# set zsh as default shell if not
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    sudo chsh -s "$(which zsh)"
fi
echo -e "${GREEN}zsh is already set as default shell${NC}"
# ==================================================================================================

# ===> Clone and setup =============================================================================
mkdir -p "$HOME/projects/personal"
cd "$HOME/projects/personal" || exit 1

if [ -d "$HOME/projects/personal/dotfiles" ]; then
    echo -e "${GREEN}The dotfiles repo is already cloned${NC}"
else
    echo "Cloning dotfiles..."
    # check if git ssh key is setup
    if [ -f "$HOME/.ssh/id_rsa" ] || [ -f "$HOME/.ssh/id_ed25519" ]; then
        git clone "git@github.com:$REPO.git" || (echo -e "\nFailed to clone the repo via ssh, try https..\n" && git clone "https://github.com/$REPO.git")
    else
        git clone "https://github.com/$REPO.git"
    fi
fi

cd dotfiles || exit 1

echo

SETUP_TERMINAL_ARGS=()

if [ "$USE_KITTY" = "y" ]; then
    echo "Use Kitty as terminal..."
    SETUP_TERMINAL_ARGS+=("--kitty")
fi

if [ "$USE_GHOSTTY" = "y" ]; then
    echo "Use Ghostty as terminal..."
    SETUP_TERMINAL_ARGS+=("--ghostty")
fi

if [ "$USE_ITERM2" = "y" ]; then
    echo "Use iTerm2 as terminal..."
    SETUP_TERMINAL_ARGS+=("--iterm2")
fi

SETUP_EDITOR_ARGS=()

if [ "$USE_NVIM" = "y" ]; then
    echo "Use Neovim as editor..."
    SETUP_EDITOR_ARGS+=("--nvim")
fi

if [ "$USE_ZED" = "y" ]; then
    echo "Use Zed as editor..."
    SETUP_EDITOR_ARGS+=("--zed")
fi

./setup-zsh.sh

echo

if ((${#SETUP_TERMINAL_ARGS[@]} > 0)); then
    ./setup-terminal.sh "${SETUP_TERMINAL_ARGS[@]}"
    echo
else
    echo -e "${WARNING}Skipping seting up terminal...${NC}"
fi

if ((${#SETUP_EDITOR_ARGS[@]} > 0)); then
    ./setup-editor.sh "${SETUP_EDITOR_ARGS[@]}"
    echo
else
    echo -e "${WARNING}Skipping seting up editor...${NC}"
fi

if [ "$USE_HYPR" = "y" ]; then
    ./setup-arch.sh
    echo
fi
