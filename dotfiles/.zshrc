#!/usr/bin/env zsh

# ==================================================================================================

# Name:         .zshrc
# Description:   zsh configuration for macOS, Ubuntu/Debian, and WSL

# ==================================================================================================

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# See https://github.com/foxundermoon/vs-shell-format/issues/336
if [ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh" ]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
fi

# ===> Set zsh history =============================================================================
# --- History Config ---
HISTFILE="$HOME/.zsh_history"

# Define the number of commands to keep in memory
HISTSIZE=10000

# Define the number of commands to keep in the file
SAVEHIST=10000

# --- History Options ---
# Append to the file after each command, instead of writing at the end of the shell (to prevent loss)
setopt APPEND_HISTORY

# Share history records in real time between multiple terminal windows (very useful for Hyprland + Kitty multi-window)
setopt SHARE_HISTORY

# Ignore duplicate commands
setopt HIST_IGNORE_DUPS

# Ignore commands that start with a blank key (sensitive commands that you don't want to record can be prefixed with a blank)
setopt HIST_IGNORE_SPACE

# Remove extra spaces
setopt HIST_REDUCE_BLANKS
# ==================================================================================================

# ===> Load .zprofile ==============================================================================
# Source .zprofile for non-login shells to load environment variables and helper functions
[[ -f $HOME/.zprofile ]] && source $HOME/.zprofile
# ==================================================================================================

# ===> Dotfiles Cache ========================================================================
DOTFILES_CACHE="$HOME/.dotfiles-cache"
# ==================================================================================================

# ===> Colors ======================================================================================
export COLORTERM="truecolor"

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
NC="\033[0m"
# ==================================================================================================

# ===> Detect OS and Shell =========================================================================

MS="Microsoft"
UBUNTU="Ubuntu"
DEBIAN="Debian"
RHEL="RedHatEnterpriseServer"
ARCH="Arch"
LINUX="Linux"
MACOS="macOS"

ARM64="arm64"
X86_64="x86_64"

ZSH_SHELL_NAME="-zsh"

PROC_VERSION_PATH="/proc/version"

if [ -f $PROC_VERSION_PATH ]; then
    PROC_VERSION=$(cat $PROC_VERSION_PATH)
    if echo "$PROC_VERSION" | grep -iqF $MS; then
        SYS_IS_WSL=YES
    fi
fi

case $(uname) in
    Darwin)
        OS_NAME=$MACOS

        case $(uname -m) in

            $ARM64)
                PROCESSOR_ARCHITECTURE=$ARM64
                ;;
            $X86_64)
                PROCESSOR_ARCHITECTURE=$X86_64
                ;;
        esac
        ;;

    Linux)
        OS_NAME=$LINUX
        OS_INFO=$(lsb_release -a 2>/dev/null)

        case $OS_INFO in
            *"$UBUNTU"*)
                DISTRO_NAME=$UBUNTU
                ;;
            *"$DEBIAN"*)
                DISTRO_NAME=$DEBIAN
                ;;
            *"$RHEL"*)
                DISTRO_NAME=$RHEL
                ;;
            *"$ARCH"*)
                DISTRO_NAME=$ARCH
                ;;
        esac
        ;;
esac
# ==================================================================================================

# ===> Detect Terminal App =========================================================================
TERMINAL_APP=""
ITERM="iTerm.app"
APPLE_TERMINAL="Apple_Terminal"
ALACRITTY="alacritty"

case $OS_NAME in
    "$MACOS")
        case $TERM_PROGRAM in
            $ITERM)
                TERMINAL_APP=$ITERM
                ;;
            $APPLE_TERMINAL)
                TERMINAL_APP=$APPLE_TERMINAL
                ;;
            $ALACRITTY)
                TERMINAL_APP=$ALACRITTY
                ;;
        esac
        ;;
    "$LINUX")
        case $TERM_PROGRAM in
            $ALACRITTY)
                TERMINAL_APP=$ALACRITTY
                ;;
        esac
        ;;
esac
# ==================================================================================================

# ===> Language Configuration (Optional) ===========================================================
# --------------------------------------------------------------------------------------------------
# -------> Set All to Traditional Chinese (Taiwan) -------------------------------------------------
# export LC_ALL="zh_TW.UTF-8" # sudo locale-gen zh_TW.UTF-8

