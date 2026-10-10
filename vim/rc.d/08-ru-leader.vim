" ============================================================
"                        RUSSIAN VIM
" ============================================================
"
"
" Insert current date in format: Mon 18 Mar 2024 at 16:58:58
command! InsertDate execute "normal! a" . strftime("%a %d %b %Y at %H:%M:%S")

nnoremap <Leader>nt :InsertDate<CR>

" Insert timestamp in format: 2022-08-22 13:54
nnoremap <Leader>nT :execute "normal! a" . strftime("%Y-%m-%d %H:%M")<CR>

" English → Russian key mapping (for leader duplication)
let g:eng_to_ru_for_leader = {
\ 'q':'й', 'w':'ц', 'e':'у', 'r':'к', 't':'е', 'y':'н', 'u':'г', 'i':'ш', 'o':'щ', 'p':'з',
\ 'a':'ф', 's':'ы', 'd':'в', 'f':'а', 'g':'п', 'h':'р', 'j':'о', 'k':'л', 'l':'д',
\ 'z':'я', 'x':'ч', 'c':'с', 'v':'м', 'b':'и', 'n':'т', 'm':'ь'
\ }

" English → Russian key mapping (for leader duplication)
let g:eng_to_ru_upper_for_leader = {
\ 'Q':'Й', 'W':'Ц', 'E':'У', 'R':'К', 'T':'Е', 'Y':'Н', 'U':'Г', 'I':'Ш', 'O':'Щ', 'P':'З',
\ 'A':'Ф', 'S':'Ы', 'D':'В', 'F':'А', 'G':'П', 'H':'Р', 'J':'О', 'K':'Л', 'L':'Д',
\ 'Z':'Я', 'X':'Ч', 'C':'С', 'V':'М', 'B':'И', 'N':'Т', 'M':'Ь'
\ }


let ru_jumps = {
\ 'вв':'dd', 'фф':'yy', 'сс':'cc','пп':'gg', 'яя': 'zz'
\ }

for [ru, en] in items(ru_jumps)
    execute 'nnoremap ' . ru . ' ' . en
    execute 'vnoremap ' . ru . ' ' . en
    execute 'vnoremap ' . ru . ' ' . en
endfor

let eng_to_ru_final_for_leader = extend(copy(eng_to_ru_for_leader), eng_to_ru_upper_for_leader)

" Duplicate leader mappings for Russian layout
function! DuplicateLeaderRu(maps)
    for [eng, ru] in items(a:maps)
        " Normal mode
        let map_n = maparg('<leader>'.eng, 'n')
        if !empty(map_n)
            execute 'nnoremap <leader>'.ru.' '.map_n
        endif

        " Visual mode
        let map_v = maparg('<leader>'.eng, 'v')
        if !empty(map_v)
            execute 'vnoremap <leader>'.ru.' '.map_v
        endif

        " Operator-pending mode
        let map_o = maparg('<leader>'.eng, 'o')
        if !empty(map_o)
            execute 'onoremap <leader>'.ru.' '.map_o
        endif
    endfor
endfunction

call DuplicateLeaderRu(eng_to_ru_final_for_leader)
