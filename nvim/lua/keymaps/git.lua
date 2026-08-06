-- ============================================================
--                  GIT (gitsigns + fzf.vim + fugitive)
-- ============================================================
-- One way to do each thing:
--   blame     git-messenger popup / fugitive sidebar
--   hunks     gitsigns (signs, nav, stage, reset)
--   history   fzf.vim pickers (:Commits, :BCommits, :GFiles?)
-- Diff *browsing* is fugitive's job (:Git diff, :Gvdiffsplit) — there is no
-- second diff UI to get lost in.
local leader = require("keymaps.leader")
local map, lmap = leader.map, leader.lmap
local exit_zen_then = require("keymaps.util").exit_zen_then

-- Quick blame popup (git-messenger)
lmap("n", "gp", "<cmd>GitMessenger<CR>", { desc = "Git blame popup" })

-- Full blame sidebar (GitLens-style) - navigate with j/k, Enter to see commit
map("n", "<leader>gb", exit_zen_then("Git blame"), { desc = "Git blame sidebar" })
map("n", "<leader>gB", "<cmd>windo set scrollbind<CR><cmd>syncbind<CR>",
    { desc = "Re-sync blame scroll" })

-- Show the commit that last touched this line (full diff, all files)
map("n", "<leader>gv", function()
    local blame = vim.fn.system("git blame -l -L " .. vim.fn.line(".") .. "," .. vim.fn.line(".") .. " -- " .. vim.fn.expand("%"))
    local hash = blame:match("^(%x+)")
    if hash and not hash:match("^0+$") then
        -- Gedit, not `Git show`: the latter dumps output into a temp buffer in a
        -- split, while this opens the commit object full-window (<C-o> to go
        -- back) with filenames you can <CR> into.
        vim.cmd("Gedit " .. hash)
    else
        print("No commit for this line")
    end
end, { desc = "Git show commit for this line" })

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

-- Fuzzy git (fzf.vim). Enter on a commit opens it via fugitive.
map("n", "<leader>gm", "<cmd>Commits<CR>", { desc = "Git log, all commits (fzf)" })
map("n", "<leader>gf", "<cmd>BCommits<CR>", { desc = "Git history, current buffer (fzf)" })
-- A range on :BCommits becomes `git log -L a,b:file` — line history, fuzzy
map("n", "<leader>gl", "<cmd>.BCommits<CR>", { desc = "Git history, current line (fzf)" })
map("v", "<leader>gl", ":BCommits<CR>", { desc = "Git history, selected lines (fzf)" })
map("n", "<leader>gd", "<cmd>GFiles?<CR>", { desc = "Git changed files (fzf)" })
