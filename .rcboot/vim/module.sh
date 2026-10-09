#!/usr/bin/env bash
# Module: vim — .vimrc and the plugin-free fragments, the ones .vimrc.core
# loads too. vimplug adds the rest.

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
