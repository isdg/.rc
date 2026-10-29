#!/usr/bin/env bash
# Drives Tab in an interactive zsh under zsh/zpty, with completion, fzf's **
# trigger and fzf-tab loaded by their rc.d fragments, and a stub fzf on PATH
# that picks the candidates matching the pick file.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

real_fzf="$(command -v fzf)"
real_home="$HOME"
unset TMUX TMUX_PANE FZF_TMUX FZF_TMUX_OPTS
export HOME="$tmp/home" XDG_CACHE_HOME="$tmp/cache" ZDOTDIR="$tmp/zdot"
export FZF_DEFAULT_OPTS_FILE= PATH="$tmp/bin:$PATH"
mkdir -p "$HOME/.local/share/zsh" "$ZDOTDIR" "$tmp/bin" "$tmp/w/alpine" \
    "$tmp/repo"
clone="$real_home/.local/share/zsh/fzf-tab"
[ ! -d "$clone" ] || ln -s "$clone" "$HOME/.local/share/zsh/fzf-tab"
touch "$tmp/w/alpha one" "$tmp/w/unique.txt" "$tmp/w/beta"
git -C "$tmp/repo" init -q
git -C "$tmp/repo" -c user.name=t -c user.email=t@t commit -q \
    --allow-empty -m init
git -C "$tmp/repo" branch feat-a
git -C "$tmp/repo" branch feat-b

# fzf-tab passes --print-query and reads back the query, the key that ended
# fzf, then the picks. fzf's ** walks the tree itself, so it gets the pick.
cat > "$tmp/bin/fzf" <<EOF
#!/bin/sh
case \$1 in --zsh|--version) exec "$real_fzf" "\$@" ;; esac
pick=\$(cat "$tmp/pick")
headers=0 tab=
for a; do
    case \$a in
        --header-lines=*) headers=\${a#*=} ;;
        --print-query) tab=1 ;;
    esac
done
if [ -z "\$tab" ]; then
    echo "** \$pick" > "$tmp/ran"
    printf '%s\n' "\$pick"
    exit
fi
echo tab > "$tmp/ran"
printf '\n\n'
tail -n +\$((headers + 1)) | grep -a -- "\$pick" || true
EOF
chmod +x "$tmp/bin/fzf"

cat > "$ZDOTDIR/.zshrc" <<EOF
for f in 01-options 03-completion 08-cache 09-fzf-init 09-fzf-tab; do
    source "$repo/zsh/rc.d/\$f.zsh"
done
bindkey -v
{
    bindkey -M viins '^I'
    zstyle -s ':completion:*' menu REPLY && print -r -- "\$REPLY"
} > "$tmp/setup"
# Keys sent while a completion runs are typeahead, which fzf-tab reads into
# fzf's query, so the driver waits for each mark before the next key.
# Loading fzf-tab rebinds Tab, so the mark binds it back.
tab-and-mark() {
    zle \${\${widgets[fzf-tab-complete]:+fzf-tab-complete}:-fzf-tab-load}
    bindkey -M viins '^I' tab-and-mark
    print -r -- "\$_ftb_orig_widget" >> "$tmp/tabs"
}
dump-buffer() {
    [[ -n \$BUFFER ]] || return 0
    print -r -- "\$BUFFER" >> "$tmp/buffers"
    BUFFER=
}
zle -N tab-and-mark
zle -N dump-buffer
bindkey -M viins '^I' tab-and-mark
bindkey -M viins '^B' dump-buffer
PS1='> '
EOF

cat > "$tmp/drive.zsh" <<'EOF'
zmodload zsh/zpty zsh/datetime
tmp=$1 n=0 tabs=0
zpty -b sh 'zsh -i'

drain() { local out; while zpty -rt sh out 2>/dev/null; do :; done }

lines() { REPLY=0; [[ -f $1 ]] && REPLY=${#${(f)"$(<$1)"}}; }

wait_for() {
    local deadline=$(( EPOCHREALTIME + ${2:-10} ))
    while (( EPOCHREALTIME < deadline )); do
        eval "$1" && return 0
        sleep 0.05
        drain
    done
    return 1
}

# tab <dir> <pick> <typed> <tabs>: logs the buffer that typing and pressing
# Tab left, and which fzf ran.
tab() {
    local i
    rm -f $tmp/ran
    print -r -- $2 > $tmp/pick
    zpty -w sh "cd $1 && touch $tmp/cd.$n"
    wait_for "[[ -f $tmp/cd.$n ]]" || return 1
    zpty -wn sh "$3"
    for i in {1..$4}; do
        zpty -wn sh $'\t'
        (( ++tabs ))
        wait_for 'lines $tmp/tabs; (( REPLY >= tabs ))' || return 1
        sleep 0.2
    done
    # A key right after a stub fzf, which exits at once, is sometimes dropped
    # (after a real fzf none is, even one sent with its Enter), so the dump,
    # which ignores an empty line, is retried.
    (( ++n ))
    for i in {1..5}; do
        zpty -wn sh $'\C-b'
        wait_for 'lines $tmp/buffers; (( REPLY >= n ))' 1 && break
    done
    print -r -- "$(cat $tmp/ran 2>/dev/null)" >> $tmp/runs
}

tab $tmp/w one 'echo al' 2
tab $tmp/w alpine 'echo al' 2
tab $tmp/w alp 'echo al' 2
tab $tmp/w x 'echo al' 1
tab $tmp/w x 'echo un' 1
tab $tmp/repo feat-b 'git checkout fe' 2
tab $tmp/w 'alpha one' 'cat **' 1
zpty -d sh
EOF

fails=0
check() {
    local what="$1" want="$2" got="$3"
    if [ "$got" = "$want" ]; then
        echo "ok   $what"
    else
        echo "FAIL $what: want '$want', got '$got'"
        fails=$((fails + 1))
    fi
}

zsh -f "$tmp/drive.zsh" "$tmp"
out="$(paste -d '|' "$tmp/buffers" "$tmp/runs")"
line() { sed -n "$1p" <<< "$out"; }
setup="$(cat "$tmp/setup")"
check "Tab loads fzf-tab" '"^I" fzf-tab-load' "$(sed -n 1p <<< "$setup")"
check "zsh's own menu is off" no "$(sed -n 2p <<< "$setup")"
check "fzf-tab lists through fzf's **" fzf-completion \
    "$(tail -n 1 "$tmp/tabs")"
check "a name with a space is quoted" 'echo alpha\ one |tab' "$(line 1)"
check "a directory keeps its slash" 'echo alpine/|tab' "$(line 2)"
check "several picks are all inserted" 'echo alpha\ one alpine/|tab' \
    "$(line 3)"
check "a shared prefix comes first" 'echo alp|' "$(line 4)"
check "one candidate skips fzf" 'echo unique.txt |' "$(line 5)"
check "a git branch completes" 'git checkout feat-b |tab' "$(line 6)"
check "** still opens fzf's walker" 'cat alpha\ one |** alpha one' \
    "$(line 7)"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
