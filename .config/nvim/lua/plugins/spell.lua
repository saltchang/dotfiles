return {
    {
        "benelan/vim-dirtytalk",
        lazy = false,
        build = ":DirtytalkUpdate",
        config = function()
            vim.opt.spelllang = { "en", "programming", "cjk" }
            vim.opt.spelloptions:append("camel")
            vim.opt.spelloptions:append("noplainbuffer")
        end,
    },
}