# -------> Set All to English (United States) ------------------------------------------------------
# export LC_ALL="en_US.UTF-8" # sudo locale-gen en_US.UTF-8

# -------> Set By Details --------------------------------------------------------------------------
# Run `locale` to see the details of language configs

export LANGUAGE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
# export LANG="zh_TW.UTF-8"
export LC_CTYPE="en_US.UTF-8"
# export LC_CTYPE="zh_TW.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
# export LC_MESSAGES="zh_TW.UTF-8"
# ==================================================================================================

# ===> Bind Keys ===================================================================================
case $OS_NAME in
    "$MACOS")
        case $TERMINAL_APP in
            "$ALACRITTY")
                bindkey '^[[1;9D' beginning-of-line
                bindkey '^[[1;9C' end-of-line
                bindkey '^B' backward-word
                bindkey '^F' forward-word
                ;;
        esac
        ;;
    "$LINUX")
        # Keybindings for Home and End
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line
        bindkey "^[[3~" delete-char
        ;;
esac

# Bind keys for history-substring-search
# See: https://github.com/zsh-users/zsh-history-substring-search/issues/110#issuecomment-650832313
function _bind_keys_for_history_substring_search() {
    case $OS_NAME in
        "$MACOS")
            bindkey '^[[A' history-substring-search-up
            bindkey '^[[B' history-substring-search-down
            ;;
        "$LINUX")
            # https://superuser.com/a/1296543
            # key dict is defined in /etc/zsh/zshrc
            if (( ${+key} )); then
                bindkey "$key[Up]" history-substring-search-up
                bindkey "$key[Down]" history-substring-search-down
            else
                bindkey '^[[A' history-substring-search-up
                bindkey '^[[B' history-substring-search-down
                bindkey '^[OA' history-substring-search-up
                bindkey '^[OB' history-substring-search-down
            fi
            ;;
    esac
}
# ==================================================================================================

