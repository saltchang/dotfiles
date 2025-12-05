local map = vim.keymap.set
local is_mac = vim.fn.has("macunix") == 1

-- set Leader Key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- quick save (Leader + w)
map("n", "<leader>w", ":w<CR>", { desc = "Save File" })

-- clear search highlight (Esc)
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- window switch
map("n", "<leader>h", "<C-w>h", { desc = "Go to left window (macOS)" })
map("n", "<leader>j", "<C-w>j", { desc = "Go to lower window (macOS)" })
map("n", "<leader>k", "<C-w>k", { desc = "Go to upper window (macOS)" })
map("n", "<leader>l", "<C-w>l", { desc = "Go to right window (macOS)" })

-- better indent (select and press < or > without losing selection)
map("v", "<", "<gv", { desc = "Indent lines" })
map("v", ">", ">gv", { desc = "Indent lines back" })

-- better move lines up and down
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })

map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

map("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move line up" })

-- paste
-- Linux/Standard: Ctrl + v
map("i", "<C-v>", "<C-r>+", { desc = "Paste from clipboard" })
map("c", "<C-v>", "<C-r>+", { desc = "Paste from system clipboard in command mode" })

-- macOS specific: Command + v
if is_mac then
    map("i", "<D-v>", "<C-r>+", { desc = "Paste from clipboard (macOS)" })
    map("c", "<D-v>", "<C-r>+", { desc = "Paste from system clipboard (macOS)" })
end

-- past from system clipboard
map("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })
map("n", "<leader>P", '"+P', { desc = "Paste from system clipboard (before)" })

-- drop whatever cut by x
map("n", "x", '"_x')
