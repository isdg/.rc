" ============================================================
"                        SESSIONS
" ============================================================
let g:session_file = expand('~/.vim/session.vim')

" Save session, creating ~/.vim on a box that has none
command! SessionSave call mkdir(expand('~/.vim'), 'p')
      \ | mksession! ~/.vim/session.vim | echo "Session saved!"
nnoremap <leader><Tab> :SessionSave<CR>

" Load session
nnoremap <leader><S-Tab> :source ~/.vim/session.vim<CR>:echo "Session loaded!"<CR>