# ===> LinuxBrew ===================================================================================
if [ $OS_NAME = "$LINUX" ] && [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
# ==================================================================================================


# ===> Python ======================================================================================
# --------> pyenv ----------------------------------------------------------------------------------
# to install pyenv run the following command
# curl https://pyenv.run | bash
# export PYENV_ROOT="$HOME/.pyenv"
# addToPATH "$PYENV_ROOT/bin"

# init pyenv if pyenv is installed
# if [ -d "$PYENV_ROOT/bin" ]; then
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"
# fi
# ==================================================================================================

# ===> Deno (Optional) =============================================================================
# if [ -f "$HOME/.deno/env" ]; then
#     . "$HOME/.deno/env"
# fi
# ==================================================================================================

# ===> Add custom completions to FPATH and Generate Scripts ========================================
ZSH_COMPLETIONS_DIR="${HOME}/.zsh/completions"
if [[ ! -d "$ZSH_COMPLETIONS_DIR" ]]; then
    mkdir -p "$ZSH_COMPLETIONS_DIR"
fi

if [[ ":$FPATH:" != *":${ZSH_COMPLETIONS_DIR}:"* ]]; then
    export FPATH="${ZSH_COMPLETIONS_DIR}:$FPATH"
fi

if command -v uv &>/dev/null && [[ ! -f "${ZSH_COMPLETIONS_DIR}/_uv" ]]; then
    uv generate-shell-completion zsh >"${ZSH_COMPLETIONS_DIR}/_uv"
fi

if command -v uvx &>/dev/null && [[ ! -f "${ZSH_COMPLETIONS_DIR}/_uvx" ]]; then
    uvx --generate-shell-completion zsh >"${ZSH_COMPLETIONS_DIR}/_uvx"
fi

if command -v proto &>/dev/null && [[ ! -f "${ZSH_COMPLETIONS_DIR}/_proto" ]]; then
    proto completions >"${ZSH_COMPLETIONS_DIR}/_proto"
fi

if command -v moon &>/dev/null && [[ ! -f "${ZSH_COMPLETIONS_DIR}/_moon" ]]; then
    moon completions >"${ZSH_COMPLETIONS_DIR}/_moon"
fi
# ==================================================================================================

# ===> Zsh Completion Options ======================================================================
# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Partial completion suggestions
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix
# ==================================================================================================

# ===> Zinit & Prezto ==============================================================================
# See: https://github.com/zdharma-continuum/zinit

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Load Prezto
zi snippet PZT::modules/helper/init.zsh

# Load Prezto modules
zi ice wait'!' blockf \
    atclone"git clone -q --depth=1 https://github.com/sorin-ionescu/prezto.git external"
zi snippet PZTM::git/alias.zsh
zi ice wait'!' blockf \
    atclone"git clone -q --depth=1 https://github.com/sorin-ionescu/prezto.git external"
zi snippet PZTM::git

zi ice wait'!'
zi snippet PZT::modules/gnu-utility

zi ice wait'!'
zi snippet PZT::modules/utility

zi ice wait'!'
zi snippet PZT::modules/python

zi ice wait'!' lucid \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay"
zi load zdharma-continuum/fast-syntax-highlighting

# Poetry completion setup
# only runs when poetry is installed
if command -v poetry &>/dev/null; then
    zi ice wait'!' lucid as"completion" id-as"poetry-completion" \
        atclone"poetry completions zsh > _poetry" \
        atpull"%atclone" \
        run-atpull \
        pick"_poetry" \
        nocompile
    zi light zdharma-continuum/null
fi

zi ice wait'!' lucid blockf
zi load zsh-users/zsh-completions

zi ice wait'!' lucid atload"!_bind_keys_for_history_substring_search"
zi load zsh-users/zsh-history-substring-search

zi ice wait'!' lucid atload"!_zsh_autosuggest_start"
zi load zsh-users/zsh-autosuggestions

# Load the theme
zi ice depth=1
zi light romkatv/powerlevel10k

zi snippet PZT::modules/prompt

# Manually load the configuration file of Prezto
source ${ZDOTDIR:-$HOME}/.zpreztorc
# ==================================================================================================

# ===> Proto =======================================================================================
# Proto is a pluggable multi-language version manager
# See: https://moonrepo.dev/docs/proto

export PROTO_HOME="$HOME/.proto"

# Install proto if not already installed
if [ ! -d "$PROTO_HOME" ]; then
    echo "Installing proto..."
    bash <(curl -fsSL https://moonrepo.dev/install/proto.sh) --yes
fi

# Add proto to PATH
addToPATH "$PROTO_HOME/shims:$PROTO_HOME/bin"

# Load proto completions if available
if command -v proto &>/dev/null; then
    # Proto uses WASM plugins and supports legacy version files (.nvmrc, .tool-versions)
    # by default, so no additional configuration is needed
    :
fi
# ==================================================================================================

# ===> Kubernetes ==================================================================================
export KUBECONFIG=~/.kube/config
# ==================================================================================================

# ===> Base Directory of Projects ==================================================================
PROJS_BASE=$HOME/projects
[ ! -d "$PROJS_BASE" ] && mkdir -p "$PROJS_BASE"
[ ! -d "$PROJS_BASE/work" ] && mkdir -p "$PROJS_BASE/work"
[ ! -d "$PROJS_BASE/personal" ] && mkdir -p "$PROJS_BASE/personal"
[ ! -d "$PROJS_BASE/libs" ] && mkdir -p "$PROJS_BASE/libs"
# ==================================================================================================

# ===> Alias: Editor ===============================================================================
# VSCode (Setup required)
# https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line
alias edit='code' # VSCode

# alias edit='vim'
# alias vi='vim'
# ==================================================================================================

# ===> Alias: Basic Command ========================================================================
alias ls='echo && ls -hF --color=always'
alias ll='ls -l --time-style=long-iso --group-directories-first'
alias la='ll -a'
alias cp='cp -iv'
alias mv='mv -iv'
alias ln='ln -iv'
alias rm='rm -I -v --preserve-root'
alias mkdir='mkdir -pv'
alias ssh='ssh -v -tt -A' # Use '-vvv' for top-level verbose
alias ping='ping -c 5'
alias sudo='nocorrect sudo '
# ==================================================================================================

# ===> Functions: Shortcut =========================================================================
cl() {
    cd "$1" && la
}

home() {
    cl "$HOME"
    printf "\nWelcome home!\n\n"
}

gow() {
    cl "$PROJS_BASE/work"
    printf "\nOK, ready to work :)\n\n"
}

gop() {
    cl "$PROJS_BASE/personal"
    printf "\nOK, ready to do something amazing :)\n\n"
}

gol() {
    cl "$PROJS_BASE/libs"
    printf "\nHere are the third-party libraries :)\n\n"
}

code-wsl() {
    if [ $# -eq 0 ]; then
        code --folder-uri "vscode-remote://wsl+${WSL_DISTRO_NAME}${PWD}"
    elif [ $# -eq 1 ] && [ "$1" = "." ]; then
        code --folder-uri "vscode-remote://wsl+${WSL_DISTRO_NAME}${PWD}"
    else
        code "$@"
    fi
}

if command -v neovide &>/dev/null; then
    alias nd='neovide --fork'
fi

if command -v nvim &>/dev/null; then
    nv() {
        for arg in "$@"; do
            case "$arg" in
                --help|-h|--version|-v)
                    nvim "$@"
                    return
                    ;;
            esac
        done

        if [[ "$OS_NAME" == "$MACOS" ]]; then
            kitty --title="Neovim" --directory="$PWD" -e nvim "$@" > /dev/null 2>&1 &
        else
            kitty --class="neovim" --title="Neovim" -e nvim "$@" > /dev/null 2>&1 &!
        fi
    }
fi

if command -v yazi &>/dev/null; then
    function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        IFS= read -r -d '' cwd < "$tmp"
        [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
        rm -f -- "$tmp"
    }
fi

if [ $SYS_IS_WSL ]; then
    # go to Windows Disk C
    win() {
        cd "/mnt/c" || exit
        printf "\nOK, you are now in disk: C!\n"
    }
    # open with Windows Explorer
    open() {
        explorer.exe "$1"
    }
    alias code=code-wsl
    alias cursor=code-wsl
fi

# ==================================================================================================

# ===> Alias: Update & Upgrade Packages ============================================================
case $OS_NAME in
    "$MACOS")
        unu() {
            brew update -v && brew upgrade -v
        }
        ;;
    "$LINUX")
        case $DISTRO_NAME in
            "$RHEL") ;;
            "$ARCH")
                unu() {
                    if command -v paru &>/dev/null; then
                        paru -Syu
                    else
                        sudo pacman -Syu
                    fi
                }
                ;;
            "$UBUNTU") ;;
            "$DEBIAN")
                unu() {
                    sudo apt-get update && sudo apt-get upgrade
                }
                ;;
        esac
        ;;
