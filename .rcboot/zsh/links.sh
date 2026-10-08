#!/usr/bin/env bash
# Links: zsh. The zsh theme needs no link — .zshrc sources it from the repo.

# .zshenv is read by non-interactive shells (tmux popups, nvim's :! …), which
# is where $FZF_DEFAULT_OPTS_FILE has to come from. A pre-existing one is backed
# up rather than clobbered: it usually carries a toolchain line worth reading.
_links_zsh() {
    local d="${DOTFILES_DIR:-$HOME/.rc}"
    echo ".zshrc|file|$d/zsh/.zshrc|$HOME/.zshrc"
    echo ".zshenv|file|$d/zsh/.zshenv|$HOME/.zshenv"
}
RC_LINK_SOURCES+=(_links_zsh)
