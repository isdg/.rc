# fzf.vim analogs for zsh
#   fp  — :Files  file picker
#   fA  — :Rg     rg once, fuzzy-filter results
#   fa  — :RG     live ripgrep (re-runs on each keystroke)
#   fC  — :BLines analog; default opens editor, -p prints
#   hrb — hr reading list: fuzzy-pick an unread article, open it in nvim
#   hrv — hr reading list: open the nvim sidebar, scoped by `hr list` flags

if command -v bat >/dev/null 2>&1; then
   _fzf_preview='bat --color=always --style=numbers --highlight-line {2} {1}'
   _fzf_file_preview='bat --color=always --style=numbers {}'
else
   _fzf_preview='awk -v n={2} "NR>=n-10 && NR<=n+40 {printf \"%5d  %s\n\", NR, \$0}" {1} 2>/dev/null'
   _fzf_file_preview='awk "NR<=200 {printf \"%5d  %s\n\", NR, \$0}" {} 2>/dev/null'
fi

fp() {
   local files
   files=("${(@f)$(fd --type f --hidden --follow --exclude .git \
      | fzf --multi --ansi \
            --query "${1:-}" \
            --preview "$_fzf_file_preview" \
            --preview-window 'down:55%')}") || return
   [[ -n $files[1] ]] && "${EDITOR:-nvim}" "${files[@]}"
}

fA() {
   local out
   out=$(rg --column --line-number --no-heading --color=always --smart-case '' 2>/dev/null \
      | fzf --ansi --delimiter=: \
            --query "${1:-}" \
            --preview "$_fzf_preview" \
            --preview-window 'down:55%:+{2}-/2') || return
   local file line
   IFS=: read -r file line _ <<< "$out"
   [[ -n $file ]] && "${EDITOR:-nvim}" "+${line}" "$file"
}

fa() {
   local rg_cmd='rg --column --line-number --no-heading --color=always --smart-case'
   local out
   out=$(FZF_DEFAULT_COMMAND="$rg_cmd ''" \
      fzf --ansi --disabled --delimiter=: \
          --query "${1:-}" \
          --bind "change:reload:sleep 0.1; $rg_cmd -- {q} || true" \
          --preview "$_fzf_preview" \
          --preview-window 'down:55%:+{2}-/2') || return
   local file line
   IFS=: read -r file line _ <<< "$out"
   [[ -n $file ]] && "${EDITOR:-nvim}" "+${line}" "$file"
}

fC() {
   local print_only=0
   while [[ $1 == -* ]]; do
      case $1 in
         -p|--print) print_only=1; shift ;;
         --) shift; break ;;
         *) break ;;
      esac
   done

   # BLines mode: fC FILE → fuzzy-pick a line, open editor at it
   if [[ -f $1 ]]; then
      local file=$1
      local preview
      if command -v bat >/dev/null 2>&1; then
         preview="bat --color=always --style=numbers --highlight-line {1} ${(q)file}"
      else
         preview="awk -v n={1} 'NR>=n-10 && NR<=n+40 {printf \"%5d  %s\\n\", NR, \$0}' ${(q)file}"
      fi
      local pick
      pick=$(awk '{printf "%d:%s\n", NR, $0}' "$file" \
         | fzf --ansi --delimiter=: --with-nth=2.. \
               --no-sort --tiebreak=index --layout=reverse \
               --preview "$preview" \
               --preview-window "right:60%:+{1}-/2") || return
      local line=${pick%%:*}
      [[ -z $line ]] && return
      if (( print_only )); then
         print -r -- "$line"
      else
         "${EDITOR:-nvim}" "+${line}" "$file"
      fi
      return
   fi

   # Pipe mode: ... | fC
   local sel
   sel=$(fzf --ansi --no-sort --tiebreak=index --layout=reverse "$@") || return
   if (( print_only )); then
      print -r -- "$sel"
      return
   fi
   local file line rest
   IFS=: read -r file line rest <<< "$sel"
   if [[ -f $file && $line == <-> ]]; then
      "${EDITOR:-nvim}" "+${line}" "$file"
   elif [[ -f $sel ]]; then
      "${EDITOR:-nvim}" "$sel"
   else
      print -r -- "$sel"
   fi
}

hrb() {
   # Fuzzy-pick an article from the hr reading list (`hr list --tsv` columns:
   # path<TAB>feed<TAB>date<TAB>read<TAB>fav<TAB>title; read and unread both)
   # and open it in nvim, where the hr.vim plugin is loaded (sidebar: `nr`).
   command -v hr >/dev/null 2>&1 || { print -u2 "hr not found"; return 1 }
   local preview
   if command -v bat >/dev/null 2>&1; then
      preview='bat --color=always --style=plain --language=markdown {1}'
   else
      preview='cat {1}'
   fi
   # Reformat to `path<TAB>date · feed · title`: field 1 stays the path (for
   # preview/open via {1}), field 2 is the display column with real spaces —
   # fzf --with-nth joining would otherwise concatenate the columns.
   local out file
   out=$(hr list --tsv 2>/dev/null \
      | awk -F'\t' -v OFS='\t' '{ print $1, $3 "  ·  " $2 "  ·  " $6 }' \
      | fzf --ansi --delimiter='\t' --with-nth='2..' \
            --query "${1:-}" \
            --prompt 'hr> ' --layout=reverse \
            --preview "$preview" \
            --preview-window 'down:70%') || return
   file=${out%%$'\t'*}
   [[ -n $file ]] && "${EDITOR:-nvim}" "$file"
}

hrv() {
   # Open the hr reading-list sidebar in nvim, scoped by any `hr list` flags:
   #   hrv                            whole vault
   #   hrv --group books              one shelf (subtree: humans covers
   #                                  humans/archive)
   #   hrv --feed matklad,danluu      one or more authors
   #   hrv --group sites --unread     flags compose
   # hr owns the flag vocabulary — hr.vim forwards them to `hr list` — so
   # anything `hr list` accepts works here with no change to this function.
   # Values must not contain spaces: they cross into nvim as :HrStart args,
   # which split on whitespace. For those, set g:hr_filter in nvim instead.
   #
   # Unlike hrb (fuzzy-pick one article), this opens the panel so you can
   # browse and act on the list with its buffer keys.
   command -v hr >/dev/null 2>&1 || { print -u2 "hrv: hr not found"; return 1 }
   # Validate against the CLI first (~0.1s on a 10k-article vault): a typo'd
   # flag becomes an error here rather than a silently empty sidebar inside
   # nvim, where it reads as a broken vault.
   if (( $# )); then
      hr list --json "$@" >/dev/null || return 1
   fi
   "${EDITOR:-nvim}" -c "HrStart $*"
}
