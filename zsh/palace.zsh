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
#   tg [-l | -n]           manage murmur notes (-l = fzf-pick)
#   dn [-n | -l FILE | -L] manage do-notes (week-based, last-pointer)
#   pst [calendar args]    pass-through to _calendar.sh for stats
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
shot()   { _plc_edit plc shot; }

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
      pick=$(plc murmur -l | fzf --prompt='murmur > ' --no-sort) || return
      [ -n "$pick" ] || return
      _plc_edit plc murmur -n "$pick"
   else
      local name
      read "name?murmur note name: "
      _plc_edit plc murmur -n "$name"
   fi
}

# pst [calendar args]   carryover wrapper around _calendar.sh until `plc cal`.
#   Lives in the palace repo alongside the notes; PALACE_DIR's parent.
pst() {
   local repo="${PALACE_DIR%/*}"
   if [ ! -x "$repo/_calendar.sh" ]; then
      echo "pst: _calendar.sh missing at $repo" >&2
      return 1
   fi
   ( cd "$repo" && ./_calendar.sh "$@" )
}

# Short aliases (functions so they resolve in non-interactive shells too)
dl() { daily "$@"; }
wk() { weekly "$@"; }
