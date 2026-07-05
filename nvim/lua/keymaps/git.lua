-- ============================================================
--                  GIT (gitsigns + diffview + fugitive)
-- ============================================================
local leader = require("keymaps.leader")
local map, lmap = leader.map, leader.lmap
local exit_zen_then = require("keymaps.util").exit_zen_then

-- Quick blame popup (git-messenger)
lmap("n", "gp", "<cmd>GitMessenger<CR>", { desc = "Git blame popup" })

-- Full blame sidebar (GitLens-style) - navigate with j/k, Enter to see commit
map("n", "<leader>gb", exit_zen_then("Git blame"), { desc = "Git blame sidebar" })
map("n", "<leader>gB", "<cmd>windo set scrollbind<CR><cmd>syncbind<CR>",
   { desc = "Re-sync blame scroll" })

-- Open commit at current line in diffview (see all files changed)
map("n", "<leader>gv", function()
   local blame = vim.fn.system("git blame -l -L " .. vim.fn.line(".") .. "," .. vim.fn.line(".") .. " -- " .. vim.fn.expand("%"))
   local hash = blame:match("^(%x+)")
   if hash and not hash:match("^0+$") then
      vim.cmd("DiffviewOpen " .. hash .. "^!")
   else
      print("No commit for this line")
   end
end, { desc = "Git view commit (all files)" })

map("n", "]c", function() require("gitsigns").nav_hunk("next") end, { desc = "Next git hunk" })
map("n", "[c", function() require("gitsigns").nav_hunk("prev") end, { desc = "Prev git hunk" })

map("n", "<leader>gs", function()
   local view = vim.fn.winsaveview()
   require("gitsigns").stage_hunk()
   vim.schedule(function() vim.fn.winrestview(view) end)
end, { desc = "Git stage hunk" })
map("v", "<leader>gs", function()
   local view = vim.fn.winsaveview()
   require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
   vim.schedule(function() vim.fn.winrestview(view) end)
end, { desc = "Git stage selection" })
map("n", "<leader>gu", function()
   local view = vim.fn.winsaveview()
   require("gitsigns").undo_stage_hunk()
   vim.schedule(function() vim.fn.winrestview(view) end)
end, { desc = "Git unstage hunk" })
map("n", "<leader>gr", function()
   local view = vim.fn.winsaveview()
   require("gitsigns").reset_hunk()
   vim.schedule(function() vim.fn.winrestview(view) end)
end, { desc = "Git reset hunk" })

lmap("n", "gf", "<cmd>DiffviewFileHistory %<CR>", { desc = "Git file history" })
lmap("n", "gl", function()
   local line = vim.fn.line(".")
   local file = vim.fn.expand("%")
   vim.cmd("DiffviewFileHistory -L" .. line .. "," .. line .. ":" .. file)
end, { desc = "Git line history" })
map("n", "<leader>gm", "<cmd>DiffviewFileHistory<CR>", { desc = "Git log (all commits)" })
map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "Git close diffview" })
map("n", "<leader>gd", function() require("git_range").pick() end,
   { desc = "Git diff range picker" })
map("n", "<leader>gj", "<cmd>Commits<CR>", { desc = "Git commits (fzf)" })
map("n", "<leader>gk", "<cmd>BCommits<CR>", { desc = "Git commits for current file (fzf)" })
