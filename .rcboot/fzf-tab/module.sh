#!/usr/bin/env bash
# Module: fzf-tab — Tab completion through fzf. Homebrew on Darwin, a clone
# into ~/.local/share/zsh on Linux, pinned to the formula's tag.

fragment zsh/rc.d/09-fzf-tab.zsh

if [ "$RC_OS" = linux ]; then
    source "$RC_BOOT/fzf-tab/fzf_tab_linux.sh"
    step install_fzf_tab_linux ensure_fzf_tab_linux
fi
