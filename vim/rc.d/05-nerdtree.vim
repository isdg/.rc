" ============================================================
"                       NERD TREE
" ============================================================
" Tree on <leader>t, freed by dropping the (unused, long commented-out) tab
" mappings. Same key in nvim, see nvim/lua/keymaps/tree.lua.
" Comments go above the mapping, never after it: :map has no trailing-comment
" syntax, so `" Toggle NERDTree` used to be part of the mapped keys.
nnoremap <leader>t :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
let NERDTreeShowHidden=1
let g:NERDTreeWinSize=40
" Close the tree once a file is opened — the explorer is for picking a file, not
" for living next to the buffer. Matches nvim-tree's actions.open_file.quit_on_open
" (nvim/lua/plugins/nav.lua). Reopen with <leader>t.
let NERDTreeQuitOnOpen=1
autocmd FileType nerdtree setlocal number
