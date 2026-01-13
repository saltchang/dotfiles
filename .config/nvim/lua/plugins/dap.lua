return {
    {
        "mfussenegger/nvim-dap",
        dependencies = { "rcarriga/nvim-dap-ui" },
        keys = {
            {
                "K",
                function()
                    require("dapui").eval()
                end,
                desc = "Debug: Hover Variable",
                mode = { "n", "v" },
            },
        },
        opts = function()
            local dap = require("dap")
            local dapui = require("dapui")

            local main_tab_id = nil
            local log_tab_id = nil

            local function is_buffer_reusable(buf)
                if vim.bo[buf].buftype ~= "terminal" then
                    return true
                end

                local chan_id = vim.bo[buf].channel
                if chan_id == 0 then
                    return true
                end

                local status = vim.fn.jobwait({ chan_id }, 0)[1]
                return status ~= -1
            end

            vim.api.nvim_create_user_command("DapOpenTerm", function()
                main_tab_id = vim.api.nvim_get_current_tabpage()

                if log_tab_id and vim.api.nvim_tabpage_is_valid(log_tab_id) then
                    vim.api.nvim_set_current_tabpage(log_tab_id)
                else
                    vim.cmd("tabnew")
                    log_tab_id = vim.api.nvim_get_current_tabpage()
                    vim.cmd("enew")
                    return
                end

                local wins = vim.api.nvim_tabpage_list_wins(0)
                local target_win = nil

                for _, win in ipairs(wins) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if is_buffer_reusable(buf) then
                        target_win = win
                        break
                    end
                end

                if target_win then
                    vim.api.nvim_set_current_win(target_win)
                    vim.cmd("enew")
                else
                    vim.api.nvim_set_current_win(wins[1])
                    vim.cmd("enew")
                end
            end, {})

            dap.defaults.fallback.terminal_win_cmd = "DapOpenTerm"

            dap.listeners.after.event_initialized["dapui_config"] = nil
            dap.listeners.before.event_terminated["dapui_config"] = nil
            dap.listeners.before.event_exited["dapui_config"] = nil

            dap.listeners.after.event_initialized["my_debug_setup"] = function()
                if main_tab_id and vim.api.nvim_tabpage_is_valid(main_tab_id) then
                    vim.api.nvim_set_current_tabpage(main_tab_id)
                end
                dapui.open()
            end

            local function close_debug_ui()
                dapui.close()
            end

            dap.listeners.before.event_terminated["my_debug_setup"] = close_debug_ui
            dap.listeners.before.event_exited["my_debug_setup"] = close_debug_ui
        end,
    },

    -- https://github.com/theHamsta/nvim-dap-virtual-text?tab=readme-ov-file#nvim-dap-virtual-text
    {
        "theHamsta/nvim-dap-virtual-text",
        opts = {
            enabled = true,
            commented = true,
            display_callback = function(variable, _, _, _, options)
                -- by default, strip out new line characters
                local value = variable.value:gsub("%s+", " ")
                -- truncate to 50 chars max
                if #value > 50 then
                    value = value:sub(1, 50) .. "..."
                end
                if options.virt_text_pos == "inline" then
                    return " = " .. value
                else
                    return variable.name .. " = " .. value
                end
            end,
        },
    },
}
