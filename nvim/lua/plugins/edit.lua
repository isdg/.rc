-- ============================================================
--                  EDITING / FORMATTING
-- ============================================================
return {
   -- Commenting (replaces NERDCommenter)
   {
      "numToStr/Comment.nvim",
      config = function()
         require("Comment").setup()
      end,
   },

   -- Zen mode (Goyo — commented out)
   -- {
   --    "junegunn/goyo.vim",
   --    config = function()
   --       vim.g.goyo_width = 80
   --       vim.g.goyo_height = "100%"
   --       vim.g.goyo_linenr = 1
   --    end,
   -- },

   -- Zen mode
   {
      "isdg/zen-mode.nvim",
      config = function()
         require("zen-mode").setup({
            window = {
               -- A floating window's width is the *total* width -- the
               -- line-number gutter and sign column are drawn inside it. So
               -- plain `width = 80` gives only ~74 cols of text. Return
               -- 80 + gutters so the actual TEXT column is a true 80.
               width = function()
                  local text = 80
                  local gutter = 0
                  if vim.wo.number or vim.wo.relativenumber then
                     -- numberwidth, or wider if the file needs more digits
                     local digits = #tostring(vim.api.nvim_buf_line_count(0)) + 1
                     gutter = gutter + math.max(vim.o.numberwidth, digits)
                  end
                  local sc = vim.wo.signcolumn
                  if sc == "yes" or sc == "auto" then
                     gutter = gutter + 2
                  else
                     local n = sc:match("^yes:(%d+)")
                     if n then gutter = gutter + 2 * tonumber(n) end
                  end
                  return text + gutter
               end,
               col_offset = -20,
               options = {
                  number = true,
                  wrap = true,
                  linebreak = true,
                  breakindent = true,
               },
            },
         })
      end,
   },

   -- Rainbow delimiters (replaces luochen1990/rainbow)
   { "HiPhish/rainbow-delimiters.nvim" },

   -- Formatter (prettier for markdown). Formatting is on demand only —
   -- <leader>F, see keymaps/edit.lua. No format_on_save here on purpose: a save
   -- should write the file and nothing else. The per-filetype opt-outs this used
   -- to need (TS/JS via a conform_on_save_disabled flag) went with it.
   {
      "stevearc/conform.nvim",
      config = function()
         require("conform").setup({
            formatters_by_ft = {
               markdown = { "prettier" },
               python = { "ruff_format", "ruff_organize_imports" },
            },
         })
      end,
   },
}
