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
" Ctrl rather than <leader> (same as nvim, keymaps/editor.lua): one keystroke
" shorter for a constant motion, and Ctrl+letter is keyed off the physical key,
" so it needs no Russian-layout twin the way <leader>hjkl did.
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

" Resize splits
" Height, width, and equalize all
nnoremap <leader>+ :resize +5<CR>
nnoremap <leader>- :resize -5<CR>
nnoremap <leader>< :vertical resize -5<CR>
nnoremap <leader>> :vertical resize +5<CR>
nnoremap <leader>= <C-w>=
