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


-- ─── Format ────────────────────────────────────────────────────
-- Moved from <leader>ff to <leader>F so the f prefix is free for flash jump
-- (<leader>f, see plugins/nav.lua's flash.nvim spec).
map("n", "<leader>F", function()
   require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
