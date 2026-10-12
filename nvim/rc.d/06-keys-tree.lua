-- ============================================================
--                  FILE TREE (nvim-tree, replaces NERDTree)
-- ============================================================
local map = require("keymaps.leader").map
local exit_zen_then = require("keymaps.util").exit_zen_then

-- <leader>t rather than <C-n>: keeps <C-n> free (its insert-mode keyword
-- completion is the valuable one) and t was freed in vim by dropping the unused
-- tab mappings, so both editors use the same key.
-- Opening reveals the current file.
map("n", "<leader>t", exit_zen_then("NvimTreeFindFileToggle"),
    { desc = "Toggle file tree at current file" })
