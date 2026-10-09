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

-- Everything else lives in rc.d/, run in prefix order from ~/.config/rc/nvim,
-- where .rcboot links the ones its level enables. A checkout never
-- bootstrapped runs all of rc.d/, found through this file's own path.
local rc_d = vim.fn.expand("~/.config/rc/nvim")
if vim.fn.isdirectory(rc_d) == 0 then
    rc_d = vim.fn.fnamemodify(
        vim.fn.resolve(debug.getinfo(1, "S").source:sub(2)), ":p:h") .. "/rc.d"
end
local frags = vim.fn.glob(rc_d .. "/[0-9][0-9]-*.lua", false, true)
table.sort(frags)
for _, frag in ipairs(frags) do
    dofile(frag)
end
