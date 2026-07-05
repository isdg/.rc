-- ============================================================
--                       GIT
-- ============================================================
return {
   -- Git: gutter signs, blame popup, hunk preview
   {
      "lewis6991/gitsigns.nvim",
      config = function()
         require("gitsigns").setup({
            current_line_blame = false,
         })
      end,
   },

   -- Git: full commit/diff browser
   {
      "sindrets/diffview.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
         local actions = require("diffview.actions")
         require("diffview").setup({
            keymaps = {
               file_history_panel = {
                  -- Press <leader>go on a commit to see ALL files in that commit
                  { "n", "<leader>go", function()
                     -- Get commit hash from current line
                     local line = vim.fn.getline(".")
                     local hash = line:match("(%x%x%x%x%x%x%x+)")
                     if hash then
                        vim.cmd("DiffviewClose")
                        vim.schedule(function()
                           vim.cmd("DiffviewOpen " .. hash .. "^!")
                        end)
                     end
                  end, { desc = "Open commit (all files)" } },
               },
            },
         })
      end,
   },

   -- Git: unified diff & git commands (:Git diff, :Git blame, :Git log)
   { "tpope/vim-fugitive" },

   -- Git: commit message popup on current line
   { "rhysd/git-messenger.vim" },
}
