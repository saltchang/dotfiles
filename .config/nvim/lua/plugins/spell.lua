return {
    {
        "benelan/vim-dirtytalk",
        lazy = false,
        build = ":DirtytalkUpdate",
        config = function()
            vim.opt.spelllang = { "en", "programming" }
            vim.opt.spelloptions:append("camel")
        end,
    },
}
