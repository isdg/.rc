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
#       daily +N | -N           the note N days ahead | back
#
#   wk  weekly [+N | -N]        this week's note, N weeks ahead | back
#
#   st  shot [-i TEXT|-p DIR|-H]
#                               timestamped snapshot, in the daily dir
#                               unless -p; -i inline body, -H no header
#
#   nt  note NAME               NAME in the notes dir (plc add)
#
#   pt  plctop                  TOP.md, the vault landing page (plc top)
#
#   td  todo [--last]           the last todo note
#       todo -n                 new todo note for this week
#       todo -l | -L NAME       list todo notes | mark NAME last (no editor)
#
#   mm  murmur NAME             NAME as a murmur note, or the note of
#                               that name anywhere in the vault
#       murmur -l               fzf-pick a murmur note
#
#   ig  isg [--last]            the last isg note (isg0, isg1, …)
#       isg -n                  new isg note, the next number
#       isg -nf [N]             follow up N, or the last: isg<N>a, …
#       isg -l | NAME           fzf-pick an isg note | open NAME
#       isg -L NAME             mark NAME last (no editor)
#
#   pd                          cd into the vault, stage it all, show the
#                               diff against HEAD
#
#       pst [DD [MM [YY]] | +N | -N] [-f FORMAT]
#                               bytes written (plc stat): a day lists its
#                               notes, - for a whole field draws a month
#                               (- MM YY) or a year (- - YY); -f grid,
#                               rows, plot, list or tsv
#       pst FROM .. TO          a range: each end a date or an amount
#                               back (3m, 2w, 30d), either left off
#
# daily, weekly, shot, note, todo -n and isg pass plc's creation flags
# through: -x TEXT appends a filename postfix, -t TAG seeds a [[TAG]]
# link.
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
   # + opens at the last line, where a note grows.
   ( cd "$vault" && ${EDITOR:-nvim} + "$f" )
}

daily()  { _plc_edit plc daily "$@"; }
weekly() { _plc_edit plc weekly "$@"; }
shot()   { _plc_edit plc shot "$@"; }
note()   { _plc_edit plc add "$@"; }
# `plctop`, not `top`, so the landing page doesn't shadow the system `top`.
plctop() { _plc_edit plc top; }

# todo [-n|-l|-L NAME|--last] manage todo notes
#   -l / -L NAME          : informational (list / re-point) — no editor
#   -n / --last / (none)  : create new / open last — opens in $EDITOR
todo() {
   case "$1" in
      -l|--list|-L|--mark) plc todo "$@" ;;
      *)                   _plc_edit plc todo "$@" ;;
   esac
}

# murmur -l | NAME   manage murmur notes
#   -l   : fzf-pick an existing note (by recency) and open it
#   NAME : open NAME, as plc murmur resolves it; no NAME is plc's error
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
      _plc_edit plc murmur "$@"
   fi
}

# isg [-l|--list | -n|--new [-f|--follow [N]] | NAME]
#   (none)               : open the last note plc created or opened
#   -n / --new           : create the next enumerated note and open it
#   -nf / -n --follow [N]: follow up note N (or the last) → isg<N>a, isg<N>b, …
#   -l / --list          : fzf-pick an existing note (by recency) and open it
#   NAME                 : open an existing note by basename
isg() {
   if [[ "$1" == -l || "$1" == --list ]]; then
      local dir pick
      # Preview by path: `plc isg {}` would mark every previewed note last.
      dir=$(plc config isg) || return
      pick=$(plc isg --list | fzf --prompt='isg > ' --no-sort \
         --preview "bat --color=always --style=plain ${(q)dir}/{} 2>/dev/null \
            || cat ${(q)dir}/{} 2>/dev/null" \
         --preview-window 'down:70%') || return
      [ -n "$pick" ] || return
      _plc_edit plc isg "$pick"
   elif [[ "$1" == -L || "$1" == --mark ]]; then
      plc isg "$@"
   else
      _plc_edit plc isg "$@"
   fi
}

# pst [stat args]   the bytes written, `plc stat` (read-only: prints):
#     pst              today's notes     pst -              this month
#     pst 27 09 25     2025-09-27's      pst - 12 25        Dec 2025
#     pst - - 25       2025              pst - - -f plot    this year, plotted
#     pst -1           yesterday's
#     pst 3m ..        last 3 months     pst - 09 .. - 11   Sep to Nov
#     pst 2w ..        last 2 weeks      pst .. - 03        Jan to Mar
pst() { plc stat "$@"; }

pd() { plc cd && git add . && git diff HEAD; }

# Short aliases (functions so they resolve in non-interactive shells too)
# On Linux, st shadows suckless's terminal if installed; `command st` still
# reaches it.
dl() { daily "$@"; }
wk() { weekly "$@"; }
st() { shot "$@"; }
nt() { note "$@"; }
pt() { plctop "$@"; }
td() { todo "$@"; }
mm() { murmur "$@"; }
ig() { isg "$@"; }
