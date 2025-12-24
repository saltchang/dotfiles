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
        },
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
