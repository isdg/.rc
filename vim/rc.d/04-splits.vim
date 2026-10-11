" ============================================================
"                   SPLIT MANAGEMENT
" ============================================================
" nnoremap <leader>e :vsplit<CR>        " Vertical split
" nnoremap <leader>r :split<CR>         " Horizontal split
" nnoremap <leader>f :only<CR>          " Keep only current split


" ============================================================
"               INSERT MODE NAVIGATION
" ============================================================
" inoremap <C-h> <Left>
" inoremap <C-l> <Right>
" inoremap <C-j> <Down>
" inoremap <C-k> <Up>

" Move between splits
" Ctrl rather than <leader> (same as nvim, nvim/rc.d/04-keys-editor.lua): one
" keystroke shorter for a constant motion, and Ctrl+letter is keyed off the
" physical key, so it needs no Russian-layout twin the way <leader>hjkl did.
" <C-l> gives up vim's redraw-screen default; :redraw! covers it.
" <C-h> is distinct from <BS> here (Ghostty sends 0x7f for Backspace) — checked
" with separate mappings: 0x08 fires <C-h>, 0x7f fires <BS>.
" Insert mode is untouched: <C-j>/<C-k> there stay coc's popup navigation.
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" jJ leaves insert mode, as in nvim, zsh and Claude Code.
inoremap jJ <Esc>

" <C-w> bent to match nvim's split layer, and through it tmux's, verb for
" verb. The reasoning behind each key is in nvim/rc.d/04-keys-editor.lua.
"   C-hjkl move  HJKL resize  sv/sh split  ; last  o cycle  1-9 jump
"
" Moving swaps buffers, carrying each window's view across by hand.
function! s:MoveSplit(dir) abort
  let l:from = win_getid()
  execute 'wincmd' a:dir
  let l:to = win_getid()
  if l:to == l:from
    return
  endif
  let l:to_buf = bufnr()
  let l:to_view = winsaveview()
  call win_gotoid(l:from)
  let l:from_buf = bufnr()
  let l:from_view = winsaveview()
  execute 'buffer' l:to_buf
  call winrestview(l:to_view)
  call win_gotoid(l:to)
  execute 'buffer' l:from_buf
  call winrestview(l:from_view)
endfunction

for s:dir in ['h', 'j', 'k', 'l']
  execute printf('nnoremap <silent> <C-w><C-%s> '
        \ . ':<C-u>call <SID>MoveSplit(%s)<CR>', s:dir, string(s:dir))
endfor

" HJKL name where the border travels, as tmux's resize-pane does; a count is
" that many cells.
let s:resize = {
      \ 'H': 'vertical resize -', 'L': 'vertical resize +',
      \ 'J': 'resize +', 'K': 'resize -'}
for [s:key, s:cmd] in items(s:resize)
  execute printf('nnoremap <silent> <C-w>%s '
        \ . ':<C-u>execute %s . (v:count ? v:count : 5)<CR>',
        \ s:key, string(s:cmd))
endfor
unlet s:dir s:resize s:key s:cmd

nnoremap <C-w>sv :vsplit<CR>
nnoremap <C-w>sh :split<CR>
nnoremap <C-w>; <C-w>p
nnoremap <C-w>o <C-w>w
nnoremap <C-w>E <C-w>=

" Clamped: :9wincmd w with four open is an E16.
for s:i in range(1, 9)
  execute printf('nnoremap <silent> <C-w>%d '
        \ . ':<C-u>execute min([%d, winnr("$")]) . "wincmd w"<CR>', s:i, s:i)
endfor
unlet s:i
