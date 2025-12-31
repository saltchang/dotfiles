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

# ===> SSH Agent (Optional) ========================================================================
SSH_KEY_FILE=$HOME/.ssh/id_ed25519

if ! [ "$(eval 'ps ax | grep "[s]sh-agent" | wc -l' 2>/dev/null)" -gt 0 ]; then
    eval "$(ssh-agent -s)"
    if [[ "$(ssh-add -l)" == "The agent has no identities." ]]; then
        ssh-add "$SSH_KEY_FILE"
    fi
    # Kill it on exit. You may not want this part.
    # trap "ssh-agent -k" EXIT
fi
# ==================================================================================================

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
case $OS_NAME in
"$MACOS")
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
    ;;
esac
