#!/usr/bin/env bash
# Module: neovim, its fragments and plugins. On Linux, a release build when
# the distro's is too old.

link nvim "$HOME/.config/nvim"

fragment nvim/rc.d/00-options.lua
fragment nvim/rc.d/01-russian.lua
fragment nvim/rc.d/02-fzf-layout.lua
fragment nvim/rc.d/03-lazy.lua
fragment nvim/rc.d/04-keys-editor.lua
fragment nvim/rc.d/05-keys-find.lua
fragment nvim/rc.d/06-keys-tree.lua
fragment nvim/rc.d/07-keys-edit.lua
fragment nvim/rc.d/08-keys-git.lua
fragment nvim/rc.d/09-keys-lsp.lua
fragment nvim/rc.d/10-keys-plugins.lua
fragment nvim/rc.d/11-colors.lua

if [ "$RC_OS" = linux ]; then
    source "$RC_BOOT/nvim/neovim_linux.sh"
    step install_neovim_linux ensure_neovim_linux
fi

source "$RC_BOOT/nvim/plugins.sh"
step install_nvim_plugins ensure_nvim_plugins
