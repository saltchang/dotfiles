return {
    "sindrets/diffview.nvim",
    cmd = {
        "DiffviewOpen",
        "DiffviewClose",
        "DiffviewToggleFiles",
        "DiffviewFocusFiles",
        "DiffviewRefresh",
        "DiffviewFileHistory",
    },
    keys = {
        { "<leader>dvo", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
        { "<leader>dvc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
        { "<leader>fhc", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current file)" },
        { "<leader>fhr", "<cmd>DiffviewFileHistory<cr>", desc = "File History (repo)" },
    },
}
