#!/usr/bin/env bash
# Module: zsh. The zsh theme needs no link — .zshrc sources it from the repo.

# .zshenv is read by non-interactive shells (tmux popups, nvim's :! …), which
# is where $FZF_DEFAULT_OPTS_FILE has to come from. A pre-existing one is backed
# up rather than clobbered: it usually carries a toolchain line worth reading.
link zsh/.zshrc "$HOME/.zshrc"
link zsh/.zshenv "$HOME/.zshenv"

if [ "$RC_OS" = linux ]; then
    source "$RC_BOOT/zsh/syntax_linux.sh"
    step install_zsh_syntax_linux ensure_zsh_syntax_linux
fi

source "$RC_BOOT/zsh/shell.sh"
step "set_default_shell_$RC_OS" "ensure_default_shell_$RC_OS"
