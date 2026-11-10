# history (oh-my-zsh defaults)
HISTFILE="$HOME/.zsh_history"
# keep the whole history: oh-my-zsh's 10k SAVEHIST trimmed the file
# (recovered Jun 2026 after a wipe; see .zsh_history.bak-*)
SAVEHIST=200000
# hist_expire_dups_first only has duplicates to drop while HISTSIZE is larger
HISTSIZE=220000
setopt extended_history hist_expire_dups_first hist_ignore_dups \
       hist_ignore_space inc_append_history share_history
