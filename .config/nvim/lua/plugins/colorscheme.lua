-- Colorscheme manager: many themes, one shared set of custom colors.
--
-- Switch at runtime:
--   :Theme              cycle to the next theme
--   :Theme <name>       jump to a theme (tab-completes; see `theme_order`)
--   <leader>uj          cycle to the next theme
--
-- The active theme persists in `vim.g.active_colorscheme`; override the default
-- per-machine via `vim.g.active_colorscheme` before this file loads.
local default_theme = vim.g.active_colorscheme or "onedark_dark"

-- Transparent in the terminal, opaque (solid bg) in neovide.
local transparent = not vim.g.neovide

-- Fixed custom colors applied on top of EVERY theme.
local palette = {
    bg = "#0b0f14",
    cursor_fg = "#000077",
    cursor_bg = "#ff7700",
    cursor_line = "#332000",
    cursor_line_nr = "#ff7700",
    line_nr = "#554433",
    comment = "#556055",
    visual = "#6A4010",
    spell_bad_sp = "#6ef5ff",
    spell_bad_bg = "#142526",
}

-- Background groups whose bg we own directly (so it works uniformly across
-- every theme, regardless of each plugin's own transparency handling).
local bg_groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "SignColumn",
    "FoldColumn",
    "EndOfBuffer",
    "MsgArea",
}

-- Change only the bg of a group, preserving its fg and other attributes.
-- `color = nil` clears the bg (transparent); a hex string sets a solid bg.
local function set_bg(group, color)
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg = color
    vim.api.nvim_set_hl(0, group, hl)
end

-- Re-apply our fixed colors over whatever colorscheme just loaded. Using a
-- single set of standard highlight groups keeps every theme consistent without
-- translating the palette into each plugin's bespoke override API.
local function apply_custom_highlights()
    local set = vim.api.nvim_set_hl
    -- Solid dark background in neovide; transparent in the terminal. Owning this
    -- ourselves works even for themes (e.g. onedarkpro) whose own transparency
    -- option does not take effect.
    local bg = vim.g.neovide and palette.bg or nil
    for _, group in ipairs(bg_groups) do
        set_bg(group, bg)
    end
    set(0, "Cursor", { fg = palette.cursor_fg, bg = palette.cursor_bg })
    set(0, "CursorLine", { bg = palette.cursor_line })
    set(0, "CursorLineNr", { fg = palette.cursor_line_nr, bold = true })
    set(0, "LineNr", { fg = palette.line_nr })
    set(0, "Comment", { fg = palette.comment, italic = true })
    set(0, "@comment", { fg = palette.comment, italic = true })
    set(0, "Visual", { bg = palette.visual })
    set(0, "SpellBad", { sp = palette.spell_bad_sp, bg = palette.spell_bad_bg, undercurl = true })
end

-- Catch every colorscheme change (incl. LazyVim's initial one and manual
-- `:colorscheme`) so the custom colors are always layered on last.
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("custom_theme_overrides", { clear = true }),
    callback = apply_custom_highlights,
})

-- onedarkpro renders via a require-based loader (its colors/*.lua use the same),
-- which sidesteps `:colorscheme` name resolution and loads the exact variant.
-- Unlike `:colorscheme`, load() does not fire the ColorScheme event, so other
-- plugins' ColorScheme autocmds (e.g. snacks explorer git-status colors) never
-- run. Fire it ourselves so onedarkpro behaves like a normal colorscheme load.
local function load_onedarkpro(theme)
    require("onedarkpro").load({ theme = theme })
    vim.api.nvim_exec_autocmds("ColorScheme", { pattern = theme, modeline = false })
end

local theme_loaders = {
    tokyonight = function()
        vim.cmd.colorscheme("tokyonight")
    end,
    tokyodark = function()
        vim.cmd.colorscheme("tokyodark")
    end,
    onedark_dark = function()
        load_onedarkpro("onedark_dark")
    end,
    vaporwave = function()
        load_onedarkpro("vaporwave")
    end,
}

-- Cycle order for `:Theme` (no arg) and <leader>uj.
local theme_order = {
    "onedark_dark",
    "vaporwave",
    "tokyodark",
    "tokyonight",
}

-- Apply a theme by name (any key in `theme_loaders`).
local function apply_theme(name)
    local loader = theme_loaders[name]
    if not loader then
        vim.notify("Unknown theme: " .. name, vim.log.levels.WARN)
        return
    end

    loader()
    -- Some loaders (require-based) don't fire the ColorScheme event, so apply
    -- the custom colors explicitly to be safe; it's idempotent.
    apply_custom_highlights()
    vim.g.active_colorscheme = name
end

-- Cycle to the next theme in `theme_order`.
local function next_theme()
    local idx = 1
    for i, name in ipairs(theme_order) do
        if name == vim.g.active_colorscheme then
            idx = i
            break
        end
    end
    local nxt = theme_order[idx % #theme_order + 1]
    apply_theme(nxt)
    vim.notify("theme: " .. nxt, vim.log.levels.INFO)
end

-- Register the :Theme command, keymaps, and apply the chosen default. Lives in
-- one always-loaded plugin's config so it runs once at startup.
local function setup_switcher()
    -- `:Theme` with no arg cycles; with an arg jumps to a theme.
    vim.api.nvim_create_user_command("Theme", function(opts)
        if opts.args == "" then
            next_theme()
        else
            apply_theme(opts.args)
        end
    end, {
        nargs = "?",
        complete = function()
            return vim.deepcopy(theme_order)
        end,
        desc = "Switch/cycle colorscheme",
    })

    vim.keymap.set("n", "<leader>uj", next_theme, { desc = "Next colorscheme" })

    -- Apply our choice after startup so it wins over LazyVim's default.
    vim.schedule(function()
        apply_theme(default_theme)
    end)
end

return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            style = "night",
            transparent = transparent,
        },
        config = function(_, opts)
            require("tokyonight").setup(opts)
            setup_switcher()
        end,
    },
    {
        "olimorris/onedarkpro.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("onedarkpro").setup({
                options = { transparency = transparent },
            })
        end,
    },
    {
        "tiagovla/tokyodark.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("tokyodark").setup({
                transparent_background = transparent,
            })
        end,
    },
}
