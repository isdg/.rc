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

" Emacs words are runs of 'iskeyword', as for w and i_CTRL-W. Positions are
" [lnum, byte col] insert-cursor slots: just past a word's end, or its start.
function! s:WordEnd() abort
    let [l, c] = searchpos('\k\>', 'cnW')
    if l == 0 | return [] | endif
    return [l, c - 1 + len(strcharpart(strpart(getline(l), c - 1), 0, 1))]
endfunction
function! s:WordStart() abort
    let [l, c] = searchpos('\<\k', 'bnW')
    return l == 0 ? [] : [l, c - 1]
endfunction
" Keys that walk the cursor to pos in <C-g>U steps. Across lines it is set
" directly instead: no insert-mode move keeps the undo step there anyway.
function! s:Walk(pos) abort
    let [l, c] = [line('.'), col('.') - 1]
    if a:pos[0] != l
        call cursor(a:pos[0], a:pos[1] + 1)
        return ''
    endif
    let [lo, hi] = [min([c, a:pos[1]]), max([c, a:pos[1]])]
    let n = strchars(strpart(getline(l), lo, hi - lo))
    return repeat(a:pos[1] > c ? "\<C-g>U\<Right>" : "\<C-g>U\<Left>", n)
endfunction
" Kills always delete forward with <Del>: <BS> would eat a whole indent
" level under 'softtabstop', so a backward kill walks to its start first.
function! s:KillTo(pos) abort
    let here = [line('.'), col('.') - 1]
    let fwd = a:pos[0] > here[0]
                \ || (a:pos[0] == here[0] && a:pos[1] > here[1])
    let [from, to] = fwd ? [here, a:pos] : [a:pos, here]
    let lines = getline(from[0], to[0])
    let lines[-1] = strpart(lines[-1], 0, to[1])
    let lines[0] = strpart(lines[0], from[1])
    let text = join(lines, "\n")
    if text ==# '' | return | endif
    call setreg('"', text, 'c')
    let walk = fwd ? '' : s:Walk(from)
    call feedkeys(walk . repeat("\<Del>", strchars(text)), 'ni')
endfunction
function! s:Move(find) abort
    let pos = call(a:find, [])
    if !empty(pos) | call feedkeys(s:Walk(pos), 'ni') | endif
endfunction
function! s:Kill(find) abort
    let pos = call(a:find, [])
    if !empty(pos) | call s:KillTo(pos) | endif
endfunction
inoremap <M-f> <Cmd>call <SID>Move(function('<SID>WordEnd'))<CR>
inoremap <M-b> <Cmd>call <SID>Move(function('<SID>WordStart'))<CR>
inoremap <M-d> <Cmd>call <SID>Kill(function('<SID>WordEnd'))<CR>
inoremap <M-BS> <Cmd>call <SID>Kill(function('<SID>WordStart'))<CR>

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