esac
# ==================================================================================================

# ===> Alias: Shortcut =============================================================================
alias c='clear'
alias edit-rc='edit $HOME/.zshrc'
alias cddf="cd $PROJS_BASE/personal/dotfiles"
alias edit-ssh='edit $HOME/.ssh/config'
alias source-rc='source $HOME/.zshrc'
alias paths='echo && echo -e ${PATH//:/\\n}'
alias weather='curl wttr.in && echo && curl v2.wttr.in'
alias ai="aichat -e" # https://github.com/sigoden/aichat

# --------> Git shortcuts --------------------------------------------------------------------------
# https://kapeli.com/cheat_sheets/Oh-My-Zsh_Git.docset/Contents/Resources/Documents/index

# Clear local branches (except main and develop)
# alias gclb='git branch | grep -v -e "main" -e "develop" | xargs git branch -D'
alias gclb='git branch \
| grep -v -w main \
| grep -v -w develop \
| grep -v -e $(git rev-parse --abbrev-ref HEAD) \
| grep -v -e " release-*" \
| grep -v -e " release/*" \
>/tmp/branches-to-clean && vim /tmp/branches-to-clean && xargs git branch -D </tmp/branches-to-clean'

alias gclmb='git branch --merged \
| grep -v -w main \
| grep -v -w develop \
| grep -v -e $(git rev-parse --abbrev-ref HEAD) \
| grep -v -e " release-*" \
| grep -v -e " release/*" \
>/tmp/merged-branches && vim /tmp/merged-branches && xargs git branch -d </tmp/merged-branches'

alias gfap='gfa && git pull'
alias gfapr='gfa && git pull --rebase'
alias gpuoc='git push -u origin $(git branch --show-current)'
# --------------------------------------------------------------------------------------------------

