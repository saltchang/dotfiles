local map = vim.keymap.set
local is_mac = vim.fn.has("macunix") == 1

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- window switch
map("n", "<leader>h", "<C-w>h", { desc = "Go to left window" })
map("n", "<leader>j", "<C-w>j", { desc = "Go to lower window" })
map("n", "<leader>k", "<C-w>k", { desc = "Go to upper window" })
map("n", "<leader>l", "<C-w>l", { desc = "Go to right window" })

-- better indent (keep selection)
map("v", "<", "<gv", { desc = "Indent lines" })
map("v", ">", ">gv", { desc = "Indent lines back" })

-- move lines up/down
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move line up" })

-- Helix-style clipboard behavior:
-- y/p/P use internal clipboard (unnamed register)
-- <leader>y/<leader>p/<leader>P use system clipboard

-- System clipboard yank (normal and visual modes)
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map({ "n", "v" }, "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })

-- System clipboard paste (normal and visual modes)
map({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from system clipboard (after)" })
map({ "n", "v" }, "<leader>P", '"+P', { desc = "Paste from system clipboard (before)" })

-- System clipboard delete (cut)
map({ "n", "v" }, "<leader>d", '"+d', { desc = "Cut to system clipboard" })

-- paste from system clipboard in insert mode
map("i", "<C-v>", "<C-r>+", { desc = "Paste from system clipboard" })
map("c", "<C-v>", "<C-r>+", { desc = "Paste from system clipboard in command mode" })

-- macOS specific: Command + v
if is_mac then
    map("i", "<D-v>", "<C-r>+", { desc = "Paste from system clipboard (macOS)" })
    map("c", "<D-v>", "<C-r>+", { desc = "Paste from system clipboard (macOS)" })
end

-- don't pollute registers with x
map("n", "x", '"_x')

-- map Delete to page-down (some keyboards)
map({ "n", "v" }, "<Delete>", "<C-d>", { desc = "Scroll down" })

-- comment toggle (terminal often sends <C-_> instead of <C-/>; keep your original binding)
if is_mac then
    map("n", "<D-/>", "gcc", { desc = "toggle comment", remap = true })
    map("v", "<D-/>", "gc", { desc = "toggle comment", remap = true })
else
    map("n", "<C-/>", "gcc", { desc = "toggle comment", remap = true })
    map("v", "<C-/>", "gc", { desc = "toggle comment", remap = true })
end
