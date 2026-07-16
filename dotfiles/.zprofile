OS_NAME=""
LINUX="Linux"
MACOS="macOS"

# ===> Terminal Setup Bin ==========================================================================
DOTFILES_LOCAL_BIN_DIR="$HOME/.local/dotfiles/bin"
# ==================================================================================================

case $(uname) in
    Darwin)
        OS_NAME=$MACOS
        ;;

    Linux)
        OS_NAME=$LINUX
        ;;
esac

# ===> Path ========================================================================================
# --------> Avoid repeated PATH statements ---------------------------------------------------------
addToPATH() {
    case ":$PATH:" in
        *":$1:"*) : ;;        # already there
        *) PATH="$1:$PATH" ;; # or PATH="$PATH:$1"
    esac
}

# --------> Basic Binary ---------------------------------------------------------------------------
addToPATH "/usr/bin"
addToPATH "/usr/local/bin"
addToPATH "$HOME/.local/bin"

# --------> Load bins of dotfiles ------------------------------------------------------------
addToPATH "$DOTFILES_LOCAL_BIN_DIR"

# -------> pnpm ------------------------------------------------------------------------------------
export PNPM_HOME="$HOME/.pnpm"
addToPATH "$PNPM_HOME"

# -------> bun -------------------------------------------------------------------------------------
export BUN_INSTALL="$HOME/.bun"
addToPATH "$BUN_INSTALL/bin"
# ==================================================================================================

# ===> Homebrew (macOS only) =======================================================================
case $OS_NAME in
    "$MACOS")
        eval "$(/opt/homebrew/bin/brew shellenv)"
        ;;
esac
# ==================================================================================================

# ===> Jump ========================================================================================
eval "$(jump shell zsh)"
# ==================================================================================================

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
case $OS_NAME in
    "$MACOS")
        source ~/.orbstack/shell/init.zsh 2>/dev/null || :
        ;;
esac

