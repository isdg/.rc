# fzf.vim analogs for zsh
#   fp  — :Files  file picker
#   fA  — :Rg     rg once, fuzzy-filter results
#   fa  — :RG     live ripgrep (re-runs on each keystroke)
#   hrb — hr reading list: fuzzy-pick an unread article, open it in nvim
#   hrv — hr reading list: open the nvim sidebar, scoped by `hr list` flags
# plus the ZLE pickers behind the vicmd <Space> leader (see the end of the file).

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

# The fA / fa pickers, shared with the <Space>A / <Space>a widgets below. Each
# prints the picked `file:line:col:text` rg line.
_fzf_rg_filter() {
   rg --column --line-number --no-heading --color=always --smart-case '' 2>/dev/null \
      | fzf --ansi --delimiter=: \
            --query "${1:-}" \
            --preview "$_fzf_preview" \
            --preview-window 'down:55%:+{2}-/2'
}

_fzf_rg_live() {
   local rg_cmd='rg --column --line-number --no-heading --color=always --smart-case'
   # Not FZF_DEFAULT_COMMAND: fzf skips it unless stdin is a tty, and a ZLE
   # widget's stdin is /dev/null, so <Space>a would open empty.
   : | fzf --ansi --disabled --delimiter=: \
          --query "${1:-}" \
          --bind "start:reload:$rg_cmd -- {q} || true" \
          --bind "change:reload:sleep 0.1; $rg_cmd -- {q} || true" \
          --preview "$_fzf_preview" \
          --preview-window 'down:55%:+{2}-/2'
}

fA() {
   local out file line
   out=$(_fzf_rg_filter "$1") || return
   IFS=: read -r file line _ <<< "$out"
   [[ -n $file ]] && "${EDITOR:-nvim}" "+${line}" "$file"
}

fa() {
   local out file line
   out=$(_fzf_rg_live "$1") || return
   IFS=: read -r file line _ <<< "$out"
   [[ -n $file ]] && "${EDITOR:-nvim}" "+${line}" "$file"
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

# ----------------------------------------------------------------------------
# ZLE pickers for the vicmd <Space> leader (bound in 17-vimode.zsh). Each
# inserts its pick at the cursor, shell-quoted.
# ----------------------------------------------------------------------------

# vicmd's cursor sits ON a character, so insert after it (like p), spaced off.
_fzf_insert_point() {
   (( CURSOR < $#BUFFER )) && (( CURSOR++ ))
   [[ -n $LBUFFER && $LBUFFER != *' ' ]] && LBUFFER+=' '
}

_fzf_insert() {
   if (( $# )); then
      _fzf_insert_point
      LBUFFER+="${(j: :)${(@q)@}} "
   fi
   zle reset-prompt
}

# <Space>f: fzf's own ^T file picker, at the same insert point.
fzf-file-after-widget() {
   _fzf_insert_point
   zle fzf-file-widget
}
zle -N fzf-file-after-widget

# <Space>a / <Space>A: ripgrep, inserting `file:line`.
_fzf_rg_insert() {
   local out file line
   out=$("$1") && IFS=: read -r file line _ <<< "$out"
   _fzf_insert ${file:+"$file:$line"}
}
fzf-rg-live-widget()   { _fzf_rg_insert _fzf_rg_live }
fzf-rg-filter-widget() { _fzf_rg_insert _fzf_rg_filter }
zle -N fzf-rg-live-widget
zle -N fzf-rg-filter-widget

# <Space>gd: changed and untracked files, as paths relative to the cwd.
# Porcelain paths are repo-relative; a rename's old path is a separate -z field.
fzf-git-changed-widget() {
   local cdup prefix top e p skip=0
   local -a entries picked paths
   cdup=$(git rev-parse --show-cdup 2>/dev/null) || { zle reset-prompt; return }
   prefix=$(git rev-parse --show-prefix)
   top=$(git rev-parse --show-toplevel)
   for e in "${(@0)$(git status --porcelain -z --untracked-files=all)}"; do
      (( skip )) && { skip=0; continue }
      [[ $e == [RC]* ]] && skip=1
      [[ -n $e ]] && entries+=("$e")
   done
   picked=(${(f)"$(print -rl -- $entries | fzf --multi --nth=2.. \
      --preview "p=\$(printf %s {} | cut -c4-); cd ${(q)top} && { git diff --color=always HEAD -- \"\$p\" | grep -q . && git diff --color=always HEAD -- \"\$p\" || cat -- \"\$p\"; }" \
      --preview-window 'down:55%')"})
   for p in "${(@)picked#???}"; do
      [[ -n $prefix && $p == "$prefix"* ]] && paths+=("${p#$prefix}") || paths+=("$cdup$p")
   done
   _fzf_insert "${(@)paths}"
}
zle -N fzf-git-changed-widget

# <Space>gm: a commit from all refs, inserting its hash.
fzf-git-commit-widget() {
   local -a picked
   picked=(${(f)"$(git log --all --oneline --decorate --color=always 2>/dev/null \
      | fzf --ansi --multi --no-sort \
            --preview 'git show --color=always --stat --patch {1}' \
            --preview-window 'down:55%')"})
   _fzf_insert "${(@)picked%% *}"
}
zle -N fzf-git-commit-widget

# <Space>b: a local or remote branch.
fzf-git-branch-widget() {
   local -a picked
   picked=(${(f)"$(git for-each-ref --format='%(refname)' refs/heads refs/remotes 2>/dev/null \
      | grep -v '/HEAD$' | sed -e 's#^refs/heads/##' -e 's#^refs/remotes/##' \
      | fzf --multi \
            --preview 'git log --oneline --decorate --color=always -30 {}' \
            --preview-window 'down:55%')"})
   _fzf_insert "${(@)picked}"
}
zle -N fzf-git-branch-widget

# <Space>J: cd into a directory from the pushd stack (auto_pushd fills it).
# Runs as a command line, as fzf's own cd widget does, so it lands in history.
fzf-dirstack-widget() {
   local dir
   dir=$(dirs -pl | tail -n +2 | awk '!seen[$0]++' | fzf \
      --preview 'ls -la {}' --preview-window 'down:40%')
   if [[ -z $dir ]]; then
      zle reset-prompt
      return
   fi
   zle push-line
   BUFFER="builtin cd -- ${(q)dir}"
   zle accept-line
}
zle -N fzf-dirstack-widget
