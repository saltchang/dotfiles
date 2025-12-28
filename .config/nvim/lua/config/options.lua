local opt = vim.opt

opt.showtabline = 2 -- always show tabs

opt.number = true
opt.relativenumber = true
opt.tabstop = 4
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
opt.cursorlineopt = "both"

opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"

-- save undo history (even if the editor is closed)
opt.undofile = true

-- Neovide specific settings
if vim.g.neovide then
    local font_size = 12
    local os_name = (vim.uv or vim.loop).os_uname().sysname

    if os_name == "Darwin" then
        font_size = 15
    elseif os_name == "Linux" then
        font_size = 12
    elseif os_name == "Windows_NT" then
        font_size = 12
    end

    vim.o.guifont = "JetBrainsMono NF:style=Regular:h" .. font_size

    vim.g.neovide_opacity = 0.9
    vim.g.neovide_normal_opacity = 0.9
    vim.g.neovide_input_use_logo = 1
    vim.g.neovide_floating_corner_radius = 0.25
    vim.g.neovide_text_gamma = 0.0
    vim.g.neovide_text_contrast = 0.8
    vim.g.neovide_scroll_animation_length = 0.15

    -- cursor fx
    vim.g.neovide_cursor_animation_length = 0.07
    vim.g.neovide_cursor_vfx_mode = "pixiedust"
    vim.g.neovide_cursor_vfx_opacity = 200.0
    vim.g.neovide_cursor_vfx_particle_lifetime = 3.0
    vim.g.neovide_cursor_vfx_particle_density = 2.0
    vim.g.neovide_cursor_vfx_particle_speed = 15.0
end

-- Enable this option to avoid conflicts with Prettier.
vim.g.lazyvim_prettier_needs_config = true

-- LSP Server to use for Rust.
-- Set to "bacon-ls" to use bacon-ls instead of rust-analyzer.
-- only for diagnostics. The rest of LSP support will still be
-- provided by rust-analyzer.
vim.g.lazyvim_rust_diagnostics = "rust-analyzer"
