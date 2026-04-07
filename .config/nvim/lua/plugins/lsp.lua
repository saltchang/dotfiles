return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            diagnostics = {
                virtual_text = {
                    -- don't show the inline text for HINT levels
                    severity = { min = vim.diagnostic.severity.INFO },
                },
                underline = {
                    -- don't show the undercurl text for HINT levels
                    severity = { min = vim.diagnostic.severity.INFO },
                },
                float = {
                    border = "rounded", -- available styles: "single", "double", "rounded", "solid", "shadow"
                    source = "always",
                },
            },
            servers = {
                pyright = {
                    settings = {
                        python = {
                            analysis = {
                                autoImportCompletions = true,
                                useLibraryCodeForTypes = true,
                            },
                        },
                    },
                },
            },
        },
    },
}
