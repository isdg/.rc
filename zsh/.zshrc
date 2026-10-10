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
# of the two-digit prefix from ~/.config/rc/zsh, where .rcboot links the enabled
# ones. A checkout never bootstrapped loads all of rc.d/.
_rc_d=~/.config/rc/zsh
[[ -d $_rc_d ]] || _rc_d=$ISGRC/zsh/rc.d
# (n) sorts numerically, <-> matches any number, N allows an empty directory.
for _rc_frag in $_rc_d/<->-*.zsh(Nn); do
    source $_rc_frag
done
unset _rc_d _rc_frag

# This box's own settings (zsh/zshrc.local.example), after every fragment, so
# they win. Then the banner, which reports them (SSH_KEYS).
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local
(( $+functions[banner_render] )) && banner_render
