-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.base46 = {
    theme = "rxyhn",
    -- Use a real background color so we can tune it darker.
    -- If you prefer transparent backgrounds in terminal, set this back to true.
    transparency = true,
    theme_toggle = { "yoru", "rxyhn" },

    hl_override = {
        -- Slightly darker background for Neovim/Neovide
        Normal = { bg = "#0b0f14" },
        NormalNC = { bg = "#0b0f14" },
        NormalFloat = { bg = "#0b0f14" },
        FloatBorder = { bg = "#0b0f14" },
        SignColumn = { bg = "#0b0f14" },
        EndOfBuffer = { fg = "#0b0f14", bg = "#0b0f14" },

        -- Neo-tree background to match
        NeoTreeNormal = { bg = "#0b0f14" },
        NeoTreeNormalNC = { bg = "#0b0f14" },
        NeoTreeEndOfBuffer = { fg = "#0b0f14", bg = "#0b0f14" },

        Cursor = { fg = "#000077", bg = "#ff7700" },
        CursorLine = { bg = "#332000" },
        NvimTreeCursorLine = { bg = "#105050", bold = true },
        CursorLineNr = { fg = "#ff7700", bold = true },
        LineNr = { fg = "#554433" },
        Comment = { fg = "#556055", italic = true },
        ["@comment"] = { fg = "#556055", italic = true },
        ["@diff.delta"] = { fg = "#60a0a0" },
        ["@comment.todo"] = { fg = "#313c40", bg = "#8bec8b" },
        MatchWord = { fg = "#e9e7e6", bg = "#616c70" },
        Visual = { bg = "#6A4010", fg = "NONE" },
        TelescopeSelection = { bg = "#eeaa22", fg = "#000077", bold = true },
        TelescopeSelectionCaret = { fg = "#ffffff", bg = "#4477cc", bold = true },
        TelescopeMatching = { fg = "#ffffff", bg = "#4477cc", bold = true },
    },
}

if vim.g.neovide then
    M.base46.transparency = false
end

M.nvdash = { load_on_startup = true }
M.ui = {
    tabufline = {
        enabled = false,
    },
    statusline = {
        theme = "vscode_colored", -- default/vscode/vscode_colored/minimal
        -- default/round/block/arrow separators work only for default statusline theme
        -- round and block will work for minimal theme only
        -- separator_style = "default",
    },
    cmp = {
        icons = true,
        lspkind_text = true,
        style = "flat_dark", -- default/flat_light/flat_dark/atom/atom_colored
    },
    telescope = { style = "bordered" }, -- borderless / bordered
}

M.cheatsheet = {
    theme = "simple", -- simple/grid
    excluded_groups = { "terminal (t)", "autopairs", "Nvim", "Opens" }, -- can add group name or with mode
}

return M
