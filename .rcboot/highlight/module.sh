#!/usr/bin/env bash
# Module: highlight — zsh-syntax-highlighting. Homebrew on Darwin, a clone
# into ~/.local/share/zsh on Linux.

fragment zsh/rc.d/20-highlight.zsh

if [ "$RC_OS" = linux ]; then
    source "$RC_BOOT/highlight/syntax_linux.sh"
    step install_zsh_syntax_linux ensure_zsh_syntax_linux
fi
