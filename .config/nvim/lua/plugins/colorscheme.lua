return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            style = "night",
            transparent = not vim.g.neovide, -- transparent in terminal, opaque in neovide
            styles = {
                comments = { italic = true },
            },
            on_colors = function(colors)
                colors.bg = "#0b0f14"
                colors.bg_dark = "#0b0f14"
                colors.bg_float = "#0b0f14"
                colors.bg_sidebar = "#0b0f14"
            end,
            on_highlights = function(hl, _)
                hl.Cursor = { fg = "#000077", bg = "#ff7700" }
                hl.CursorLine = { bg = "#332000" }
                hl.CursorLineNr = { fg = "#ff7700", bold = true }
                hl.LineNr = { fg = "#554433" }

                hl.Comment = { fg = "#556055", italic = true }
                hl["@comment"] = { fg = "#556055", italic = true }

                hl.Visual = { bg = "#6A4010", fg = "NONE" }

                hl.SpellBad = { sp = "#6ef5ff", bg = "#142526", undercurl = true }
            end,
        },
    },
}
