" ============================================================
"                        SESSIONS
" ============================================================
let g:session_file = expand('~/.vim/session.vim')

" Save session
nnoremap <leader><Tab> :mksession! ~/.vim/session.vim<CR>:echo "Session saved!"<CR>

" Load session
nnoremap <leader><S-Tab> :source ~/.vim/session.vim<CR>:echo "Session loaded!"<CR>
