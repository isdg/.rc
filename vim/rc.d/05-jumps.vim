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
  " Visual pastes with "+P so the unnamed register is left alone.
  nnoremap <leader>p "+p
  vnoremap <leader>p "+P

  " Buffer name, absolute path, or cwd-relative path onto the clipboard.
  function! s:YankPath(modifier) abort
    let l:path = expand('%' . a:modifier)
    if empty(l:path)
      echohl WarningMsg | echo 'Buffer has no file name' | echohl None
      return
    endif
    call setreg('+', l:path)
    echo 'Copied ' . l:path
  endfunction
  nnoremap <silent> <leader>yf :<C-u>call <SID>YankPath(':t')<CR>
  nnoremap <silent> <leader>yp :<C-u>call <SID>YankPath(':p')<CR>
  nnoremap <silent> <leader>yP :<C-u>call <SID>YankPath(':.')<CR>
endif
