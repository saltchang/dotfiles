return {
    -- theme
    {
        "navarasu/onedark.nvim",
        priority = 1000,
        config = function()
            require('onedark').setup {
                style = 'deep',
                transparent = false,
                colors = {
                    bg0 = "#000D1E",
                },
                highlights = {
                    Normal = { bg = "$bg0" },
                    NormalFloat = { bg = "$bg0" },
                },
                code_style = {
                    comments = 'italic',
                    keywords = 'italic,bold',
                    functions = 'none',
                    strings = 'none',
                    variables = 'none'
                },
                lualine = {
                    transparent = true,
                },
            }
            require('onedark').load()
        end
    },

    -- status bar
    {
        "nvim-lualine/lualine.nvim",
        config = function()
            require('lualine').setup({
                options = {
                    theme = 'onedark',
                    component_separators = { left = '', right = '' },
                    section_separators = { left = '', right = '' },
                }
            })
        end
    },

    -- file explorer
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        keys = {
            { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer" }, -- Space+e toggle
        },
        config = function()
            require("neo-tree").setup({
                window = { width = 30 },
                filesystem = {
                    filtered_items = {
                        visible = true,
                        hide_dotfiles = false,
                        hide_gitignored = false,
                        hide_ignored = false,
                        hide_hidden = false,
                    },
                },
                default_component_configs = {
                    git_status = {
                        symbols = {
                            added     = "A",
                            modified  = "M",
                            deleted   = "D",
                            renamed   = "R",
                            untracked = "U",
                            ignored   = "",
                            unstaged  = "",
                            staged    = "",
                            conflict  = "!",
                        }
                    },
                    diagnostics = {
                        symbols = {
                            error = "",
                            warn  = "",
                            info  = "",
                            hint  = "󰌵",
                        },
                        highlights = {
                            hint  = "NeoTreeDiagnosticHint",
                            info  = "NeoTreeDiagnosticInfo",
                            warn  = "NeoTreeDiagnosticWarn",
                            error = "NeoTreeDiagnosticError",
                        },
                    },
                },
            })
            -- git colors
            vim.api.nvim_set_hl(0, "NeoTreeGitAdded", { fg = "#8cba6e" })
            vim.api.nvim_set_hl(0, "NeoTreeGitModified", { fg = "#26e2ff" })
            vim.api.nvim_set_hl(0, "NeoTreeGitDeleted", { fg = "#784242" })
            vim.api.nvim_set_hl(0, "NeoTreeGitRenamed", { fg = "#377ed4" })
            vim.api.nvim_set_hl(0, "NeoTreeGitUntracked", { fg = "#00ff00" })
            vim.api.nvim_set_hl(0, "NeoTreeGitUnstaged", { fg = "#26e2ff" })
            vim.api.nvim_set_hl(0, "NeoTreeGitStaged", { fg = "#a38752" })
            vim.api.nvim_set_hl(0, "NeoTreeGitConflict", { fg = "#f502f5" })

            -- error/warning colors
            vim.api.nvim_set_hl(0, "NeoTreeDiagnosticError", { fg = "#ff0000", bold = true })
            vim.api.nvim_set_hl(0, "NeoTreeDiagnosticWarn", { fg = "#ffff00", bold = true })
            vim.api.nvim_set_hl(0, "NeoTreeDiagnosticInfo", { fg = "#56b6c2" })
            vim.api.nvim_set_hl(0, "NeoTreeDiagnosticHint", { fg = "#61afef" })
        end,
    },
    -- key hint (for beginners
    -- when you press half of the command (e.g. <space>), it will show you what you can press next
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {},
    }
}
