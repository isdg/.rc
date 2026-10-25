" ============================================================
"                 JUMPS, SELECTION, CLIPBOARD
" ============================================================
" Swap jump list navigation (Ctrl+I = back, Ctrl+O = forward)
nnoremap <C-i> <C-o>
nnoremap <C-o> <C-i>

" Emacs char motion, as in every readline prompt. <C-g>U keeps the undo step
" and dot-repeat whole.
nnoremap <C-f> l
nnoremap <C-b> h
inoremap <C-f> <C-g>U<Right>
inoremap <C-b> <C-g>U<Left>
cnoremap <C-f> <Right>
cnoremap <C-b> <Left>

" Emacs line keys in insert mode, from <C-g>U moves and <Del> so undo and
" dot-repeat stay whole. Fed when the key runs: an expr map is read too early
" under queued keys (macros). coc's menu claims <C-k> while it is open.
function! s:LineStart() abort
    call feedkeys(repeat("\<C-g>U\<Left>", charcol('.') - 1), 'ni')
endfunction
function! s:LineEnd() abort
    let n = strcharlen(getline('.')) - charcol('.') + 1
    call feedkeys(repeat("\<C-g>U\<Right>", n), 'ni')
endfunction
function! EmacsKillLine() abort
    let rest = getline('.')[col('.') - 1 :]
    if rest ==# ''
        return feedkeys("\<Del>", 'ni')
    endif
    call setreg('"', rest, 'c')
    call feedkeys(repeat("\<Del>", strcharlen(rest)), 'ni')
endfunction
inoremap <C-a> <Cmd>call <SID>LineStart()<CR>
inoremap <C-e> <Cmd>call <SID>LineEnd()<CR>
inoremap <C-k> <Cmd>call EmacsKillLine()<CR>
inoremap <C-d> <Del>
inoremap <C-y> <C-r><C-o>"

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
