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

The interactive `install.sh` orchestrates these setup scripts in order:

1. `setup-zsh.sh` - symlinks shell dotfiles from `dotfiles/` to `$HOME`
2. `setup-terminal.sh --kitty|--ghostty|--iterm2|--tmux` - terminal and multiplexer configs; `--tmux` also bootstraps TPM and installs declared plugins
3. `setup-editor.sh --nvim|--zed` - editor configs
4. `setup-arch.sh` - Arch-only: hyprland, hyprpanel, rofi, swappy

All setup scripts must be run from the repo root directory.

## Architecture

### Symlink Deployment Model

Configs are **not** copied -- they are symlinked so edits in the repo are immediately live:

- `dotfiles/*` symlinks to `$HOME/` (`.zshrc`, `.zprofile`, `.p10k.zsh`, `.zpreztorc`, `.prototools`)
- `.config/*/` symlinks to `$HOME/.config/*/` (nvim, kitty, tmux, zed, hypr, hyprpanel, rofi, swappy)
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

### Terminal Multiplexer (tmux)

tmux replaces the previous zellij setup. Config lives in `.config/tmux/`:

- `tmux.conf` - main config. Prefix is `Ctrl+b`. Keybinds follow a zellij-style modal model: always-on `Alt+*` root bindings plus sub-tables (`pane-mode`, `tab-mode`, `resize-mode`, `scroll-mode`, `session-mode`, `move-mode`) entered via the prefix and exited with `Enter` / `Escape`.
- `tokyonight_night.tmux` - colour scheme sourced from folke/tokyonight.nvim's `extras/tmux/`, aligned with the nvim tokyonight theme.
- `cheatsheet.md` - opened in a popup via `Ctrl+b ?`.
- Plugins managed by TPM (`~/.tmux/plugins/tpm/`). TPM also installs plugins into the XDG path `.config/tmux/plugins/`, which is gitignored.
- `allow-passthrough on` is enabled so Kitty Graphics Protocol / sixel work inside tmux (main reason this repo uses tmux over zellij).
- `.zshrc` autostarts `tmux new-session -A -s main` when outside tmux and not in an SSH session.

### Local Overrides

Machine-specific config goes in `dotfiles/.zshrc.local` (gitignored via `*.local`). Kitty uses `local.conf` (also gitignored), copied from `local.mac.conf` or `local.arch.conf` during setup.

## Conventions

- **Commits**: Conventional Commits format (`feat:`, `fix:`, `chore:`, etc.). Scope is preferred when changes target a specific area (e.g., `feat(nvim):`, `fix(zsh):`).
- **Indentation**: 4 spaces default, 2 spaces for JSON/YAML. LF line endings, UTF-8.
- **Shell scripts**: Use `#!/bin/bash`. OS detection via `uname` + `lsb_release`. Color output via ANSI escape codes (GREEN/ERROR/NC pattern).
