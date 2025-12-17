return {
    -- fuzzy search
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            -- search files (Like VSCode Cmd+P)
            -- { "<leader>f",  "<cmd>Telescope find_files<cr>", desc = "Find Files" },
            -- search text (Like VSCode Cmd+Shift+F)
            -- { "<leader>sg", "<cmd>Telescope live_grep<cr>",  desc = "Search Grep" },
            -- search old files
            -- { "<leader>?",  "<cmd>Telescope oldfiles<cr>",   desc = "Recent Files" },
        },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                pickers = {
                    live_grep = {
                        file_ignore_patterns = { " node_modules", ".git", ".venv" },
                        additional_args = function(_)
                            return { "--hidden" }
                        end,
                    },
                },
            })
        end,
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
            { "<leader>cs", "<cmd>Cheatsheet<cr>", desc = "Open Cheat Sheet" },
        },
    },

    {
        "ThePrimeagen/vim-be-good",
        cmd = "VimBeGood",
    },

    {
        "kdheepak/lazygit.nvim",
        lazy = true,
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim",
        },
        config = function()
            require("telescope").load_extension("lazygit")
        end,
        keys = {
            { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
        },
    },

    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
        config = function()
            local actions = require("diffview.actions")
            require("diffview").setup({
                -- Enable enhanced diff highlighting so diff buffers can keep richer highlighting
                -- (including syntax/tree-sitter highlights where available).
                enhanced_diff_hl = true,
                view = {
                    merge_tool = {
                        layout = "diff3_mixed",
                    },
                },
                file_panel = {
                    win_config = {
                        position = "left",
                        width = 30,
                    },
                },
                keymaps = {
                    -- Neo-tree-like git keys inside Diffview:
                    -- ga = stage/unstage current file, gu = unstage (toggle), A = stage all, gr = revert.
                    view = {
                        ["ga"] = actions.toggle_stage_entry,
                        -- ["A"] = actions.stage_all,
                        -- ["re"] = actions.restore_entry,
                        -- ["go"] = actions.goto_file_edit,
                    },
                    file_panel = {
                        ["ga"] = actions.toggle_stage_entry,
                        -- ["A"] = actions.stage_all,
                        -- ["re"] = actions.restore_entry,
                        -- ["go"] = actions.goto_file_edit,
                    },
                },
                hooks = {
                    diff_buf_win_enter = function(bufnr, winid, ctx)
                        if ctx.layout_name:match("^diff2") then
                            if ctx.symbol == "a" then
                                -- "a" = old side. Treat additions as deletions (GitHub-style),
                                -- and make inline-changes (DiffText) more prominent.
                                vim.api.nvim_set_option_value(
                                    "winhl",
                                    table.concat({
                                        "DiffAdd:DiffviewDiffAddAsDelete",
                                        "DiffDelete:DiffviewDiffDelete",
                                        "DiffChange:DiffviewDiffDelete",
                                        "DiffText:DiffviewDiffTextDelete",
                                    }, ","),
                                    { win = winid }
                                )
                            elseif ctx.symbol == "b" then
                                -- "b" = new side.
                                vim.api.nvim_set_option_value(
                                    "winhl",
                                    table.concat({
                                        "DiffAdd:DiffviewDiffAdd",
                                        "DiffDelete:DiffviewDiffDelete",
                                        "DiffChange:DiffviewDiffChange",
                                        "DiffText:DiffviewDiffTextAdd",
                                    }, ","),
                                    { win = winid }
                                )
                            end
                        end
                    end,
                },
            })

            -- Custom Highlights to match Neo-tree
            local function set_hl(name, fg, bg, extra)
                vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", { fg = fg, bg = bg }, extra or {}))
            end

            -- Match Diffview highlights with Neo-tree Git colors
            -- set_hl("DiffviewFilePanelInsert", "#8cba6e", nil) -- Added (NeoTreeGitAdded)
            -- set_hl("DiffviewFilePanelModified", "#26e2ff", nil) -- Modified (NeoTreeGitModified)
            -- set_hl("DiffviewFilePanelDeleted", "#784242", nil) -- Deleted (NeoTreeGitDeleted)
            -- set_hl("DiffviewFilePanelRename", "#377ed4", nil) -- Renamed (NeoTreeGitRenamed)
            -- set_hl("DiffviewFilePanelConflict", "#f502f5", nil) -- Conflict (NeoTreeGitConflict)
            -- set_hl("DiffviewFilePanelUntracked", "#00ff00", nil) -- Untracked (NeoTreeGitUntracked)

            local function apply_diff_hl()
                -- Show syntax highlight *inside* added/changed/removed lines.
                -- Many themes set Diff*/DiffviewDiff* foreground to solid green/red, which masks syntax colors.
                -- Setting fg="NONE" lets the underlying syntax/tree-sitter highlight show through, while bg indicates diff.
                --
                -- Also set blend=0 to avoid any "washed out" look in GUIs.

                -- Added lines
                set_hl("DiffviewDiffAdd", "NONE", "#132e1e", { blend = 0 })
                set_hl("DiffAdd", "NONE", "#132e1e", { blend = 0 })

                -- Changed lines
                set_hl("DiffviewDiffChange", "NONE", "#1c202e", { blend = 0 })
                set_hl("DiffChange", "NONE", "#1c202e", { blend = 0 })
                set_hl("DiffviewDiffText", "NONE", "#1e2642", { bold = true, blend = 0 })
                set_hl("DiffText", "NONE", "#1e2642", { bold = true, blend = 0 })

                -- Inline changes (GitHub-like): stronger highlight for changed chunks within the line.
                -- These are used via winhl in diff2 layouts (old/new sides).
                set_hl("DiffviewDiffTextAdd", "NONE", "#1f5e33", { bold = true, blend = 0 })
                set_hl("DiffviewDiffTextDelete", "NONE", "#7a1e1e", { bold = true, blend = 0 })

                -- Deleted lines
                set_hl("DiffviewDiffDelete", "NONE", "#381313", { blend = 0 })
                set_hl("DiffDelete", "NONE", "#381313", { blend = 0 })

                -- Diffview uses these in diff2 layouts and/or for filler highlighting.
                set_hl("DiffviewDiffAddAsDelete", "NONE", "#381313", { blend = 0 })
                set_hl("DiffviewDiffDeleteDim", "NONE", "#381313", { blend = 0 })
            end

            apply_diff_hl()

            -- Themes (and sometimes Diffview) can re-apply Diff highlights; re-apply ours after those events.
            local grp = vim.api.nvim_create_augroup("DiffviewCustomDiffHL", { clear = true })
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = grp,
                callback = apply_diff_hl,
            })
            vim.api.nvim_create_autocmd("User", {
                group = grp,
                pattern = { "DiffviewDiffBufRead", "DiffviewDiffBufWinEnter" },
                callback = apply_diff_hl,
            })

            -- Custom Signs/Symbols (simulated by configuring Diffview if possible, otherwise rely on highlights)
            -- Note: Diffview uses its own status indicators (M, A, D, etc.) by default which are similar to standard git status.
        end,
        keys = {
            { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff View Open" },
            { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Diff View Close" },
            { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
        },
    },
}
