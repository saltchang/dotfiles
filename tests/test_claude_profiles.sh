#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
mock_bin="$(mktemp -d)"
trap 'rm -rf "$mock_bin"' EXIT
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "${CLAUDE_CONFIG_DIR-unset}" "$@"' > "$mock_bin/claude"
chmod +x "$mock_bin/claude"

zsh -f -s -- "$repo_root/dotfiles/.zshrc" "$mock_bin" <<'ZSH'
config=$(<"$1")
profiles=${config#*$'\n_claude_run()'}
eval "_claude_run()${profiles%%$'\n# ===> Functions: Shortcut'*}"
set -eu
path=("$2" $path)
PROJS_BASE="$HOME/projects"
export CLAUDE_CONFIG_DIR=/inherited/profile

check() {
    local expected=$1
    shift
    local actual=$("$@" --resume "a session" 2>/dev/null)
    if [[ $actual != "$expected"$'\n--resume\na session' ]]; then
        print -u2 -r -- "FAIL: $* in $PWD (mode=${CLAUDE_MULTI_PROFILE-unset}): $actual"
        exit 1
    fi
    [[ $CLAUDE_CONFIG_DIR == /inherited/profile ]]
}

unset CLAUDE_MULTI_PROFILE
PWD="$PROJS_BASE/work"
check "$HOME/.claude-work" claude
check "$HOME/.claude-work" claude-work
check unset claude-personal
PWD="$PROJS_BASE/personal"
check unset claude
PWD="$PROJS_BASE/work-other"
check unset claude

CLAUDE_MULTI_PROFILE=true
PWD="$PROJS_BASE/work/nested project"
check "$HOME/.claude-work" claude

CLAUDE_MULTI_PROFILE=false
for PWD in "$PROJS_BASE/work" "$PROJS_BASE/work/nested project" "$PROJS_BASE/personal"; do
    check unset claude
    check unset claude-personal
    check unset claude-work
done
print -r -- 'PASS: Claude profile routing, single-profile mode, arguments, and environment isolation'
ZSH
