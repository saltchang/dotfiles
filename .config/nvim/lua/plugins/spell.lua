return {
    {
        "benelan/vim-dirtytalk",
        lazy = false,
        -- Neovim 0.12 dropped the `spellfile#WritableSpellDir()` runtime function
        -- that `:DirtytalkUpdate` relies on, so build the spellfile ourselves.
        build = function(plugin)
            local wordlists_dir = plugin.dir .. "/wordlists/"
            local files = vim.fn.glob(wordlists_dir .. "*.words", true, true)
            local blacklist = vim.g.dirtytalk_blacklist or {}
            local words = {}
            for _, filename in ipairs(files) do
                local name = vim.fn.fnamemodify(filename, ":t:r")
                if not vim.tbl_contains(blacklist, name) then
                    vim.list_extend(words, vim.fn.readfile(filename))
                end
            end
            local tmp = vim.fn.tempname()
            vim.fn.writefile(words, tmp)
            local spell_dir = vim.fn.stdpath("data") .. "/site/spell/"
            vim.fn.mkdir(spell_dir, "p")
            vim.cmd("silent noautocmd mkspell! " .. spell_dir .. "programming " .. tmp)
        end,
        config = function()
            vim.opt.spelllang = { "en", "programming", "cjk" }
            vim.opt.spelloptions:append("camel")
            vim.opt.spelloptions:append("noplainbuffer")
        end,
    },
}
