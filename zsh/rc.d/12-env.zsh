export EDITOR='nvim'
export VISUAL='nvim'

# Default data dirs, set here rather than in files their tools rewrite, so
# no process can move them for another. launchd jobs pass their own.
export HR_VAULT="$HOME/feed"

# gpg-agent's pinentry needs a tty to prompt on. Without this, commit signing
# (git_signing.sh leaves it on whenever the key is present) hangs silently
# instead of asking for the passphrase.
export GPG_TTY=$TTY   # zsh sets $TTY; same answer as $(tty), no fork

# Ghostty only auto-sources its shell integration (the `ssh` wrapper behind
# shell-integration-features = ssh-env,ssh-terminfo in ghostty/config) in
# shells it spawns directly. tmux panes are not that — GHOSTTY_RESOURCES_DIR
# reaches them by plain env inheritance, but the integration script itself
# never runs, so `ssh` stays the real binary and remotes fail with "missing
# or unsuitable terminal: xterm-ghostty". This is the guard Ghostty's own
# ghostty-integration script recommends for exactly this case.
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
fi
