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

-- Move the split itself, the one verb vim's <C-w> has no directional form of:
-- it offers <C-w>x (exchange with *next*) and <C-w>r (rotate), both of which
-- make you work out where a window will land, plus <C-w>HJKL, which is a
-- different thing entirely — that throws a window to the far edge and makes it
-- full height/width, destroying the layout rather than swapping within it.
--
-- On <C-w><C-hjkl>, which costs nothing: those are builtin synonyms for
-- <C-w>hjkl, and navigation already lives on bare <C-hjkl> above, so the
-- synonyms are dead weight here. Spending them makes nvim read exactly like the
-- tmux layer — hjkl goes to a split, C-hjkl drags it there — so the two editors
-- keep one set of muscle memory between them.
--
-- Swapping buffers rather than windows is what vim gives us, and it needs the
-- view carried across by hand: winsaveview is per *window*, so a bare buffer
-- swap leaves each window looking at its old scroll position and cursor line,
-- and the file appears to jump. Focus follows the buffer that moved, matching
-- the tmux binding — a move you have to chase is a move you did twice.
--
-- No wrapping, unlike tmux: `wincmd h` at the leftmost split simply stays put,
-- and a silent no-op reads better in a 2-D layout than a jump to the far side.
local function move_split(dir)
    local from = vim.api.nvim_get_current_win()
    vim.cmd("wincmd " .. dir)
    local to = vim.api.nvim_get_current_win()
    if to == from then return end -- nothing that way; leave the layout alone

    local from_buf = vim.api.nvim_win_get_buf(from)
    local to_buf = vim.api.nvim_win_get_buf(to)
    local from_view = vim.api.nvim_win_call(from, vim.fn.winsaveview)
    local to_view = vim.api.nvim_win_call(to, vim.fn.winsaveview)

    vim.api.nvim_win_set_buf(from, to_buf)
    vim.api.nvim_win_call(from, function() vim.fn.winrestview(to_view) end)
    vim.api.nvim_win_set_buf(to, from_buf)
    vim.api.nvim_win_call(to, function() vim.fn.winrestview(from_view) end)

    vim.api.nvim_set_current_win(to) -- follow the buffer we just moved
end

for _, dir in ipairs({ "h", "j", "k", "l" }) do
    map("n", "<C-w><C-" .. dir .. ">", function() move_split(dir) end,
        { desc = "Move split " .. ({ h = "left", j = "down", k = "up", l = "right" })[dir] })
end

map("n", "<leader>+", "<cmd>resize +5<CR>", { desc = "Increase height" })
map("n", "<leader>-", "<cmd>resize -5<CR>", { desc = "Decrease height" })
map("n", "<leader><", "<cmd>vertical resize -5<CR>", { desc = "Decrease width" })
map("n", "<leader>>", "<cmd>vertical resize +5<CR>", { desc = "Increase width" })
map("n", "<leader>=", "<C-w>=", { desc = "Equalize splits" })


-- ─── History & clipboard ────────────────────────────────────────
-- Fuzzy history (fzf.vim), replacing the q: / q/ cmdline windows — those are
-- still there by typing q: / q/ directly when an editable buffer is wanted.
-- Command history works like <leader>: (fzf's :Commands): picking an entry
-- drops it into the command line and leaves the cursor there, so it can be
-- edited before running. Plain :History: does the opposite — <CR> executes at
-- once and only C-e puts it in the cmdline — and its sink is script-local, so
-- drive fzf#run with our own source and sink instead.
local function command_history()
    local items = {}
    for i = 1, vim.fn.histnr(":") do
        local entry = vim.fn.histget(":", -i)
        if entry ~= "" then
            items[#items + 1] = entry
        end
    end
    if #items == 0 then
        vim.notify("No command history yet", vim.log.levels.INFO)
        return
    end
    -- fzf#wrap applies g:fzf_layout and the colour setup, so this frames like
    -- every other fzf.vim picker. +m: one entry at a time. --scheme=history is
    -- what fzf.vim itself ranks history lists with.
    vim.fn["fzf#run"](vim.fn["fzf#wrap"]("history-command", {
        source = items,
        options = { "+m", "--prompt", "Hist:> ", "--scheme=history" },
        -- 'n' (no remap) + 't' (as if typed) — the same feedkeys fzf.vim uses
        -- for its C-e path, which leaves the cmdline open and unexecuted.
        sink = function(entry) vim.fn.feedkeys(":" .. entry, "nt") end,
    }))
end

lmap("n", ";", command_history, { desc = "Command history → cmdline (fzf)" })
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
