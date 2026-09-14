-- ============================================================
--                  FUZZY FIND (Telescope)
-- ============================================================
local leader = require("keymaps.leader")
local lmap = leader.lmap

-- f, not p: <leader>f is the letter every distro spends on finding (Telescope's
-- own <leader>ff, and the file/find group in LazyVim, NvChad, AstroNvim). p only
-- ever meant "the leader spelling of <C-p>" — a mnemonic, not a name.
lmap("n", "f", "<cmd>Files<CR>", { desc = "Find files" })
lmap("n", "b", "<cmd>Buffers<CR>", { desc = "Find buffers" })
-- Lowercase = this buffer, uppercase = wider scope, for both pairs:
--   e / E   symbols in this file / across the workspace   (LSP)
--   l / L   lines in this buffer / across open buffers    (fzf)
--
-- FzfBLinesPreview / FzfLinesPreview (vim/fzf-layout.vim) rather than plain
-- :BLines and :Lines — fzf.vim ships both without a preview pane.
lmap("n", "l", "<cmd>call FzfBLinesPreview()<CR>", { desc = "Search lines in buffer" })
lmap("n", "L", "<cmd>call FzfLinesPreview()<CR>", { desc = "Search lines in open buffers" })
lmap("n", "a", "<cmd>RG<CR>", { desc = "Live ripgrep" })
lmap("n", "A", "<cmd>Rg<CR>", { desc = "Ripgrep (fzf filter)" })
lmap("n", "E", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", { desc = "Workspace symbols" })
-- Telescope issues its own documentSymbol request. This used to precede it with
-- a blocking buf_request_sync to find the symbol under the cursor, but the name
-- it computed was never passed anywhere — dead work, a 1s worst-case stall, and
-- the source of nvim 0.11's "position_encoding param is required" warning (via
-- make_position_params). To actually narrow the picker to the enclosing symbol,
-- pass { default_text = <name> } here.
lmap("n", "e", function() require("telescope.builtin").lsp_document_symbols() end,
    { desc = "Document symbols" })
lmap("n", "i", function() require("breadcrumb").show() end, { desc = "Show breadcrumb" })
-- H for history, free since the tool keys moved into <leader><leader>
-- (keymaps/plugins.lua). B only ever meant "the uppercase of b", naming this
-- after a neighbouring key instead of after the thing it opens.
lmap("n", "H", "<cmd>History<CR>", { desc = "File history (fzf)" })

-- -- Search across open buffers (equivalent to :Lines)
-- lmap("n", "e", function()
--    require("telescope.builtin").live_grep({ grep_open_files = true })
-- end, { desc = "Search open buffers" })

-- <C-p> deliberately unmapped: file finding lives on <leader>f only, and
-- leaving <C-p> alone restores its builtin meaning (previous line / insert-mode
-- keyword completion).
