" ============================================================
"                     BUILT-IN STAND-INS
" ============================================================
" The plugin keys on vim's own tools (netrw, :find, :ls, :vimgrep, q:). The
" plugin fragments after 09-plugins.vim remap the same keys, so these only
" remain where plugins are not loaded, as in .vimrc.core.
set wildmode=full
set path+=**
set wildignore+=*/.git/*,*/node_modules/*,*/build/*,*/target/*,*.o,*.pyc

nnoremap <leader>t :Explore<CR>
nnoremap <leader>f :find *
nnoremap <leader>b :ls<CR>:b
nnoremap <leader>a :vimgrep // **<Left><Left><Left><Left>
nnoremap <leader>A :copen<CR>
nnoremap <leader>F mzgg=Gg`z
nnoremap <leader>; q:
nnoremap <leader>/ q/

" Reload whichever vimrc vim started with: ~/.vimrc or .vimrc.core.
nnoremap <leader>R :source $MYVIMRC<CR>
