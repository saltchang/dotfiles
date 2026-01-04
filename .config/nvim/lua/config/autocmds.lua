-- Autocommands

-- highlight on yank
local yank_group = vim.api.nvim_create_augroup("HighlightYank", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
    group = yank_group,
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
    end,
})

-- smart relative number switcher
local smart_rel_group = vim.api.nvim_create_augroup("SmartRelNums", { clear = true })

vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave", "FocusLost" }, {
    group = smart_rel_group,
    callback = function()
        vim.opt.relativenumber = false
    end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter", "FocusGained", "BufEnter", "BufWinEnter" }, {
    group = smart_rel_group,
    callback = function()
        if vim.opt.number:get() then
            vim.opt.relativenumber = true
        end
    end,
})
