#!/bin/bash
set -e

# ===> Colors ======================================================================================
GREEN="\033[32m"
WARNING="\033[33m"
NC="\033[0m"
# ==================================================================================================

VENV_DIR="$HOME/.venvs/nvim"

# Prefer the proto-managed Python so we honour the version pinned in
# dotfiles/.prototools. Fall back to whatever python3 is on PATH.
PYTHON=""
if command -v proto >/dev/null 2>&1; then
    PROTO_PYTHON=$(proto bin python 2>/dev/null || true)
    if [ -n "$PROTO_PYTHON" ] && [ -x "$PROTO_PYTHON" ]; then
        PYTHON="$PROTO_PYTHON"
    fi
fi
if [ -z "$PYTHON" ] && command -v python3 >/dev/null 2>&1; then
    PYTHON="$(command -v python3)"
fi
if [ -z "$PYTHON" ]; then
    printf '%bpython3 not found, skipping nvim python host setup%b\n' "$WARNING" "$NC"
    exit 0
fi

if [ ! -x "$VENV_DIR/bin/python" ]; then
    printf '%s\n' "Creating nvim python host venv at $VENV_DIR (using $PYTHON)..."
    mkdir -p "$(dirname "$VENV_DIR")"
    "$PYTHON" -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/python" -m pip install --quiet --upgrade pip pynvim
printf '%bnvim python host ready: %s%b\n' "$GREEN" "$VENV_DIR/bin/python" "$NC"
