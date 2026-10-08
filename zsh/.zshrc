# escape hatch — `ZSH_BARE=1 zsh` skips this entire config: no theme, banner,
# plugins or highlighting; a bare shell for testing
[[ -n $ZSH_BARE ]] && return

# startup timing — read by log_shell (rc.d/21-startup.zsh)
zmodload zsh/datetime
typeset -gF _BANNER_T0=$EPOCHREALTIME

# Repo root, resolved from THIS file's real path so the config works under any
# directory name (~/.rc, ~/.dotfiles, …) — not just a hardcoded one. %x = the
# file being sourced; :A resolves the ~/.zshrc symlink to the repo; :h:h climbs
# zsh/ up to the repo root. Exported so children (tmux, scripts) can use it too.
export ISGRC="${${(%):-%x}:A:h:h}"

# Everything else lives in rc.d/, one concern per file, sourced in the order
# of the two-digit prefix. (n) sorts numerically; <-> matches any number.
for _rc_frag in $ISGRC/zsh/rc.d/<->-*.zsh(n); do
    source $_rc_frag
done
unset _rc_frag