case $OS_NAME in
    "$MACOS") ;;
    "$LINUX")
        alias ffind='find * -type f | fzf' # sudo apt-get -y install fzf
        alias monitor='gotop -r 1s -a -s'  # https://github.com/xxxserxxx/gotop

        if command -v waydroid &>/dev/null; then
            # use system python path for waydroid
            alias waydroid='env PATH=/usr/bin:$PATH waydroid'
        fi

        if command -v paru &>/dev/null; then
            # use system python path for paru
            alias paru='env PATH=/usr/bin:$PATH paru'
        fi

        if command -v hyprpanel &>/dev/null; then
            # use system python path for hyprpanel
            alias hyprpanel='env PATH=/usr/bin:$PATH hyprpanel'
        fi

        case $DISTRO_NAME in
            "$RHEL") ;;
            *)
                # sudo apt-get -y install ncdu
                alias mand='sudo ncdu --exclude /mnt -e --color=dark /'
                ;;
        esac
        ;;
esac

# --------> List all ports -------------------------------------------------------------------------
case $OS_NAME in
    "$MACOS")
        alias ports='sudo lsof -iTCP -sTCP:LISTEN -n -P'
        ;;
    "$LINUX")
        if [ -x "$(command -v netstat)" ]; then
            alias ports='netstat -tulanp'
        else
            case $DISTRO_NAME in
                "$RHEL") ;;
                *)
                    echo "net-tools is not installed, please install it first."
                    ;;
            esac
        fi
        ;;
esac
# ==================================================================================================

# ===> Docker (Optional) ===========================================================================
alias docker-all='docker ps -a --format "{{.Names}} ({{.ID}}): {{.Image}} ({{.Ports}})"'
alias docker-ls='docker ps --format "{{.Names}} ({{.ID}}): {{.Image}} ({{.Ports}})"'
# ==================================================================================================

# ===> Git (Optional) ==============================================================================
# --------> Global Configuration -------------------------------------------------------------------
if command -v nvim &>/dev/null; then
    GIT_EDITOR="nvim"
    EDITOR="nvim"
elif command -v code &>/dev/null; then
    GIT_EDITOR="code"
    EDITOR="code"
elif command -v vim &>/dev/null; then
    GIT_EDITOR="vim"
    EDITOR="vim"
else
    GIT_EDITOR="vi"
    EDITOR="vi"
fi

export EDITOR

git config --global pull.ff only              # set git pull --ff-only
git config --global init.defaultBranch main   # set default init branch
git config --global core.editor "$GIT_EDITOR" # set default editor
# ==================================================================================================

# ===> Google Cloud (Optional) =====================================================================
# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
# ==================================================================================================

