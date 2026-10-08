export PATH="/usr/local/opt/llvm@17/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"   # cargo-installed binaries (plc)
export PATH="$HOME/.elan/bin:$PATH"    # Lean via elan on Linux (Brewfile covers Darwin)

# postgresql@17 (Brewfile). Homebrew ships Postgres only as versioned formulae,
# and versioned formulae are keg-only: the install is complete under
# /opt/homebrew/opt/postgresql@17 but nothing is symlinked into the brew prefix,
# so psql/pg_dump/createdb exist and are still "command not found". Guarded like
# the fzf and Homebrew lines below, so a box without it skips the line.
[[ -d /opt/homebrew/opt/postgresql@17/bin ]] && \
    export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# Homebrew. Same failure as ~/.local/bin above, one level up. /opt/homebrew/bin
# reaches PATH on this Mac only through /etc/paths.d/homebrew, and Darwin's
# /usr/libexec/path_helper — run from /etc/zprofile — expands every line of
# /etc/paths *before* it touches /etc/paths.d. /etc/paths line 3 is /usr/bin, so
# the brew prefix is structurally guaranteed to lose; no edit under /etc/paths.d
# can reorder that, the two lists are concatenated in that order by design. The
# symptom was `git` resolving to Apple's 2.39.5 while brew's 2.53.0 sat unused.
#
# Has to be .zshrc, not .zshenv: a login zsh reads .zshenv *before* /etc/zprofile,
# so path_helper would re-hoist /usr/bin over anything set there. .zshrc is the
# first file that runs after it.
#
# sbin is included because path_helper never had it at all — /etc/paths.d/homebrew
# lists only bin, so formulae installing to /opt/homebrew/sbin were invisible.
# Guarded like the fzf line above so Linux boxes, which have no /opt/homebrew,
# skip it rather than prepending a dead directory.
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
