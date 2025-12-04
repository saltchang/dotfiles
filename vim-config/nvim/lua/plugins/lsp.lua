return {
    -- Mason: manage LSP Server, Formatter, Linter
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },

    -- Mason LSP Config: bridge Mason and Neovim LSP
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
        config = function()
            local mason_lsp = require("mason-lspconfig")
            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            -- define the list of servers you want to install
            local servers = {
                "pyright",  -- Python
                "bashls",   -- Shell
                "dockerls", -- Docker
                "yamlls",   -- YAML / K8s
                "lua_ls",   -- Lua
            }

            mason_lsp.setup({
                ensure_installed = servers,
                -- using handlers is the most stable official way
                handlers = {
                    function(server_name)
                        -- here we still call lspconfig, but through Mason handler it usually solves some loading order issues
                        -- if you see yellow warning (deprecated), this is a preview for 0.11 version of nvim-lspconfig, temporarily ignore it
                        require("lspconfig")[server_name].setup({
                            capabilities = capabilities,
                        })
                    end,

                    -- for specific languages you can override individually (e.g. lua_ls needs special settings)
                    ["lua_ls"] = function()
                        require("lspconfig").lua_ls.setup({
                            capabilities = capabilities,
                            settings = {
                                Lua = {
                                    diagnostics = { globals = { "vim" } }, -- make it recognize vim global variables
                                },
                            },
                        })
                    end,
                },
            })
        end,
    },

    -- auto completion (Auto Completion)
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim-lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },

    -- Formatter
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>cf",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                desc = "Format buffer",
            },
        },
        opts = {
            format_on_save = { timeout_ms = 500, lsp_fallback = true },
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "isort", "black" },
                sh = { "shfmt" },
            },
        },
    },
}
