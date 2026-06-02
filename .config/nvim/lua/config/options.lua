local opt = vim.opt
local uv = vim.uv or vim.loop

local venv_python = vim.fn.expand("~/.venvs/nvim/bin/python")
if vim.fn.executable(venv_python) == 1 then
    vim.g.python3_host_prog = venv_python
else
    vim.g.loaded_python3_provider = 0
end

opt.showtabline = 2 -- always show tabs

opt.number = true
opt.relativenumber = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.ignorecase = true
opt.smartcase = true
opt.cursorline = true
opt.termguicolors = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.cursorlineopt = "both"
opt.modeline = false
opt.title = true
opt.titlestring = "%{v:lua.dotfiles_nvim_title()}"

opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"

local function existing_dir(start_path)
    if not start_path or start_path == "" then
        return nil
    end

    local path = vim.fn.fnamemodify(start_path, ":p")
    local stat = uv.fs_stat(path)

    while not stat do
        local parent = vim.fs.dirname(path)
        if not parent or parent == path then
            return nil
        end

        path = parent
        stat = uv.fs_stat(path)
    end

    if stat and stat.type == "file" then
        return vim.fs.dirname(path)
    end

    return path
end

local function git_dir(dot_git)
    local stat = uv.fs_stat(dot_git)
    if not stat then
        return nil
    end

    if stat.type == "directory" then
        return dot_git
    end

    local gitdir_line = vim.fn.readfile(dot_git, "", 1)[1]
    local path = gitdir_line and gitdir_line:match("^gitdir:%s*(.+)%s*$")
    if not path then
        return nil
    end

    if not vim.startswith(path, "/") then
        path = vim.fs.normalize(vim.fs.dirname(dot_git) .. "/" .. path)
    end

    return path
end

local function git_info(start_path)
    local path = existing_dir(start_path)
    if not path then
        return nil
    end

    local git_path = vim.fs.find(".git", { path = path, upward = true })[1]
    if not git_path then
        return nil
    end

    return {
        root = vim.fs.dirname(git_path),
        git_dir = git_dir(git_path),
    }
end

local function branch_segment(git_path)
    if not git_path then
        return nil
    end

    local head_path = vim.fs.normalize(git_path .. "/HEAD")
    if vim.fn.filereadable(head_path) ~= 1 then
        return nil
    end

    local head = vim.fn.readfile(head_path, "", 1)[1]
    local branch = head and head:match("^ref:%s+refs/heads/(.+)$")

    return branch and branch:match("([^/]+)$") or nil
end

function _G.dotfiles_nvim_title()
    local current_file = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) or nil
    local cwd = vim.fn.getcwd()
    local repo = git_info(current_file) or git_info(cwd)
    local root = repo and repo.root or cwd
    local title = "nvim: " .. vim.fn.fnamemodify(root, ":t")
    local branch = repo and branch_segment(repo.git_dir)

    return branch and string.format("%s (%s)", title, branch) or title
end

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

    -- neovide_transparency has now been deprecated, use neovide_opacity instead.
    vim.g.neovide_opacity = 0.9
    vim.g.neovide_normal_opacity = 0.9
    vim.g.transparency = 0.9
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
else
    if os_name == "Darwin" then
        vim.o.guifont = "JetBrainsMono NF:style=Regular:h 16"
    end
end

-- Enable this option to avoid conflicts with Prettier.
vim.g.lazyvim_prettier_needs_config = true

-- LSP Server to use for Rust.
-- Set to "bacon-ls" to use bacon-ls instead of rust-analyzer.
-- only for diagnostics. The rest of LSP support will still be
-- provided by rust-analyzer.
-- Use bacon-ls so Rust diagnostics (errors/warnings/clippy) update live
-- as you type, without needing to save. rust-analyzer still provides
-- completion/hover/goto; bacon runs cargo check/clippy in the background.
vim.g.lazyvim_rust_diagnostics = "bacon-ls"
