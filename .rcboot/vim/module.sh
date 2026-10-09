#!/usr/bin/env bash
# Module: vim — .vimrc, coc settings, the color schemes, then the vim and
# neovim plugins.

source "$RC_BOOT/vim/vim.sh"
step create_vim_dirs ensure_vim_dirs

link vim/.vimrc "$HOME/.vimrc"

# coc.nvim only ever reads ~/.vim/coc-settings.json, so that single file is
# linked rather than the directory around it. The same-inode case — ~/.vim
# *being* the repo's vim/.vim — is handled by _link_state, which reports it
# as `ok` instead of trying to back the repo's own file up.
link vim/.vim/coc-settings.json "$HOME/.vim/coc-settings.json"

local scheme
for scheme in "$DOTFILES_DIR"/vim/.vim/colors/*.vim; do
    link "vim/.vim/colors/${scheme##*/}" "$HOME/.vim/colors/${scheme##*/}"
done

step install_vim_plugins ensure_vim_plugins
