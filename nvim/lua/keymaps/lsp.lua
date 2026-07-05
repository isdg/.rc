-- ============================================================
--                  LSP keymaps (on attach)
-- ============================================================
local map = require("keymaps.leader").map

vim.api.nvim_create_autocmd("LspAttach", {
   callback = function(ev)
      local opts = { buffer = ev.buf, silent = true }
      map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
      map("n", "gy", "<cmd>Telescope lsp_type_definitions<CR>", opts)
      map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
      map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
      map("n", "K", vim.lsp.buf.hover, opts)
      map("n", "ge", function()
         vim.diagnostic.open_float({ scope = "cursor" })
      end, opts)
      map("n", "]d", vim.diagnostic.goto_next, opts)
      map("n", "[d", vim.diagnostic.goto_prev, opts)
   end,
})
