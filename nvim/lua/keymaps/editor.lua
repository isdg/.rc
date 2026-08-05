-- ============================================================
--                  EDITOR: files, splits, sessions
-- ============================================================
local leader = require("keymaps.leader")
local map, lmap = leader.map, leader.lmap

-- ─── File management ────────────────────────────────────────────
lmap("n", "s", "<cmd>w<CR>", { desc = "Save file" })
-- Toggle the whole number column on/off (both number + relativenumber).
lmap("n", "N", function()
   local show = not (vim.wo.number or vim.wo.relativenumber)
   vim.wo.number = show
   vim.wo.relativenumber = false
end, { desc = "Toggle line-number column" })
-- Toggle relative numbers, keeping `number` on so the current line stays
-- absolute (hybrid) instead of showing 0.
lmap("n", "n", function()
   vim.wo.number = true
   vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative numbers (hybrid)" })
lmap("n", "w", "<cmd>q<CR>", { desc = "Quit file" })
lmap("n", "W", "<cmd>q!<CR>", { desc = "Quit without saving" })
lmap("n", "Q", "<cmd>qa!<CR>", { desc = "Quit all without saving" })


-- ─── Split management ───────────────────────────────────────────
-- Ctrl rather than <leader>: one keystroke shorter for a motion used constantly,
-- and Ctrl+letter is keyed off the physical key, so unlike the <leader>hjkl these
-- replaced it needs no Russian-layout twin (see keymaps/leader.lua's lmap).
-- <C-l> gives up Neovim's CTRL-L-default (nohlsearch + diffupdate + redraw):
-- <Esc> already clears highlights below, and :redraw! / :diffupdate cover the
-- rest. <C-h> is distinct from <BS> here — verified in both editors.
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to below split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to above split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

map("n", "<leader>+", "<cmd>resize +5<CR>", { desc = "Increase height" })
map("n", "<leader>-", "<cmd>resize -5<CR>", { desc = "Decrease height" })
map("n", "<leader><", "<cmd>vertical resize -5<CR>", { desc = "Decrease width" })
map("n", "<leader>>", "<cmd>vertical resize +5<CR>", { desc = "Increase width" })
map("n", "<leader>=", "<C-w>=", { desc = "Equalize splits" })


-- ─── History & clipboard ────────────────────────────────────────
-- Fuzzy history (fzf.vim), replacing the q: / q/ cmdline windows — those are
-- still there by typing q: / q/ directly when an editable buffer is wanted.
lmap("n", ";", "<cmd>History:<CR>", { desc = "Command history (fzf)" })
lmap("n", "/", "<cmd>History/<CR>", { desc = "Search history (fzf)" })
-- Jumplist as a list instead of stepping through it with <C-i>/<C-o>
lmap("n", "J", "<cmd>Jumps<CR>", { desc = "Jump list (fzf)" })
-- Every ex command, including plugin ones; <CR> runs it
lmap("n", ":", "<cmd>Commands<CR>", { desc = "Ex commands (fzf)" })

-- Clear search highlights
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- Terminal: Esc exits terminal mode
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Swap jump list navigation (Ctrl+I = back, Ctrl+O = forward)
map("n", "<C-i>", "<C-o>", { noremap = true, desc = "Jump back" })
map("n", "<C-o>", "<C-i>", { noremap = true, desc = "Jump forward" })

-- Yank to system clipboard (visual mode)
lmap("v", "y", '"+y', { desc = "Yank to clipboard" })

-- Reselect last visual selection
lmap("n", "v", "gv", { desc = "Reselect visual" })


-- ─── Sessions ───────────────────────────────────────────────────
local session_path = vim.fn.stdpath("data") .. "/session.vim"

lmap("n", "<Tab>", "<cmd>mksession! " .. session_path .. "<CR><cmd>echo 'Session saved!'<CR>",
   { desc = "Save session" })
lmap("n", "<S-Tab>", "<cmd>source " .. session_path .. "<CR><cmd>echo 'Session loaded!'<CR>",
   { desc = "Load session" })
