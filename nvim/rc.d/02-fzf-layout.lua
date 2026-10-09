-- Sibling files in the repo's vim/, resolved via this file's real path (so the
-- dotfiles dir doesn't have to be ~/.rc):
--   fzf-layout.vim  — fzf.vim window/preview layout (shared with vim/.vimrc)
do
    local this_file = vim.fn.resolve(debug.getinfo(1, "S").source:sub(2))
    local dotfiles_dir = vim.fn.fnamemodify(this_file, ":p:h:h:h")
    vim.cmd("source " .. dotfiles_dir .. "/vim/fzf-layout.vim")
end
