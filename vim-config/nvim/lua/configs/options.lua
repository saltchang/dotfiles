require("nvchad.options")

local opt = vim.opt

opt.showtabline = 2 -- always show tabs

opt.number = true -- show line numbers
opt.relativenumber = true
opt.tabstop = 4 -- tab width
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.wrap = false
opt.ignorecase = true
opt.smartcase = true
opt.cursorline = true
opt.termguicolors = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.cursorlineopt = "both" -- to enable cursorline!

opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"

-- system clipboard settings (with wl-clipboard)
-- opt.clipboard = "unnamedplus"

-- save undo history (even if the editor is closed)
opt.undofile = true

-- Neovide specific settings (font and animation)
if vim.g.neovide then
    local font_size = 12
    local os_name = vim.loop.os_uname().sysname

    if os_name == "Darwin" then
        font_size = 15
    elseif os_name == "Linux" then
        font_size = 12
    elseif os_name == "Windows_NT" then
        font_size = 12
    end

    vim.o.guifont = "JetBrainsMono NF:style=Regular:h" .. font_size
    vim.g.neovide_opacity = 0.8
    vim.g.neovide_normal_opacity = 0.8
    vim.g.neovide_input_use_logo = 1
    vim.g.neovide_floating_corner_radius = 0.25
    vim.g.neovide_text_gamma = 0.0
    vim.g.neovide_text_contrast = 0.8
    vim.g.neovide_scroll_animation_length = 0.15

    -- cursor fx
    vim.g.neovide_cursor_animation_length = 0.07 -- cursor animation speed
    vim.g.neovide_cursor_vfx_mode = "pixiedust"
    vim.g.neovide_cursor_vfx_opacity = 200.0
    vim.g.neovide_cursor_vfx_particle_lifetime = 3.0
    vim.g.neovide_cursor_vfx_particle_density = 2.0
    vim.g.neovide_cursor_vfx_particle_speed = 15.0
end

local yank_group = vim.api.nvim_create_augroup("HighlightYank", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
    group = yank_group,
    pattern = "*",
    callback = function()
        -- yank effect
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })

        -- only access to system clipboard when yank
        if vim.v.event.operator == "y" then
            vim.fn.setreg("+", vim.fn.getreg("0"))
        end
    end,
})

-- smart relative number switcher
local smartRelativeLineNumbersGroup = vim.api.nvim_create_augroup("SmartRelNums", { clear = true })

vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave", "FocusLost" }, {
    group = smartRelativeLineNumbersGroup,
    callback = function()
        vim.opt.relativenumber = false
    end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter", "FocusGained" }, {
    group = smartRelativeLineNumbersGroup,
    callback = function()
        if vim.opt.number:get() then
            vim.opt.relativenumber = true
        end
    end,
})
