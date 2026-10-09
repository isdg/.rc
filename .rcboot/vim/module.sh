#!/usr/bin/env bash
# Module: vim — .vimrc, coc settings, the color schemes, then the vim and
# neovim plugins.

source "$RC_BOOT/vim/vim.sh"
step create_vim_dirs ensure_vim_dirs

link vim/.vimrc "$HOME/.vimrc"

fragment vim/rc.d/00-basics.vim
fragment vim/rc.d/01-defaults.vim
fragment vim/rc.d/02-builtins.vim
fragment vim/rc.d/03-files.vim
fragment vim/rc.d/04-splits.vim
fragment vim/rc.d/05-jumps.vim
fragment vim/rc.d/06-sessions.vim
fragment vim/rc.d/07-ru-keys.vim
fragment vim/rc.d/08-ru-leader.vim
fragment vim/rc.d/09-plugins.vim
fragment vim/rc.d/10-colors.vim
fragment vim/rc.d/11-coc.vim
fragment vim/rc.d/12-nerdtree.vim
fragment vim/rc.d/13-hr.vim
fragment vim/rc.d/14-fzf-layout.vim
fragment vim/rc.d/15-fuzzy.vim
fragment vim/rc.d/16-history.vim
fragment vim/rc.d/17-commenting.vim
fragment vim/rc.d/18-goyo.vim
fragment vim/rc.d/19-ru-twins.vim

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
