-- LazyVim bootstrap entrypoint
-- This repo stores the config at `vim-config/nvim/` and is symlinked to `~/.config/nvim/`.
---@diagnostic disable: undefined-global

-- set Leader Key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.lazy")
