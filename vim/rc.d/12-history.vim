" ============================================================
"                HISTORY & CLIPBOARD
" ============================================================
" Fuzzy history and pickers on the same keys as nvim (keymaps/editor.lua):
" ";" command history, "/" search history, "J" the jumplist, ":" every ex
" command. All four come from fzf.vim, which vim already loads — the plugin
" ships Jumps/Commands/History just like the copy nvim uses.
"
" q: and q/ are still there by typing them directly, for when the editable
" cmdline window is what's wanted.
"
" (These two lines used to read `nnoremap <leader>; q:    " Command history`.
"  :map has no trailing-comment syntax, so that text was part of the RHS and
"  got typed into the cmdline window on every press.)
nnoremap <leader>; :History:<CR>
nnoremap <leader>/ :History/<CR>
nnoremap <leader>J :Jumps<CR>
nnoremap <leader>: :Commands<CR>

" Swap jump list navigation (Ctrl+I = back, Ctrl+O = forward)
nnoremap <C-i> <C-o>
nnoremap <C-o> <C-i>

vnoremap <leader>y "+y   " Yank to system clipboard

nnoremap <leader>v gv    " Reselect last visual selection
