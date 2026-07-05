-- ============================================================
--                  NOTES: <leader>n*, hr reading list
-- ============================================================
local leader = require("keymaps.leader")
local map, lmap = leader.map, leader.lmap

-- (<leader>nl = palace-link picker, defined in vim/palace-link.vim)
map("n", "<leader>nt", function()
   -- format: isg 2026-06-04 13:15:42 +0200  (local time + local UTC offset)
   vim.api.nvim_put({ os.date("isg %Y-%m-%d %H:%M:%S %z") }, "c", true, true)
end, { desc = "Insert date stamp (isg, local tz)" })

map("n", "<leader>nT", function()
   -- format: isg 2026-06-04 11:15:42 UTC  (UTC variant of <leader>nt)
   vim.api.nvim_put({ os.date("%Y-%m-%d %H:%M:%S %z") }, "c", true, true)
end, { desc = "Insert date stamp (isg, local tz)" })

-- Provided by the hr.vim plugin (see lua/plugins/misc.lua); :HrToggle is the
-- portable Vimscript replacement for the old require("hr") Lua module.
lmap("n", "nr", "<Cmd>HrToggle<CR>",
   { desc = "Toggle hr reading list", silent = true })
