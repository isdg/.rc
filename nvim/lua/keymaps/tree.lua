-- ============================================================
--                  FILE TREE (nvim-tree, replaces NERDTree)
-- ============================================================
local map = require("keymaps.leader").map
local exit_zen_then = require("keymaps.util").exit_zen_then

map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
map("n", "<C-f>", exit_zen_then("NvimTreeFindFile"), { desc = "Find file in tree" })
