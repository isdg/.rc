-- ============================================================
--                  EDITING: comment, zen mode, format
-- ============================================================
local map = require("keymaps.leader").map
local lmap = require("keymaps.leader").lmap

-- ─── Commenting (Comment.nvim, replaces NERDCommenter) ──────────
map("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment" })
map("v", "<C-_>", "gc", { remap = true, desc = "Toggle comment" })


-- ─── Zen mode ───────────────────────────────────────────────────
-- lmap("n", "z", "<cmd>Goyo-10<CR>", { desc = "Toggle zen mode (Goyo)" })
lmap("n", "z", "<cmd>ZenMode<CR>", { desc = "Toggle zen mode" })
-- Height is full-height by default; :ZenHeight 0.8 / :ZenHeight 30 changes it
-- for the session (see plugins/edit.lua and vim.g.zen_height in options.lua).


-- ─── Format ────────────────────────────────────────────────────
-- Moved off <leader>ff long ago; <leader>f is the file finder (keymaps/find.lua),
-- so format keeps the capital.
map("n", "<leader>F", function()
    require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
