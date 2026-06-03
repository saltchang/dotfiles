return {
    "sindrets/diffview.nvim",
    cmd = {
        "DiffviewOpen",
        "DiffviewClose",
        "DiffviewToggleFiles",
        "DiffviewFocusFiles",
        "DiffviewRefresh",
        "DiffviewFileHistory",
    },
    keys = {
        { "<leader>dvo", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
        { "<leader>dvc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
        { "<leader>fhc", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current file)" },
        { "<leader>fhr", "<cmd>DiffviewFileHistory<cr>", desc = "File History (repo)" },
    },
    opts = function()
        local actions = require("diffview.actions")
        -- Wrap goto_file_edit in pcall to swallow a cosmetic E367 raised by
        -- snacks.nvim dashboard's BufWipeout autocmd (it tries to delete an
        -- augroup that was already removed during the same wipeout). The file
        -- still opens correctly; this just silences the stack trace.
        local goto_file_edit_safe = function()
            pcall(actions.goto_file_edit)
        end

        -- Close diffview and edit the file in the tab you launched diffview
        -- from (or the current tab if diffview is the only one). Mimics
        -- lazygit's `e`: you stay in the same tab, diffview disappears, and
        -- the file is loaded for editing.
        local function edit_in_place()
            local lib = require("diffview.lib")
            local view = lib.get_current_view()
            if not view then
                return
            end

            local file = view:infer_cur_file()
            if not file then
                return
            end

            local path = file.absolute_path
            local pl = require("diffview.utils").path
            if not pl:readable(path) then
                require("diffview.utils").err(
                    string.format("File does not exist on disk: '%s'", pl:relative(path, "."))
                )
                return
            end

            local cursor
            if file == view.cur_entry and view.cur_layout then
                local win = view.cur_layout:get_main_win()
                if win and win.id and vim.api.nvim_win_is_valid(win.id) then
                    cursor = vim.api.nvim_win_get_cursor(win.id)
                end
            end

            -- Capture the target tab BEFORE closing diffview.
            local target_tab = lib.get_prev_non_view_tabpage()

            pcall(vim.cmd, "DiffviewClose")

            vim.schedule(function()
                -- Ensure we're on the originating tab.
                if target_tab and vim.api.nvim_tabpage_is_valid(target_tab) then
                    vim.api.nvim_set_current_tabpage(target_tab)
                end

                -- Find a normal (non-floating, modifiable file) window on this
                -- tab to host the file. Fall back to the current window.
                local target_win = vim.api.nvim_get_current_win()
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    local cfg = vim.api.nvim_win_get_config(win)
                    if cfg.relative == "" then
                        local buf = vim.api.nvim_win_get_buf(win)
                        local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
                        if bt == "" then
                            target_win = win
                            break
                        end
                    end
                end
                vim.api.nvim_set_current_win(target_win)

                local bufnr = vim.fn.bufadd(path)
                vim.fn.bufload(bufnr)
                -- Use noautocmd to bypass snacks.nvim dashboard's BufWipeout
                -- autocmd which throws E367 and aborts nvim_win_set_buf.
                vim.api.nvim_win_call(target_win, function()
                    vim.cmd("noautocmd buffer " .. bufnr)
                end)
                -- Now fire the events we actually want (filetype detection,
                -- LSP attach, etc.) on the real buffer.
                pcall(vim.api.nvim_exec_autocmds, "BufEnter", { buffer = bufnr })
                pcall(vim.api.nvim_exec_autocmds, "BufWinEnter", { buffer = bufnr })
                pcall(vim.cmd, "filetype detect")
                pcall(vim.api.nvim_set_option_value, "buflisted", true, { buf = bufnr })

                if cursor then
                    pcall(vim.api.nvim_win_set_cursor, target_win, cursor)
                end
            end)
        end

        return {
            keymaps = {
                view = {
                    { "n", "e", edit_in_place, { desc = "Close diffview and edit file in place" } },
                    { "n", "gf", edit_in_place, { desc = "Close diffview and edit file in place" } },
                    { "n", "gF", goto_file_edit_safe, { desc = "Open file in previous tab (diffview default)" } },
                },
                file_panel = {
                    { "n", "e", edit_in_place, { desc = "Close diffview and edit file in place" } },
                    { "n", "gf", edit_in_place, { desc = "Close diffview and edit file in place" } },
                    { "n", "gF", goto_file_edit_safe, { desc = "Open file in previous tab (diffview default)" } },
                },
                file_history_panel = {
                    { "n", "e", edit_in_place, { desc = "Close diffview and edit file in place" } },
                    { "n", "gf", edit_in_place, { desc = "Close diffview and edit file in place" } },
                    { "n", "gF", goto_file_edit_safe, { desc = "Open file in previous tab (diffview default)" } },
                },
            },
        }
    end,
}
