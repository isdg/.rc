" ============================================================
"                           GOYO
" ============================================================
" Make Goyo fill the entire screen vertically and horizontally (no margins)
let g:goyo_height = '100%'  " Full vertical height

" Disable horizontal resizing by Goyo
let g:goyo_linenr = 1


" Map toggle to <leader>z
nnoremap <leader>z :Goyo<CR>

" Goyo shift left: <leader><number>z (e.g., <leader>5z → Goyo-5)
nnoremap <leader>1z :Goyo-1<CR>
nnoremap <leader>2z :Goyo-2<CR>
nnoremap <leader>3z :Goyo-3<CR>
nnoremap <leader>4z :Goyo-4<CR>
nnoremap <leader>5z :Goyo-5<CR>
nnoremap <leader>6z :Goyo-6<CR>
nnoremap <leader>7z :Goyo-7<CR>
nnoremap <leader>8z :Goyo-8<CR>
nnoremap <leader>9z :Goyo-9<CR>

" Goyo shift right: <leader><shift+number>z (e.g., <leader>%z → Goyo+5)
nnoremap <leader>!z :Goyo+1<CR>
nnoremap <leader>@z :Goyo+2<CR>
nnoremap <leader>#z :Goyo+3<CR>
nnoremap <leader>$z :Goyo+4<CR>
nnoremap <leader>%z :Goyo+5<CR>
nnoremap <leader>^z :Goyo+6<CR>
nnoremap <leader>&z :Goyo+7<CR>
nnoremap <leader>*z :Goyo+8<CR>
nnoremap <leader>(z :Goyo+9<CR>
