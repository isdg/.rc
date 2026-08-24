#!/bin/sh
# Russian-layout twins for tmux bindings — the tmux half of what the editors
# already do: nvim/lua/keymaps/leader.lua duplicates every <leader> mapping onto
# its Cyrillic key, nvim/lua/russian.lua and vim/.vimrc do the same for normal
# mode. Without this, switching the layout to Russian silently disarms tmux:
# prefix-s stops opening the session tree, hjkl stops moving in copy mode.
#
# Three tables, matching the two halves of the editor story plus the layer:
#   prefix        the <leader> equivalent — every prefix-<letter> binding
#   copy-mode-vi  the normal-mode equivalent — hjkl, v, y, w, b, G, ...
#   plugins       the second layer (C-b C-b), whose letters need twins for the
#                 same reason the prefix ones do — its C-b entry key does not,
#                 being a control combination.
#
# Only single Latin letters are twinned. C-b, M-1, Space, arrows and the
# punctuation bindings are deliberately skipped: terminals derive control and
# meta combinations from the physical key, so those already fire under either
# layout, while punctuation does not sit on matching keys across the two.
#
# Run from .tmux.conf AFTER tpm, so the plugins' own keys (omni b/a/j/P/A/J,
# orchbus o/O, resurrect C-s/C-r) are twinned too. Sweeping what is actually
# bound, rather than listing keys here, is the whole point — a hand-written list
# would go stale the moment a plugin or a bind line changes.
#
# Re-running is safe and idempotent: the twins it creates are Cyrillic, which
# never match the table again, so a re-source (toggle_theme.sh does one) just
# rewrites the same bindings instead of compounding them.
set -eu

# English -> Russian by physical key, same pairs as the editors use. Held as a
# flat word list, not two strings indexed by position: awk here is not multibyte
# aware, so a Cyrillic letter must be handled as a whole token, never sliced.
PAIRS='q й w ц e у r к t е y н u г i ш o щ p з
       a ф s ы d в f а g п h р j о k л l д
       z я x ч c с v м b и n т m ь
       Q Й W Ц E У R К T Е Y Н U Г I Ш O Щ P З
       A Ф S Ы D В F А G П H Р J О K Л L Д
       Z Я X Ч C С V М B И N Т M Ь'
# Flatten to one line: the awk here refuses a newline inside a -v assignment,
# and the table above is wrapped for reading. Unquoted expansion word-splits on
# the runs of whitespace, so this rejoins the pairs with single spaces.
PAIRS=$(echo $PAIRS)

# Rewrite tmux's own `list-keys` output with the key swapped, then source it.
# Sourcing rather than shelling out to `tmux bind-key` is what keeps this
# honest: list-keys emits tmux syntax, so the command half is handed back to
# tmux exactly as it came out, with its quoting intact. Passing those same
# strings through the shell would re-tokenise every "#{...}" and nested quote.
conf="${TMPDIR:-/tmp}/tmux-russian.$$"
: > "$conf"

for table in prefix copy-mode-vi plugins; do
    tmux list-keys -T "$table" | awk -v pairs="$PAIRS" '
        BEGIN {
            n = split(pairs, p, /[ \t\n]+/)
            for (i = 1; i < n; i += 2) ru[p[i]] = p[i + 1]
        }
        # bind-key [-r] -T <table> <key> <command...>  — match through the
        # flags and table so whatever follows starts exactly at the key, and
        # the command keeps its original spacing byte for byte.
        match($0, /^bind-key[ \t]+(-[a-zA-Z]+[ \t]+)*-T[ \t]+[^ \t]+[ \t]+/) {
            head = substr($0, 1, RLENGTH)
            rest = substr($0, RLENGTH + 1)
            key = rest
            sub(/[ \t].*$/, "", key)
            if (key in ru) printf "%s%s%s\n", head, ru[key], substr(rest, length(key) + 1)
        }
    ' >> "$conf"
done

tmux source-file "$conf"
rm -f "$conf"
