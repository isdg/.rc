# ── init ──
# Plain zsh — oh-my-zsh was dropped (Aug 2026). Measured: it cost ~141 ms of a
# ~480 ms warm startup and 17 MB, and nearly all of that went to compaudit, a
# second compdump and 21 lib files — not to the parts worth having. Those are
# reproduced by hand below (options, completion styles, key bindings, URL
# quoting) at no measurable cost. Its git aliases were in use and are vendored
# in zsh/rc.d/13-git.zsh.
# auto_cd is deliberately NOT set. It turns any command zsh cannot run into a
# cd when a directory of that name happens to sit in $PWD, which reads as the
# shell doing something at random. The case that gave it away: `t` is aliased to
# tig, and on a box where tig was not installed, typing `t` in ~/.rc silently
# moved the shell into ~/.rc/tig — the repo's tig *config* directory — instead
# of saying "command not found". Every subdirectory here (fzf, theme, prompt,
# tig) is a loaded gun of that kind. 14-dirs.zsh defines `..` explicitly
# instead.
setopt prompt_subst interactive_comments extended_glob

# options oh-my-zsh's libs set that are worth keeping
setopt auto_pushd pushd_ignore_dups pushd_minus  # cd builds a stack: cd -2, dirs -v
setopt always_to_end complete_in_word            # completion cursor behaviour
setopt hist_verify                               # !! expands for review, not instantly
setopt no_flow_control                           # frees Ctrl-S / Ctrl-Q
setopt long_list_jobs

autoload -Uz colors add-zsh-hook && colors
