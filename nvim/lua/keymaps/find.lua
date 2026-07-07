-- ============================================================
--                  FUZZY FIND (Telescope)
-- ============================================================
local leader = require("keymaps.leader")
local map, lmap = leader.map, leader.lmap

lmap("n", "p", "<cmd>Files<CR>", { desc = "Find files" })
lmap("n", "b", "<cmd>Buffers<CR>", { desc = "Find buffers" })
lmap("n", "C", "<cmd>BLines<CR>", { desc = "Search in buffer" })
lmap("n", "a", "<cmd>RG<CR>", { desc = "Live ripgrep" })
lmap("n", "A", "<cmd>Rg<CR>", { desc = "Ripgrep (fzf filter)" })
lmap("n", "e", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", { desc = "Workspace symbols" })
lmap("n", "c", function()
   local params = vim.lsp.util.make_position_params()
   local results = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)
   local cursor = vim.api.nvim_win_get_cursor(0)
   local row = cursor[1] - 1
   local name = ""
   local function find_symbol(symbols)
      for _, s in ipairs(symbols or {}) do
         local range = s.range or (s.location and s.location.range)
         if range and row >= range.start.line and row <= range["end"].line then
            name = s.name
            if s.children then find_symbol(s.children) end
         end
      end
   end
   for _, res in pairs(results or {}) do
      find_symbol(res.result)
   end
   require("telescope.builtin").lsp_document_symbols()
end, { desc = "Document symbols (focused)" })
lmap("n", "i", function() require("breadcrumb").show() end, { desc = "Show breadcrumb" })
lmap("n", "B", "<cmd>History<CR>", { desc = "Recent files (fzf)" })

-- -- Search across open buffers (equivalent to :Lines)
-- lmap("n", "e", function()
--    require("telescope.builtin").live_grep({ grep_open_files = true })
-- end, { desc = "Search open buffers" })

map("n", "<C-p>", "<cmd>Files<CR>", { desc = "Find files" })
