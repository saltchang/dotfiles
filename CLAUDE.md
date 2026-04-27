# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Personal dotfiles managing shell, terminal, and editor configurations. Supports macOS, Arch Linux, Ubuntu/Debian, and WSL. The repo lives at `~/projects/personal/dotfiles` and deploys configs via symlinks.

## Installation & Setup

```bash
# Fresh install (clones repo and runs setup)
curl -fsSL https://raw.githubusercontent.com/saltchang/dotfiles/HEAD/install.sh | sh -

# Re-install or update (from repo root)
./install.sh
```

The interactive `install.sh` handles bootstrap-only concerns (package managers, fonts, `jump`, git clone) and then delegates to the following self-contained setup scripts:

1. `setup-dotfiles.sh` - installs zsh if missing, sets zsh as the default shell, and symlinks shell dotfiles from `dotfiles/` to `$HOME`
2. `setup-terminal.sh --kitty|--ghostty|--iterm2` - terminal configs; each flag also installs the corresponding binary if missing
3. `setup-editor.sh --nvim|--zed` - editor configs
4. `setup-arch.sh` - Arch-only: hyprland, hyprpanel, rofi, swappy
5. `scripts/setup-server-tools.sh` - headless-host tools (uv). Not wired into `install.sh`; run manually on servers (e.g. contabo) where the desktop bootstrap doesn't apply.

Each `setup-*.sh` owns both the install and config for its area, so you can re-run a single script to refresh just that portion (e.g. `./setup-terminal.sh --kitty` to reinstall and reconfigure kitty) without rerunning `install.sh`.

All setup scripts must be run from the repo root directory.

## Architecture

### Symlink Deployment Model

Configs are **not** copied -- they are symlinked so edits in the repo are immediately live:

- `dotfiles/*` symlinks to `$HOME/` (`.zshrc`, `.zprofile`, `.p10k.zsh`, `.zpreztorc`, `.prototools`)
- `.config/*/` symlinks to `$HOME/.config/*/` (nvim, kitty, zed, hypr, hyprpanel, rofi, swappy)
- `bin/` symlinks to `$HOME/.local/dotfiles/bin/` (added to PATH)

The shared helper `scripts/setup-config-dir.sh --name=<Name> --config-dir=<dir>` handles the `.config/` symlink pattern.

### Key Directories

- **`dotfiles/`** - Shell config source files. The main `.zshrc` detects OS/distro at runtime and adjusts behavior (macOS/Arch/Ubuntu/Debian/WSL).
- **`.config/`** - App config directories, each symlinked independently to `~/.config/`.
- **`bin/`** - Custom scripts on PATH (e.g., `update_git`).
- **`scripts/`** - Setup helpers called by the top-level `setup-*.sh` scripts.

### Shell Stack

Zsh with: zinit (plugin manager) -> Prezto modules + fast-syntax-highlighting + zsh-autosuggestions + zsh-history-substring-search + powerlevel10k (theme). Version management via proto (moonrepo).

### Neovim

LazyVim-based config. Plugin specs in `.config/nvim/lua/plugins/`, custom options/keymaps/autocmds in `.config/nvim/lua/config/`.

### Kitty pane / tab management

Kitty itself is used to manage panes (kitty "windows" inside a tab) and tabs — no external multiplexer. The `splits` layout is enabled so panes can be arbitrarily split horizontally / vertically. Zellij-style `Alt+*` bindings live in `.config/kitty/kitty.conf`:

- `Alt+h/l` — focus left/right neighbor; if at the edge, fall through to the previous/next tab. Implemented via the custom kitten `.config/kitty/move_focus_or_tab.py` (uses `Tab.neighboring_window` then compares the active window id to detect "no movement"; see kitty's [custom kittens docs](https://sw.kovidgoyal.net/kitty/kittens/custom/)).
- `Alt+j/k` — focus down/up neighbor (no tab fallthrough).
- `Alt+n` — new pane, smart split based on aspect ratio (`launch --location=split`).
- `Alt+d` — split current pane downward (`launch --location=hsplit`).
- `Alt+Shift+x` — close current pane.
- `Alt+f` — toggle fullscreen (zoom) for the current pane via `toggle_layout stack` (requires `stack` in `enabled_layouts`).
- Tab management uses kitty defaults (`Ctrl+Shift+T` new tab, `Ctrl+Shift+Left/Right` switch, etc.).

### Local Overrides

Machine-specific config goes in `dotfiles/.zshrc.local` (gitignored via `*.local`). Kitty uses `local.conf` (also gitignored), copied from `local.mac.conf` or `local.arch.conf` during setup.

## Conventions

- **Commits**: Conventional Commits format (`feat:`, `fix:`, `chore:`, etc.). Scope is preferred when changes target a specific area (e.g., `feat(nvim):`, `fix(zsh):`).
- **Indentation**: 4 spaces default, 2 spaces for JSON/YAML. LF line endings, UTF-8.
- **Shell scripts**: Use `#!/bin/bash`. OS detection via `uname` + `lsb_release`. Color output via ANSI escape codes (GREEN/ERROR/NC pattern).
