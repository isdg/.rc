-- ============================================================
--                   NEOVIM CONFIGURATION
-- ============================================================
-- Equivalent to vim/.vimrc — same features, keybindings, layout
--
-- Plugins (neovim-native equivalents):
--   CoC           → nvim-lspconfig + mason + nvim-cmp
--   NERDTree      → nvim-tree.lua
--   fzf.vim       → telescope.nvim
--   NERDCommenter → Comment.nvim
--   goyo.vim      → zen-mode.nvim
--   rainbow       → rainbow-delimiters.nvim
--   (new)         → nvim-treesitter

require("options")
require("russian")

-- Sibling files in ../vim, resolved via this file's real path (so the
-- dotfiles dir doesn't have to be ~/.dotfiles):
--   fzf-layout.vim  — fzf.vim window/preview layout (shared with vim/.vimrc)
do
   local this_file = vim.fn.resolve(debug.getinfo(1, "S").source:sub(2))
   local dotfiles_dir = vim.fn.fnamemodify(this_file, ":p:h:h")
   vim.cmd("source " .. dotfiles_dir .. "/vim/fzf-layout.vim")
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
   vim.fn.system({
      "git", "clone", "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", lazypath,
   })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({ { import = "plugins" } })
require("keymaps")

-- Theme mode (dark|light) from the single source of truth (~/.config/isg/theme,
-- written by toggle_theme.sh). Read at startup so new instances always match the
-- current theme — no sed of this file. Falls back to light.
local function isg_theme_mode()
   local cfg = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")
   local fh = io.open(cfg .. "/isg/theme", "r")
   if not fh then
      return "light"
   end
   local m = (fh:read("l") or ""):gsub("%s+", "")
   fh:close()
   return (m == "dark" or m == "light") and m or "light"
end
vim.cmd("colorscheme vs_" .. isg_theme_mode())
