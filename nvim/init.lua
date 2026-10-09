-- ============================================================
--                   NEOVIM CONFIGURATION
-- ============================================================
-- Equivalent to vim/.vimrc — same features, keybindings, layout
--
-- Plugins (neovim-native equivalents):
--   CoC           → nvim-lspconfig + mason + nvim-cmp
--   NERDTree      → nvim-tree.lua
--   CocList       → fzf-lua
--   NERDCommenter → Comment.nvim
--   goyo.vim      → zen-mode.nvim
--   rainbow       → rainbow-delimiters.nvim
--   (new)         → nvim-treesitter

-- Everything else lives in rc.d/, run in the order of the two-digit prefix.
-- Found through this file's own path, so the repo can be anywhere.
local rc_d = vim.fn.fnamemodify(
    vim.fn.resolve(debug.getinfo(1, "S").source:sub(2)), ":p:h") .. "/rc.d"
local frags = vim.fn.glob(rc_d .. "/[0-9][0-9]-*.lua", false, true)
table.sort(frags)
for _, frag in ipairs(frags) do
    dofile(frag)
end
