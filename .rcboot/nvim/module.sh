#!/usr/bin/env bash
# Module: neovim. On Linux, a release build when the distro's is too old.

link nvim "$HOME/.config/nvim"

if [ "$RC_OS" = linux ]; then
    source "$RC_BOOT/nvim/neovim_linux.sh"
    step install_neovim_linux ensure_neovim_linux
fi
