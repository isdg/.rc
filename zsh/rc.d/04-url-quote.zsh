# Quote ? & * in URLs as they are typed, so they don't glob-explode. This is the
# self-insert half of oh-my-zsh's magic functions; the bracketed-paste half is
# deliberately left out — it is slow with zsh-syntax-highlighting on large
# pastes, and paste timing here is already delicate (see KEYTIMEOUT in
# 17-vimode.zsh).
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic
