" ============================================================
"                     BUILT-IN STAND-INS
" ============================================================
" The plugin keys on vim's own tools (netrw, :find, :ls, :vimgrep, q:). The
" plugin fragments after 09-plugins.vim remap the same keys, so these only
" remain where the plugin fragments are not enabled.
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

nnoremap <leader>R :source $MYVIMRC<CR>
