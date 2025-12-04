return {
    -- fuzzy search
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            -- search files (Like VSCode Cmd+P)
            { "<leader>f",  "<cmd>Telescope find_files<cr>", desc = "Find Files" },
            -- search text (Like VSCode Cmd+Shift+F)
            { "<leader>sg", "<cmd>Telescope live_grep<cr>",  desc = "Search Grep" },
            -- search old files
            { "<leader>?",  "<cmd>Telescope oldfiles<cr>",   desc = "Recent Files" },
        },
    },

    -- syntax highlighting
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                -- ensure these languages are installed
                ensure_installed = { "bash", "c", "lua", "vim", "vimdoc", "python", "dockerfile", "yaml", "markdown" },
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },

    -- comment plugin
    {
        "numToStr/Comment.nvim",
        event = "VeryLazy",
        config = function()
            require("Comment").setup()
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

    -- vim cheatsheet
    {
        "sudormrfbin/cheatsheet.nvim",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/popup.nvim",
            "nvim-lua/plenary.nvim",
        },
        config = function()
            require("cheatsheet").setup({
                bundled_cheatsheets = {
                    enabled = { "default", "lua", "markdown", "regex", "netrw", "unicode" },
                    disabled = { "nerdtree" },
                },
                include_only_installed_plugins = true,
            })
        end,
        keys = {
            -- set shortcut to <leader>ch (Cheat Sheet)
            { "<leader>ch", "<cmd>Cheatsheet<cr>", desc = "Open Cheat Sheet" },
        },
    },

    {
        "ThePrimeagen/vim-be-good",
        cmd = "VimBeGood",
    },
}
