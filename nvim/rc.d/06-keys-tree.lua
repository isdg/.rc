-- ============================================================
--                  FILE TREE (nvim-tree, replaces NERDTree)
-- ============================================================
local map = require("keymaps.leader").map
local exit_zen_then = require("keymaps.util").exit_zen_then

-- <leader>t rather than <C-n>: keeps <C-n> free (next line, or the
-- completion menu's next entry) and t was freed in vim by dropping the unused
-- tab mappings, so both editors use the same key.
map("n", "<leader>t", exit_zen_then("NvimTreeFindFile"),
    { desc = "Find file in tree" })
