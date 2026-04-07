return {
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
                json = { "biome", "prettier", stop_after_first = true },
                jsonc = { "biome", "prettier", stop_after_first = true },
                typ = { "biome" },
                sh = { "shfmt" },
                zsh = { "beautysh" },
                javascript = { "biome", "prettier", stop_after_first = true },
                javascriptreact = { "biome", "prettier", stop_after_first = true },
                typescript = { "biome", "prettier", stop_after_first = true },
                typescriptreact = { "biome", "prettier", stop_after_first = true },
                python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
            })

            opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
                biome = {
                    require_cwd = true, -- 只有在專案根目錄找到 biome.json(c) 時才執行 biome
                },
            })
        end,
    },
}
