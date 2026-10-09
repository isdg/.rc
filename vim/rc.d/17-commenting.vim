" ============================================================
"                      COMMENTING
" ============================================================
" Comment style, to match nvim's Comment.nvim: a space after the delimiter
" ("-- x", not "--x") and comments aligned at the left margin rather than at the
" line's indent-stripped start. Without NERDSpaceDelims the two editors produce
" different text for the same key.
let g:NERDSpaceDelims = 1
let g:NERDDefaultAlign = 'left'
" Also toggle based on all selected lines, so a partly-commented block
" comments the rest instead of uncommenting — Comment.nvim's behaviour.
let g:NERDToggleCheckAllLines = 1

" Toggle comment on <C-_> (what Ctrl-/ sends), normal and visual — the same key
" nvim uses (nvim/rc.d/07-keys-edit.lua maps it onto Comment.nvim's gcc/gc).
" nmap/vmap rather than the noremap forms: <Plug>NERDCommenterToggle is itself a
" mapping, so the recursive form is the documented way to invoke it. Note :map
" has no trailing-comment syntax — a `" text` suffix lands inside the RHS.
nmap <C-_> <Plug>NERDCommenterToggle
vmap <C-_> <Plug>NERDCommenterToggle

" nvim's keys too (Comment.nvim): gcc toggles the current line — with a count,
" that many lines — and gc toggles a visual selection.
" `gc{motion}` (gcap, gc3j) is NOT provided: NERDCommenter works on lines and
" selections, not as an operator. tpope/vim-commentary is the drop-in that adds
" motions, if that turns out to matter.
nmap gcc <Plug>NERDCommenterToggle
xmap gc  <Plug>NERDCommenterToggle
