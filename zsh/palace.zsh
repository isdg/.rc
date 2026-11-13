# ============================================================
# palace.zsh — zsh wrappers for the palace notes vault
# ============================================================
# Sourced by ~/.rc/zsh/rc.d/15-aliases.zsh. The heavy lifting lives in the
# `plc` binary (installed by .rcboot/plc/plc.sh): it creates/resolves
# note files and prints their path. These wrappers just open that path in
# $EDITOR, and add fzf pickers for murmur and isg notes. The vault is
# whatever `plc config` names: $PALACE_DIR, else the vault line of
# ~/.plc/.plcrc.
#
# Commands, short alias on the left. Each opens its note in $EDITOR,
# creating it first if it does not exist yet:
#   dl  daily [DD MM YY|YYYY]   daily note, today by default
#   wk  weekly                  this ISO week's note
#       shot [-i TEXT|-p DIR|-H]
#                               timestamped snapshot, in the daily dir
#                               unless -p; -i inline body, -H no header
#   no  note NAME               NAME in the notes dir (plc add)
#       ptop                    TOP.md, the vault landing page (plc top)
#   td  todo                    the last do-note
#       todo -n                 new do-note for this ISO week
#       todo -L | -l FILE       list do-notes | mark FILE last (no editor)
#   mm  murmur                  new murmur note, prompts for its name
#       murmur -l               fzf-pick a murmur note
#       isg                     the last isg note (isg0, isg1, …)
#       isg -c                  next isg note
#       isg --continue [N]      continue N, or the latest: isg<N>a, …
#       isg --list | NAME       fzf-pick an isg note | open NAME
#       pst [-m M] [-y Y] [-t year] [-p]
#                               daily-note heatmap + stats (plc stat);
#                               -t picks the scope, -p a line chart
#
# daily, shot, note, todo -n and isg pass plc's creation flags through:
# -x TEXT appends a filename postfix, -t TAG seeds a [[TAG]] link.
#
# plc itself prints paths and never opens an editor:
#   plc cd [DIR]                cd into the vault, or DIR inside it
#   plc top                     print TOP.md's path, creating it
#   plc ledger | lr             double-entry ledger in +ledger notes
#   plc graph | orphans         the link graph | notes with no links
#   plc doctor [--fix]          check vault health, repair
#   plc config | init           vault path | scaffold the vault tree
#   plc help [COMMAND]          every command and its flags

# A process can't move its parent shell, so `plc cd` is answered here; every
# other call reaches the binary unchanged.
plc() {
   if [[ "$1" != cd ]]; then
      command plc "$@"
      return
   fi
   if (( $# > 2 )); then
      print -u2 "usage: plc cd [DIR]"
      return 2
   fi
   local vault
   vault=$(command plc config) || return
   cd -- "$vault${2:+/$2}"
}

# Open the note whose path plc prints, cd'd into the vault so the editor's
# working dir is the palace. Usage: _plc_edit plc <subcommand> [args...]
_plc_edit() {
   local f
   f=$("$@") || return
   [ -n "$f" ] || return
   local vault
   vault=$(plc config) || return
   ( cd "$vault" && ${EDITOR:-nvim} "$f" )
}

daily()  { _plc_edit plc daily "$@"; }
weekly() { _plc_edit plc weekly; }
shot()   { _plc_edit plc shot "$@"; }
note()   { _plc_edit plc add "$@"; }
# `ptop`, not `top`, so the palace landing page doesn't shadow the system `top`.
ptop()   { _plc_edit plc top; }

# todo [-n|-l FILE|-L] manage do-notes
#   -L / -l FILE : informational (list / re-point) — no editor
#   -n / (none)  : create new / open last — opens in $EDITOR
todo() {
   case "$1" in
      -L|--list|-l|--last) plc do "$@" ;;
      *)                   _plc_edit plc do "$@" ;;
   esac
}

# murmur [-l|-n]   manage murmur notes
#   -l : fzf-pick an existing note (by recency) and open it
#   -n : create a new note (prompts for a name)
murmur() {
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
no() { note "$@"; }
td() { todo "$@"; }
mm() { murmur "$@"; }
