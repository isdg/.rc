-- ============================================================
--     TOOLS: palace/plc <leader>P*, hr reading list <leader>H*
-- ============================================================
-- Grouped by the binary they drive: <leader>P* = plc/palace notes,
-- <leader>H* = the hr reading list. (This frees the old <leader>n* prefix.)
local leader = require("keymaps.leader")
local map, lmap = leader.map, leader.lmap

-- ── palace / plc: <leader>P* ──
map("n", "<leader>Pt", function()
   -- format: isg 2026-06-04 13:15:42 +0200  (local time + local UTC offset)
   vim.api.nvim_put({ os.date("isg %Y-%m-%d %H:%M:%S %z") }, "c", true, true)
end, { desc = "Insert date stamp (isg, local tz)" })

map("n", "<leader>PT", function()
   -- format: isg 2026-06-04 11:15:42 UTC  (UTC variant of <leader>Pt)
   vim.api.nvim_put({ os.date("%Y-%m-%d %H:%M:%S %z") }, "c", true, true)
end, { desc = "Insert date stamp (isg, UTC offset)" })

-- ── hr reading list: <leader>H* ──
-- Provided by the hr.vim plugin (see lua/plugins/misc.lua); :HrToggle is the
-- portable Vimscript replacement for the old require("hr") Lua module.
lmap("n", "Hr", "<Cmd>HrToggle<CR>",
   { desc = "Toggle hr reading list", silent = true })
-- Locate the current article's row in the hr panel (opens/refreshes it and
-- reveals read articles under an unread-only view). :HrLocate from the plugin.
lmap("n", "Hf", "<Cmd>HrLocate<CR>",
   { desc = "Locate current article in hr feed", silent = true })
