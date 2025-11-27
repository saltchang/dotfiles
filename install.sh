#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
WARNING="\033[33m"
NC="\033[0m"
# ==================================================================================================

OS_NAME=""
LINUX="Linux"
MACOS="macOS"

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
    if ! command -v lsb_release &> /dev/null; then
        echo
        echo -e "${WARNING}Error: lsb_release command not found!${NC}"
        echo
        echo "lsb_release is required for detecting your Linux distribution."
        echo "Please install it first:"
        echo
        echo "  Arch Linux:       sudo pacman -S lsb-release"
        echo "  Debian/Ubuntu:    sudo apt-get install lsb-release"
        echo "  RHEL/CentOS:      sudo yum install redhat-lsb-core"
        echo "  Fedora:           sudo dnf install redhat-lsb-core"
        echo
        exit 1
    fi
    ;;
esac
# ==================================================================================================


# ===> Prompt User for the repo to clone ===========================================================
printf "Please enter the terminal-setup github repo to clone (default: saltchang/terminal-setup): \n> "
read -r REPO </dev/tty

if [ -z "$REPO" ]; then
    REPO="saltchang/terminal-setup"
fi
# ==================================================================================================

# ===> Prompt User for installing Pnpm =============================================================
printf "\nDo you want to install pnpm(https://pnpm.io)? (y/n, default: y): \n> "
read -r INSTALL_PNPM </dev/tty

if [ -z "$INSTALL_PNPM" ]; then
    INSTALL_PNPM="y"
fi
# ==================================================================================================

# ===> Prompt User for using iTerm2 as terminal app ================================================
case $OS_NAME in
"$MACOS")
    printf "\nDo you want to use iTerm2(https://iterm2.com) as terminal app? (y/n, default: y): \n> "
    read -r USE_ITERM2 </dev/tty

    if [ -z "$USE_ITERM2" ]; then
        USE_ITERM2="y"
    fi
    ;;
esac
# ==================================================================================================

# ===> Prompt User for using kitty as terminal app ================================================
if [ "$USE_ITERM2" != "y" ]; then
    printf "\nDo you want to use Kitty(https://sw.kovidgoyal.net/kitty/) as terminal app? (y/n, default: n): \n> "
    read -r USE_KITTY </dev/tty

    if [ -z "$USE_KITTY" ]; then
        USE_KITTY="n"
    fi
fi
# ==================================================================================================

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

    # install pipx if it's not installed
    if ! [ -x "$(command -v pipx)" ]; then
        echo "Installing pipx..."
        brew install pipx
    fi
    echo -e "${GREEN}pipx is already installed${NC}"
    ;;
"$LINUX")
    # install jump if it's not installed
    if ! [ -x "$(command -v jump)" ]; then
        if ! [ -x "$(command -v snap)" ]; then
            echo -e "${WARNING}snap is not installed, skip installing jump.${NC}"
            echo -e "${WARNING}You can install it from https://github.com/gsamokovarov/jump?tab=readme-ov-file#installation${NC}"
        fi

        sudo snap install jump
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
        curl -s -L -o /tmp/Meslo.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip
        unzip /tmp/Meslo.zip -d /tmp/Meslo
        cp /tmp/Meslo/*.ttf /Library/Fonts
    fi
    echo -e "${GREEN}font \"Meslo\" is already installed${NC}"

    if ! [ -f "/Library/Fonts/FiraCode-Regular.ttf" ]; then
        curl -s -L -o /tmp/FiraCode_v6.2.zip https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip
        unzip /tmp/FiraCode_v6.2.zip -d /tmp/FiraCode
        cp /tmp/FiraCode/ttf/*.ttf /Library/Fonts
    fi
    echo -e "${GREEN}font \"Fira Code\" is already installed${NC}"
    ;;
"$LINUX")
    if ! [ -f "/usr/local/share/fonts/MesloLGLNerdFont-Regular.ttf" ]; then
        curl -s -L -o /tmp/Meslo.tar.xz https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.tar.xz
        mkdir -p /tmp/Meslo
        tar xvf /tmp/Meslo.tar.xz -C /tmp/Meslo
        sudo cp /tmp/Meslo/*.ttf /usr/local/share/fonts
    fi
    echo -e "${GREEN}font \"Meslo\" is already installed${NC}"

    if ! [ -f "/usr/local/share/fonts/FiraCode-Regular.ttf" ]; then
        sudo apt install fonts-firacode
        sudo fc-cache -f -v
    fi
    echo -e "${GREEN}font \"Fira Code\" is already installed${NC}"
    ;;
*) ;;
esac
# ==================================================================================================

# ===> Install packages ============================================================================
# Install pnpm if it's not installed
if [ "$INSTALL_PNPM" = "y" ]; then
    if ! [ -x "$(command -v pnpm)" ]; then
        echo "Installing pnpm..."
        curl -fsSL https://get.pnpm.io/install.sh | sh -
    fi
    echo -e "${GREEN}pnpm is already installed${NC}"
fi
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
            echo "Installing kitty..."
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
            # Create desktop integration
            ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/
            # Place the kitty.desktop file somewhere it can be found by the OS
            cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
            # Update the paths to the kitty and its icon in the kitty.desktop file
            sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty.desktop
            sed -i "s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty.desktop
        fi
        echo -e "${GREEN}kitty is already installed${NC}"
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
        sudo apt update && sudo apt -y install zsh
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

if [ -d "$HOME/projects/personal/terminal-setup" ]; then
    echo -e "${GREEN}terminal-setup is already cloned${NC}"
else
    echo "Cloning terminal-setup..."
    # check if git ssh key is setup
    if [ -f "$HOME/.ssh/id_rsa" ] || [ -f "$HOME/.ssh/id_ed25519" ]; then
        git clone "git@github.com:$REPO.git" || (echo -e "\nFailed to clone the repo via ssh, try https..\n" && git clone "https://github.com/$REPO.git")
    else
        git clone "https://github.com/$REPO.git"
    fi
fi

cd terminal-setup || exit 1

echo

if [ "$USE_KITTY" = "y" ]; then
    ./setup.sh --setup-kitty
elif [ "$USE_ITERM2" = "y" ]; then
    ./setup.sh --setup-iterm2
else
    ./setup.sh
fi
