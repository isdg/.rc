#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Syntax highlighting — Homebrew on darwin (prefix derived from brew's own path,
# /usr/local/bin/brew → /usr/local, instead of the slow `brew --prefix`), or the
# git clone that .rcboot/zsh/syntax_linux.sh makes on Linux.
_brew_prefix="${HOMEBREW_PREFIX:-${commands[brew]:h:h}}"
for _hl in "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
           "$HOME/.local/share/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
    [[ -f $_hl ]] && { source "$_hl"; break }
done
unset _brew_prefix _hl
