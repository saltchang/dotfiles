return {
    {
        "folke/snacks.nvim",
        opts = {
            styles = {
                lazygit = {
                    width = 0,
                    height = 0,
                    border = "none",
                },
            },
            lazygit = {
                configure = true,
                config = {
                    gui = {
                        nerdFontsVersion = "3",
                        splitDiff = "horizontal",
                    },
                    git = {
                        paging = {
                            colorArg = "always",
                            pager = "delta --dark --paging=never --side-by-side",
                        },
                    },
                },
            },
            picker = {
                icons = {
                    git = {
                        untracked = "U",
                        added = "A",
                        staged = "A",
                        modified = "M",
                        deleted = "D",
                        renamed = "R",
                        ignored = "",
                    },
                },
                sources = {
                    explorer = {
                        hidden = true,
                        ignored = true,
                        exclude = {
                            ".git",
                        },
                    },
                    grep = {
                        hidden = true,
                        ignored = true,
                        exclude = {
                            ".git",
                        },
                    },
                    grep_word = {
                        hidden = true,
                        ignored = true,
                        exclude = {
                            ".git",
                        },
                    },
                    files = {
                        hidden = true,
                        ignored = true,
                        exclude = {
                            ".git",
                        },
                    },
                },
            },
            notifier = {
                enabled = true,
                timeout = 7000,
            },
        },
        init = function()
            vim.api.nvim_create_autocmd("ColorScheme", {
                pattern = "*",
                callback = function()
                    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusModified", { fg = "#0db9d7" })
                    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { fg = "#7ede5a" })
                    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusStaged", { fg = "#1abc9c" })

                    vim.api.nvim_set_hl(0, "SnacksPickerPathHidden", { link = "SnacksPickerFile" })
                    vim.api.nvim_set_hl(0, "SnacksPickerPathIgnored", { fg = "#565f89" })
                end,
            })
        end,
    },

    -- for editing files with sudo
    {
        "lambdalisue/suda.vim",
        cmd = { "SudaRead", "SudaWrite" },
        event = { "BufRead" },
        lazy = false,
        init = function()
            vim.g.suda_smart_edit = 1
        end,
    },
}
