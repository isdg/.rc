# Read by EVERY zsh — interactive or not, login or not. That includes the
# non-interactive `zsh -c` tmux uses for display-popup / run-shell, which never
# reads .zshrc. Only settings a subprocess must inherit belong here; everything
# else (prompt, plugins, aliases, colours) stays in .zshrc, which this file
# deliberately does not duplicate.

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ----------------------------------------------------------------------------
# fzf options, for every fzf on the machine
# ----------------------------------------------------------------------------
#
# fzf reads $FZF_DEFAULT_OPTS_FILE itself, so one file themes every picker —
# ours (zsh/fzf.zsh), fzf-tab, nvim's fzf.vim, the ~/omni tmux popups — with no
# per-call-site flags and nothing to keep in sync.
#
# What matters is that the variable holds a *constant path* while the per-mode
# colours live in the file it points at, behind the opts-active.conf symlink
# that toggle_theme.sh flips. The colours therefore get read from disk at each
# fzf launch. When they lived in FZF_DEFAULT_OPTS instead, tmux froze one copy
# of the string in its server environment at start and handed that to every
# popup forever: after a toggle, omni's pickers kept painting the old mode's
# selection bar while the rest of the terminal had moved on. A path can go
# stale the same way and still be right.
#
# Set only when the file is readable — fzf treats a missing
# $FZF_DEFAULT_OPTS_FILE as a fatal error (exit 2, "no such file or
# directory"), so an unseeded or dangling symlink would break every picker
# rather than fall back. Unset, fzf just uses its own defaults.
# `ISG_FZF_THEME=false` opts out, as it always has.
if [[ "$ISG_FZF_THEME" != 'false' ]]; then
  # This file's own real path locates the repo, so no $ISGRC (set in .zshrc,
  # i.e. too late and absent in subprocesses) and no hardcoded ~/.rc: %x is the
  # file being sourced, :A resolves the ~/.zshenv symlink into the repo, :h:h
  # climbs zsh/ up to the root. Falls back to ~/.rc when ~/.zshenv is a real
  # file rather than a link into the repo.
  _isg_rc="${${(%):-%x}:A:h:h}"
  [[ -d "$_isg_rc/fzf" ]] || _isg_rc="$HOME/.rc"
  if [[ -r "$_isg_rc/fzf/opts-active.conf" ]]; then
    export FZF_DEFAULT_OPTS_FILE="$_isg_rc/fzf/opts-active.conf"
  fi
  unset _isg_rc
fi
