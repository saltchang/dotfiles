local markdownlint_configs = {
    ".markdownlint-cli2.jsonc",
    ".markdownlint-cli2.yaml",
    ".markdownlint-cli2.cjs",
    ".markdownlint-cli2.mjs",
    ".markdownlint.jsonc",
    ".markdownlint.json",
    ".markdownlint.yaml",
    ".markdownlint.yml",
    ".markdownlint.cjs",
    ".markdownlint.mjs",
}

local function markdownlint_root(filename)
    return vim.fs.root(filename, ".git") or vim.fs.root(filename, markdownlint_configs) or vim.fs.dirname(filename)
end

-- CLI2's gitignore handling can match ancestor directories in absolute paths.
-- Both linting and formatting must pass paths relative to their repo cwd.
local function markdownlint_cli2()
    local linter = vim.deepcopy(require("lint.linters.markdownlint-cli2"))
    local filename = vim.api.nvim_buf_get_name(0)
    local executable = vim.uv.fs_realpath(vim.fn.exepath(linter.cmd))

    if filename == "" or not executable then
        return linter
    end

    linter.cmd = "node"
    linter.stdin = true
    linter.args = {
        vim.fs.joinpath(vim.fn.stdpath("config"), "markdownlint-cli2-buffer.mjs"),
        vim.fs.joinpath(vim.fs.dirname(executable), "markdownlint-cli2.mjs"),
        function()
            return vim.fn.fnamemodify(filename, ":.")
        end,
    }
    linter.cwd = markdownlint_root(filename)
    linter.parser = require("lint.parser").from_pattern(
        "^(.-):(%d+):?(%d*)%s(.+)$",
        { "file", "lnum", "col", "message" },
        nil,
        { source = "markdownlint", severity = vim.diagnostic.severity.WARN }
    )

    return linter
end

return {
    {
        "stevearc/conform.nvim",
        opts = {
            formatters = {
                ["markdownlint-cli2"] = {
                    args = { "--fix", "$RELATIVE_FILEPATH" },
                    cwd = function(_, ctx)
                        return markdownlint_root(ctx.filename)
                    end,
                },
            },
        },
    },
    {
        "mfussenegger/nvim-lint",
        opts = {
            linters = {
                ["markdownlint-cli2"] = markdownlint_cli2,
            },
        },
    },
}