# ===> Check Git Version ===========================================================================
function check_git_version() {
    local LAST_CHECK_TIME=0
    local LAST_CHECK_FILE="${DOTFILES_CACHE}/.git_last_check"

    local CHECK_INTERVAL_DAYS=1
    local CHECK_INTERVAL=$((60 * 60 * 24 * ${CHECK_INTERVAL_DAYS})) # 60s * 60m * 24h * n days

    local CURRENT_TIME=$(date +%s)

    local SHOULD_FIRST_CHECK=NO

    if [[ -f $LAST_CHECK_FILE ]]; then
        LAST_CHECK_TIME=$(cat $LAST_CHECK_FILE)
    else
        mkdir -p ${DOTFILES_CACHE} >/dev/null 2>&1
        SHOULD_FIRST_CHECK=YES
    fi

    if [[ $((CURRENT_TIME - LAST_CHECK_TIME)) -gt ${CHECK_INTERVAL} || ${SHOULD_FIRST_CHECK} == 'YES' ]]; then
        echo -e "\nChecking Git version..."

        local LOCAL_GIT_VERSION=$(command git --version | cut -d ' ' -f 3)
        local LATEST_GIT_VERSION=$(curl --silent https://mirrors.edge.kernel.org/pub/software/scm/git/ | grep tar | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort --version-sort | tail -1)

        if [[ $(echo "$LOCAL_GIT_VERSION $LATEST_GIT_VERSION" | tr ' ' '\n' | sort -Vr | head -n 1) != "$LOCAL_GIT_VERSION" ]]; then
            echo -e "New version of Git is available! ${RED}${LOCAL_GIT_VERSION}${NC} → ${GREEN}${LATEST_GIT_VERSION}${NC}"
            echo -e "Run the command: ${BLUE}update_git${NC} to update it."
        else
            echo -e "Your current Git version ${GREEN}${LOCAL_GIT_VERSION}${NC} is up to date."
        fi

        echo

        echo ${CURRENT_TIME} >${LAST_CHECK_FILE}
    fi
}
# ==================================================================================================

# ===> Rust ========================================================================================
if [ -d $HOME/.cargo/bin ]; then
    addToPATH $HOME/.cargo/bin
fi

function cargo() {
    local LAST_CHECK_TIME=0
    local LAST_CHECK_FILE="${DOTFILES_CACHE}/.rust_last_check"

    local CHECK_INTERVAL_DAYS=1
    local CHECK_INTERVAL=$((60 * 60 * 24 * ${CHECK_INTERVAL_DAYS})) # 60s * 60m * 24h * n days

    local CURRENT_TIME=$(date +%s)

    local SHOULD_FIRST_CHECK=NO

    if [[ -f $LAST_CHECK_FILE ]]; then
        LAST_CHECK_TIME=$(cat $LAST_CHECK_FILE)
    else
        mkdir -p ${DOTFILES_CACHE} >/dev/null 2>&1
        SHOULD_FIRST_CHECK=YES
    fi

    if [[ $((CURRENT_TIME - LAST_CHECK_TIME)) -gt ${CHECK_INTERVAL} || ${SHOULD_FIRST_CHECK} == 'YES' ]]; then
        echo -e "\nChecking Rust version..."

        local LOCAL_RUST_VERSION=$(command rustc --version | cut -d ' ' -f 2)
        local LATEST_RUST_VERSION=$(curl --silent https://github.com/rust-lang/rust/tags | grep /rust-lang/rust/releases/tag/ | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort --version-sort | tail -1)

        if [[ $(echo "$LOCAL_RUST_VERSION $LATEST_RUST_VERSION" | tr ' ' '\n' | sort -Vr | head -n 1) != "$LOCAL_RUST_VERSION" ]]; then
            echo -e "New version of Rust is available! ${RED}${LOCAL_RUST_VERSION}${NC} → ${GREEN}${LATEST_RUST_VERSION}${NC}"
            echo -e "Run the command: ${BLUE}rustup update${NC} to update it."
        else
            echo -e "Your current Rust version ${GREEN}${LOCAL_RUST_VERSION}${NC} is up to date."
        fi

        echo
    fi

    echo ${CURRENT_TIME} >${LAST_CHECK_FILE}

    command cargo "$@"
}
# ==================================================================================================

# ===> Zsh hooks ===================================================================================
# ---> Set terminal title to current directory -----------------------------------------------------

autoload -Uz add-zsh-hook

function set-title() {
    local window_title="\033]0;${PWD##*/}\007"
    echo -ne "$window_title"
}

add-zsh-hook precmd set-title
# --------------------------------------------------------------------------------------------------

# ---> Automatically activate proto environment ----------------------------------------------------
autoload -U add-zsh-hook
load-activate-proto() {
    if ! command -v proto &>/dev/null; then
        return
    fi

    if [ -f ".prototools" ] || [ -f ".nvmrc" ]; then
        eval "$(proto activate zsh)"
    fi
}
add-zsh-hook chpwd load-activate-proto
load-activate-proto
# --------------------------------------------------------------------------------------------------
# ==================================================================================================

# ===> Path Configuration ==========================================================================
typeset -U path PATH # remove duplicates in $PATH
# ==================================================================================================

# ===> Run commands before the prompt is displayed =================================================

# ---> Change directory to $HOME -------------------------------------------------------------------
if [ "$0" = "$ZSH_SHELL_NAME" ]; then # don't run when source .zshrc
    cd "$HOME" || exit
fi

# ---> Check for Git updates -----------------------------------------------------------------------
if [ "$0" = "$ZSH_SHELL_NAME" ]; then # don't run when source .zshrc
    check_git_version
fi

# ---> Load p10k configuration ---------------------------------------------------------------------
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ---> Finalize p10k -------------------------------------------------------------------------------
# original code is `(( ! ${+functions[p10k]} )) || p10k finalize`,
# but the shell-format doesn't support the syntax of zsh
if type p10k >/dev/null 2>&1; then
    p10k finalize
fi

# ==================================================================================================

# ==================================================================================================
# End of File
# ==================================================================================================

# pnpm
export PNPM_HOME="/home/salt/.pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
