return {
    {
        -- Default config here: https://github.com/yetone/avante.nvim?tab=readme-ov-file#default-setup-configuration
        "yetone/avante.nvim",
        event = "VeryLazy",
        version = false, -- Never set this value to "*"! Never!
        ---@module 'avante'
        ---@type avante.Config
        opts = {
            instructions_file = "avante.md",
            -- provider = "gemini-cli",
            provider = "claude-code",
            -- provider = "claude",
            providers = {
                claude = {
                    -- setup API key in your env:
                    -- export AVANTE_ANTHROPIC_API_KEY=your-claude-api-key
                    endpoint = "https://api.anthropic.com",
                    model = "claude-sonnet-4-20250514",
                    timeout = 30000, -- ms
                    extra_request_body = {
                        temperature = 0.75,
                        max_tokens = 20480,
                    },
                },
            },
            acp_providers = {
                ["gemini-cli"] = {
                    command = "gemini",
                    args = { "--experimental-acp" },
                    env = {
                        NODE_NO_WARNINGS = "1",
                        GEMINI_API_KEY = os.getenv("GEMINI_API_KEY"),
                    },
                },
                ["claude-code"] = {
                    command = "npx",
                    args = { "@zed-industries/claude-code-acp" },
                    env = {
                        NODE_NO_WARNINGS = "1",
                        ANTHROPIC_API_KEY = os.getenv("AVANTE_ANTHROPIC_API_KEY"),
                    },
                },
            },
        },
    },
}
