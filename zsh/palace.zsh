# ============================================================
# palace.zsh — zsh wrappers for the palace notes vault
# ============================================================
# Sourced by ~/.dotfiles/zsh/aliases.zsh. The heavy lifting lives in the
# `plc` binary (installed by bootstrap/components/plc.sh): it creates/resolves
# note files and prints their path. These wrappers just open that path in
# $EDITOR, and add the fzf picker for murmur notes. PALACE_DIR is exported by
# the caller.
#
# Commands:
#   daily [DD MM YY|YYYY]  open/create a daily note (today by default)
#   weekly                 open/create this ISO week's note
#   shot                   timestamped daily snapshot note
#   start                  open/create TOP.md, the vault landing page
#   tg [-l | -n]           manage murmur notes (-l = fzf-pick)
#   isg [-l | NAME]        enumerated isg notes (isg0, isg1, … ; -l = fzf-pick)
#   dn [-n | -l FILE | -L] manage do-notes (week-based, last-pointer)
#   pst [stat args]        daily-note activity calendar + stats (plc stat)
#
# Short aliases:  dl → daily, wk → weekly

# Open the note whose path plc prints, cd'd into the vault so the editor's
# working dir is the palace. Usage: _plc_edit plc <subcommand> [args...]
_plc_edit() {
   local f
   f=$("$@") || return
   [ -n "$f" ] || return
   ( cd "$PALACE_DIR" && ${EDITOR:-nvim} "$f" )
}

daily()  { _plc_edit plc daily "$@"; }
weekly() { _plc_edit plc weekly; }
shot()   { _plc_edit plc shot "$@"; }
# `ptop`, not `top`, so the palace landing page doesn't shadow the system `top`.
ptop()   { _plc_edit plc top; }

# dn [-n|-l FILE|-L]   manage do-notes
#   -L / -l FILE : informational (list / re-point) — no editor
#   -n / (none)  : create new / open last — opens in $EDITOR
dn() {
   case "$1" in
      -L|--list|-l|--last) plc do "$@" ;;
      *)                   _plc_edit plc do "$@" ;;
   esac
}

# tg [-l|-n]   manage murmur notes
#   -l : fzf-pick an existing note (by recency) and open it
#   -n : create a new note (prompts for a name)
tg() {
   if [ "$1" = -l ]; then
      local pick
      # Preview the note below the list. `plc murmur -n {}` resolves an existing
      # name to its path (no creation, since every listed name already exists) --
      # the same resolver _plc_edit uses to open.
      pick=$(plc murmur -l | fzf --prompt='murmur > ' --no-sort \
         --preview 'f=$(plc murmur -n {} 2>/dev/null); bat --color=always --style=plain "$f" 2>/dev/null || cat "$f" 2>/dev/null' \
         --preview-window 'down:70%') || return
      [ -n "$pick" ] || return
      _plc_edit plc murmur -n "$pick"
   else
      local name
      read "name?murmur note name: "
      _plc_edit plc murmur -n "$name"
   fi
}

# isg [-l|--last | -c|--create | --continue [N] | --list | NAME]
#   (none) / -l / --last : open the last (most recent) note
#   -c / --create        : create the next enumerated note and open it
#   --continue [N]       : continue note N (or the latest) → isg<N>a, isg<N>b, …
#   --list               : fzf-pick an existing note (by recency) and open it
#   NAME                 : open an existing note by basename
isg() {
   if [ "$1" = --list ]; then
      local pick
      # Preview below the list; `plc isg {}` resolves an existing basename to its
      # path (listed names already exist, so no note is created).
      pick=$(plc isg --list | fzf --prompt='isg > ' --no-sort \
         --preview 'f=$(plc isg {} 2>/dev/null); bat --color=always --style=plain "$f" 2>/dev/null || cat "$f" 2>/dev/null' \
         --preview-window 'down:70%') || return
      [ -n "$pick" ] || return
      _plc_edit plc isg "$pick"
   else
      _plc_edit plc isg "$@"
   fi
}

# pst [stat args]   render daily-note activity as a calendar heatmap + stats.
#   Thin wrapper over `plc stat` (read-only: prints, no editor). plc's global
#   `-t` is --tag, so map a bare `-t` back to --type for muscle memory:
#     pst              current month     pst -t year        year (git heatmap)
#     pst -m 12 -y 25  Dec 2025          pst -t year -p     year line chart
pst() {
   local args=() a
   for a in "$@"; do
      [[ "$a" == "-t" ]] && a=--type
      args+=("$a")
   done
   plc stat "${args[@]}"
}

# Short aliases (functions so they resolve in non-interactive shells too)
dl() { daily "$@"; }
wk() { weekly "$@"; }
