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
#
#   wk  weekly                  this week's note
#
#   st  shot [-i TEXT|-p DIR|-H]
#                               timestamped snapshot, in the daily dir
#                               unless -p; -i inline body, -H no header
#
#   nt  note NAME               NAME in the notes dir (plc add)
#
#   pt  plctop                  TOP.md, the vault landing page (plc top)
#
#   td  todo                    the last do-note
#       todo -n                 new do-note for this week
#       todo -L | -l FILE       list do-notes | mark FILE last (no editor)
#
#   mm  murmur                  new murmur note, prompts for its name
#       murmur -l               fzf-pick a murmur note
#
#   ii  isg                     the last isg note (isg0, isg1, …)
#   ig                          same as ii
#       isg -c                  next isg note
#       isg --continue [N]      continue N, or the latest: isg<N>a, …
#       isg --list | NAME       fzf-pick an isg note | open NAME
#
#       pst [DD [MM [YY]]] [-f FORMAT]
#                               bytes written (plc stat): a day lists its
#                               notes, - for a whole field draws a month
#                               (- MM YY) or a year (- - YY); -f grid,
#                               rows, plot, list or tsv
#
# daily, shot, note, todo -n and isg pass plc's creation flags through:
# -x TEXT appends a filename postfix, -t TAG seeds a [[TAG]] link.
#
# plc itself prints paths and never opens an editor:
#   plc cd [DIR]                cd into the vault, or DIR inside it
#
#   plc top                     print TOP.md's path, creating it
#
#   plc ledger | lr             double-entry ledger in +ledger notes
#
#   plc graph | orphans         the link graph | notes with no links
#
#   plc doctor [--fix]          check vault health, repair
#
#   plc config | init           vault path | scaffold the vault tree
#
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
# `plctop`, not `top`, so the landing page doesn't shadow the system `top`.
plctop() { _plc_edit plc top; }

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

# pst [stat args]   the bytes written, `plc stat` (read-only: prints):
#     pst              today's notes     pst -              this month
#     pst 27 09 25     2025-09-27's      pst - 12 25        Dec 2025
#     pst - - 25       2025              pst - - -f plot    this year, plotted
pst() { plc stat "$@"; }

# Short aliases (functions so they resolve in non-interactive shells too)
# On Linux, st and ii shadow suckless's terminal and IRC client if installed;
# `command st` and `command ii` still reach them.
dl() { daily "$@"; }
wk() { weekly "$@"; }
st() { shot "$@"; }
nt() { note "$@"; }
pt() { plctop "$@"; }
td() { todo "$@"; }
mm() { murmur "$@"; }
ii() { isg "$@"; }
ig() { isg "$@"; }
