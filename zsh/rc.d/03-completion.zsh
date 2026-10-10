# completion — full fpath scan at most once a day, cached -C otherwise
autoload -Uz compinit
if [[ -n $HOME/.zcompdump-lite(#qN.mh-24) ]]; then
    compinit -C -d "$HOME/.zcompdump-lite"
else
    compinit -d "$HOME/.zcompdump-lite"
fi
autoload -Uz bashcompinit && bashcompinit   # tools that ship only bash completions

zstyle ':completion:*' menu select
# oh-my-zsh's matcher-list: exact, then case-insensitive, then partial-word —
# strictly richer than the single case-fold rule this config had before.
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' special-dirs true
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
