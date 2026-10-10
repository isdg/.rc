# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Personal aliases live in zsh/rc.d/15-aliases.zsh.
# For a full list of active aliases, run `alias`.
#
# alias python=/Library/Frameworks/Python.framework/Versions/3.10/bin/python3
#alias python=/usr/local/bin/python3
# export PATH="$HOME/nvim/bin:$PATH"

# ~/.local/bin — pipx (which added this line in 2024, hardcoded to the Darwin
# $HOME and so dead on every Linux box), and the newer Neovim the Linux
# bootstrap drops there when the distro's package is too old. Prepended, not
# appended: the whole point is to beat an older /usr/bin copy.
export PATH="$HOME/.local/bin:$PATH"

# fzf. ~/.fzf/bin goes first for the same reason: on a distro that also packages
# fzf (Debian bookworm ships 0.38) the clone's modern binary has to win, or
# ~/.fzf.zsh's `fzf --zsh` fails with "unknown option: --zsh" — leaving ^R bound
# to redisplay and $FZF_DEFAULT_OPTS_FILE (fzf >= 0.48, set in .zshenv) ignored,
# so every picker loses its colours too. fzf's own installer appends this, which
# is precisely the bug.
[[ -d $HOME/.fzf/bin ]] && export PATH="$HOME/.fzf/bin:$PATH"
