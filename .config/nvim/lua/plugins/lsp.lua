return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            diagnostics = {
                virtual_text = {
                    -- don't show the inline text for HINT levels
                    severity = { min = vim.diagnostic.severity.INFO },
                },
            },
        },
    },
}
