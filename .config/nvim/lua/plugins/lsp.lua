return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            diagnostics = {
                -- refresh diagnostics while typing in insert mode, so bacon-ls
                -- live (as-you-type) Rust diagnostics actually show without leaving insert
                update_in_insert = true,
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
                -- bacon-ls: live Rust diagnostics (errors/warnings/clippy) as you type,
                -- without saving. The cargo backend mirrors the dirty buffer into a
                -- shadow workspace and runs cargo/clippy against it on every keystroke
                -- (debounced). updateOnInsert MUST live in init_options, not settings,
                -- because the didChange sync capability is advertised at init time.
                -- rust-analyzer still handles completion/hover/goto (its own
                -- diagnostics are turned off by the LazyVim rust extra in bacon-ls mode).
                bacon_ls = {
                    enabled = true,
                    init_options = {
                        cargo = { updateOnInsert = true },
                    },
                    settings = {
                        bacon_ls = {
                            backend = "cargo",
                            cargo = {
                                command = "clippy",
                                -- check the whole workspace, every target (tests/examples/
                                -- benches) and every feature, so errors outside the default
                                -- package/target/feature still surface. Without this, cargo
                                -- only checks the default package's default target.
                                -- --keep-going: keep compiling every target even after one
                                -- fails, so ALL files' errors are reported. Without it cargo
                                -- aborts at the first failing target and later targets (e.g.
                                -- another broken file) never get checked — this is why a
                                -- known-broken file could show no diagnostics at all.
                                extraArgs = { "--workspace", "--all-targets", "--all-features", "--keep-going" },
                                updateOnInsertDebounceMillis = 500,
                            },
                        },
                    },
                },
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
