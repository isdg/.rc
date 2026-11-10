# Russian layout in vi mode: every vicmd, viopp and visual binding gets a
# twin on the same physical keys under ЙЦУКЕН, so Esc then вц is dw. The
# mirror runs on the first Esc (17-vimode.zsh), not at startup: it forks,
# and by then every leader and fzf key is bound.
typeset -A _ru_keys=(
   q й w ц e у r к t е y н u г i ш o щ p з '[' х ']' ъ
   a ф s ы d в f а g п h р j о k л l д ';' ж "'" э
   z я x ч c с v м b и n т m ь ',' б '.' ю '#' №
   Q Й W Ц E У R К T Е Y Н U Г I Ш O Щ P З '{' Х '}' Ъ
   A Ф S Ы D В F А G П H Р J О K Л L Д ':' Ж '"' Э
   Z Я X Ч C С V М B И N Т M Ь '<' Б '>' Ю
)
# Apple's Russian layout puts ё on \, the PC one Linux uses on `.
if [[ $OSTYPE == darwin* ]]; then
   _ru_keys+=('\' ё '|' Ё)
else
   _ru_keys+=('`' ё '~' Ё)
fi

# ASCII the layout moves ($ types %, / types . on PC) has no twin: those
# characters are vi commands already.
function _ru_mirror() {
   # extended_glob (01-options.zsh) would read the ^ below as negation.
   emulate -L zsh
   local line key out c
   local -a words
   local listing=$(bindkey -LM vicmd; bindkey -LM viopp; bindkey -LM visual)
   for line in ${(f)listing}; do
      words=(${(z)line})
      (( ${words[(I)-R]} )) && continue
      key=${(g:ce:)${(Q)words[-2]}}
      [[ $key == *[[:cntrl:]]* ]] && continue
      out=
      for c in ${(s::)key}; do out+=${_ru_keys[$c]:-$c}; done
      [[ $out == $key ]] && continue
      bindkey ${words[2,-3]} ${${out//\\/\\\\}//^/\\^} ${(Q)words[-1]}
   done
   unfunction _ru_mirror
   unset _ru_keys
}

bindkey -M viins 'о' vi-insert-j
bindkey -M viins 'О' vi-escape-jJ
