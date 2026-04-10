# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for macOS and Linux (Arch, Ubuntu, Debian). Configurations are managed via **symbolic links** — editing files in this repo directly updates the live system config.

## Installation & Setup

```bash
# Full interactive install (prompts for OS, terminal, editor choices)
./install.sh

# Individual setup scripts (must run from repo root)
./setup-zsh.sh                           # Shell configs → ~/.*
./setup-terminal.sh --kitty --ghostty    # Terminal configs → ~/.config/
./setup-editor.sh --nvim --zed           # Editor configs → ~/.config/
./setup-arch.sh                          # Hyprland ecosystem (Arch only)
```

All setup scripts rely on `scripts/setup-config-dir.sh` which removes the old `~/.config/<app>` target and creates a symlink to this repo's `.config/<app>/`.

## Symlink Architecture

| Source in repo                                                           | Symlinked to             | Method                                                          |
| ------------------------------------------------------------------------ | ------------------------ | --------------------------------------------------------------- |
| `dotfiles/.zshrc`, `.zprofile`, `.zpreztorc`, `.p10k.zsh`, `.prototools` | `~/`                     | `setup-zsh.sh`                                                  |
| `dotfiles/.zshrc.local`                                                  | `~/.zshrc.local`         | Copied from `.zshrc.local.example` on first run, then symlinked |
| `bin/`                                                                   | `~/.local/dotfiles/bin/` | `setup-zsh.sh`                                                  |
| `.config/nvim/`, `.config/kitty/`, `.config/zed/`, etc.                  | `~/.config/`             | `scripts/setup-config-dir.sh`                                   |

Key implication: **files in this repo are live configs**. Changes take effect immediately for symlinked apps.

## Neovim Configuration

Built on **LazyVim** with lazy.nvim as plugin manager.

- Entry point: `.config/nvim/init.lua` → loads `lua/config/lazy.lua`
- Plugin specs in `lua/plugins/` are auto-loaded by LazyVim convention
- LazyVim extras configured in `lazyvim.json` (18 extras: languages, DAP, testing, AI)
- Mason manages LSP servers, formatters, linters, and DAP adapters (see `lua/plugins/mason.lua`)
- AI integration via Avante.nvim (`lua/plugins/ai.lua`) — uses Claude API

## Shell Stack

Zsh + Prezto + Zinit + Powerlevel10k. The `.zshrc` (~878 lines) handles OS/distro detection, terminal detection, SSH agent, completions (uv, uvx, proto, moon), and jump integration. User-specific overrides go in `.zshrc.local` (gitignored via `.local` pattern).

## Conventions

- **Commits**: Conventional Commits format (`feat:`, `fix:`, `chore:`, etc.). Prefer including a scope when changes target a specific tool (e.g., `feat(nvim): ...`).
- **Formatting**: `.editorconfig` — 4-space indent, LF line endings; 2-space for JSON/YAML.
- **Platform support**: Scripts use `case` blocks on OS/distro. macOS uses Homebrew; Arch uses Paru; Ubuntu/Debian use apt.
