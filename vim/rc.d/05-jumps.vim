" ============================================================
"                 JUMPS, SELECTION, CLIPBOARD
" ============================================================
" Swap jump list navigation (Ctrl+I = back, Ctrl+O = forward)
nnoremap <C-i> <C-o>
nnoremap <C-o> <C-i>

" Reselect last visual selection
nnoremap <leader>v gv

" Yank to the system clipboard, where vim was built with one
if has('clipboard')
  vnoremap <leader>y "+y
endif
