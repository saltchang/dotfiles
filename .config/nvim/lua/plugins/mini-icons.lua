return {
    {
        "nvim-mini/mini.icons",
        config = function()
            local function set_my_colors()
                vim.api.nvim_set_hl(0, "MiniIconsOrange", { fg = "#f1502f", force = true })
                vim.api.nvim_set_hl(0, "MiniIconsBlue", { fg = "#42A5F5", force = true })
                vim.api.nvim_set_hl(0, "MiniIconsYello", { fg = "#F9A825", force = true })
            end

            set_my_colors()
            vim.api.nvim_create_autocmd("ColorScheme", {
                pattern = "*",
                callback = set_my_colors,
            })

            require("mini.icons").setup({
                -- MiniIconsAzure  - azure
                -- MiniIconsBlue   - blue
                -- MiniIconsCyan   - cyan
                -- MiniIconsGreen  - green
                -- MiniIconsGrey   - grey
                -- MiniIconsOrange - orange
                -- MiniIconsPurple - purple
                -- MiniIconsRed    - red
                -- MiniIconsYellow - yellow

                directory = {
                    config = { glyph = "󱁿", hl = "MiniIconsGreen" },
                    configs = { glyph = "󱁿", hl = "MiniIconsGreen" },
                    dotfiles = { glyph = "󱂀", hl = "MiniIconsPurple" },
                    images = { glyph = "󰉏", hl = "MiniIconsAzure" },
                    scripts = { glyph = "󰲂", hl = "MiniIconsOrange" },
                },
                file = {
                    [".gitignore"] = { hl = "MiniIconsOrange" },

                    ["readme"] = { glyph = "󰋼", hl = "MiniIconsBlue" },
                    ["README"] = { glyph = "󰋼", hl = "MiniIconsBlue" },
                    ["readme.md"] = { glyph = "󰋼", hl = "MiniIconsBlue" },
                    ["README.md"] = { glyph = "󰋼", hl = "MiniIconsBlue" },

                    ["LICENSE"] = { glyph = "󰿃", hl = "MiniIconsOrange" },
                },
                default = {
                    directory = { hl = "MiniIconsGray" },
                },
                extension = {},
                filetype = {
                    json = { glyph = "", hl = "MiniIconsYellow" },
                    sh = { glyph = "", hl = "MiniIconsOrange" },
                },
                lsp = {},
                os = {},
            })
        end,
    },
}
