" ============================================================
"             RUSSIAN LAYOUT REMAPPING
" ============================================================
" Allows Vim commands on Russian keyboard layout
" (maps Cyrillic keys to Vim commands)

"noremap й q | noremap ц w | noremap у e | noremap к r | noremap е t
"noremap н y | noremap г u | noremap ш i | noremap щ o | noremap з p
"noremap х [ | noremap ъ ] | noremap ф a | noremap ы s | noremap в d
"noremap а f | noremap п g | noremap р h | noremap о j | noremap л k
"noremap д l | noremap ж ; | noremap э ' | noremap ё \
"noremap я z | noremap ч x | noremap с c | noremap м v
"noremap и b | noremap т n | noremap ь m | noremap б , | noremap ю .

"" Uppercase
"noremap Й Q | noremap Ц W | noremap У E | noremap К R | noremap Е T
"noremap Н Y | noremap Г U | noremap Ш I | noremap Щ O | noremap З P
"noremap Х { | noremap Ъ } | noremap Ф A | noremap Ы S | noremap В D
"noremap А F | noremap П G | noremap Р H | noremap О J | noremap Л K
"noremap Д L | noremap Ж : | noremap Э " | noremap Я Z
"noremap Ч X | noremap С C | noremap М V | noremap И B | noremap Т N
"noremap Ь M | noremap Б < | noremap Ю >

" =========================================
" Russian keyboard → English key remap
" =========================================

let ru_eng = {
\ 'й':'q', 'ц':'w', 'у':'e', 'к':'r', 'е':'t', 'н':'y', 'г':'u', 'ш':'i', 'щ':'o', 'з':'p', 'х':'[', 'ъ':']',
\ 'ф':'a', 'ы':'s', 'в':'d', 'а':'f', 'п':'g', 'р':'h', 'о':'j', 'л':'k', 'д':'l', 'ж':';', 'э':"'",
\ 'я':'z', 'ч':'x', 'с':'c', 'м':'v', 'и':'b', 'т':'n', 'ь':'m', 'б':',', 'ю':'.', 'ё':'`'
\ }

let ru_eng_upper = {
\ 'Й':'Q', 'Ц':'W', 'У':'E', 'К':'R', 'Е':'T', 'Н':'Y', 'Г':'U', 'Ш':'I', 'Щ':'O', 'З':'P', 'Х':'{', 'Ъ':'}',
\ 'Ф':'A', 'Ы':'S', 'В':'D', 'А':'F', 'П':'G', 'Р':'H', 'О':'J', 'Л':'K', 'Д':'L', 'Ж':':', 'Э':'"',
\ 'Я':'Z', 'Ч':'X', 'С':'C', 'М':'V', 'И':'B', 'Т':'N', 'Ь':'M', 'Б':'<', 'Ю':'>', 'Ё':'~'
\ }

let ru_eng_final = extend(copy(ru_eng), ru_eng_upper)

for [ru, en] in items(ru_eng_final)
    execute 'noremap' ru en
    execute 'vnoremap' ru en
    execute 'onoremap' ru en
endfor
