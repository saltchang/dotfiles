# VIM Configs

This document is for Arch Linux & Hyprland only.

## Install the Editor

```zsh
paru -S neovim neovide
```

## Install Dependencies

- ripgrep: for Telescope
- fd: for looking for files
- wl-clipboard: Wayland system clipboard
- unzip, gzip, tar: for Mason to install LSP servers

```zsh
paru -S ripgrep fd wl-clipboard unzip gzip tar
```

You can also install the following runtime optionally if you don't use other version managers:

```zsh
paru -S npm python-pip go
```
