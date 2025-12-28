return {
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
                json = { "biome" },
                jsonc = { "biome" },
                sh = { "shfmt" },
            })
        end,
    },
}
