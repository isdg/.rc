#!/usr/bin/env bash
# Module: zsh. The zsh theme needs no link — .zshrc sources it from the repo.

# .zshenv is read by non-interactive shells (tmux popups, nvim's :! …), which
# is where $FZF_DEFAULT_OPTS_FILE has to come from. A pre-existing one is backed
# up rather than clobbered: it usually carries a toolchain line worth reading.
link zsh/.zshrc "$HOME/.zshrc"
link zsh/.zshenv "$HOME/.zshenv"

fragment zsh/rc.d/00-theme-mode.zsh
fragment zsh/rc.d/01-options.zsh
fragment zsh/rc.d/02-history.zsh
fragment zsh/rc.d/03-completion.zsh
fragment zsh/rc.d/04-url-quote.zsh
fragment zsh/rc.d/05-prompt.zsh
fragment zsh/rc.d/06-aliases-base.zsh
fragment zsh/rc.d/07-path.zsh
fragment zsh/rc.d/08-cache.zsh
fragment zsh/rc.d/09-fzf-init.zsh
fragment zsh/rc.d/10-zoxide.zsh
fragment zsh/rc.d/11-path-tools.zsh
fragment zsh/rc.d/12-env.zsh
fragment zsh/rc.d/13-git.zsh
fragment zsh/rc.d/14-dirs.zsh
fragment zsh/rc.d/15-aliases.zsh
fragment zsh/rc.d/16-fzf.zsh
fragment zsh/rc.d/17-vimode.zsh
fragment zsh/rc.d/18-omni.zsh
fragment zsh/rc.d/19-keys.zsh
fragment zsh/rc.d/20-highlight.zsh
fragment zsh/rc.d/21-startup.zsh
fragment zsh/rc.d/22-local.zsh
fragment zsh/rc.d/23-banner.zsh

if [ "$RC_OS" = linux ]; then
    source "$RC_BOOT/zsh/syntax_linux.sh"
    step install_zsh_syntax_linux ensure_zsh_syntax_linux
fi

source "$RC_BOOT/zsh/shell.sh"
step "set_default_shell_$RC_OS" "ensure_default_shell_$RC_OS"
