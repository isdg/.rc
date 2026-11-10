#!/usr/bin/env bash
# Types Russian-layout keys into an interactive zsh under zsh/zpty, with the
# vi mode of rc.d/17-vimode.zsh and its twins from rc.d/24-russian.zsh, and
# checks the command line each sequence leaves.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

LC_ALL="$(locale -a | grep -i -E '^(en_US|C)\.utf-?8$' | sed -n 1p)"
export LC_ALL HOME="$tmp" ZDOTDIR="$tmp"

cat > "$ZDOTDIR/.zshrc" <<EOF
source "$repo/zsh/rc.d/01-options.zsh"
source "$repo/zsh/rc.d/17-vimode.zsh"
source "$repo/zsh/rc.d/24-russian.zsh"
PS1='> '
twin() { print -r -- \${\${(z)"\$(bindkey -M \$1 \$2)"}[-1]}; }
{
    print -r -- \$+functions[_ru_mirror]
    twin vicmd в
} > "$tmp/startup"
dump-buffer() {
    print -r -- "\$BUFFER" >> "$tmp/buffers"
    BUFFER=
}
dump-twins() {
    {
        print -r -- \$+functions[_ru_mirror]
        twin vicmd ' нн'
        twin vicmd Э
        twin vicmd Ё
        twin viopp шц
        twin vicmd '\^'
    } > "$tmp/twins"
}
zle -N dump-buffer
zle -N dump-twins
bindkey -M viins '^B' dump-buffer
bindkey -M vicmd '^B' dump-buffer
bindkey -M vicmd '^T' dump-twins
EOF

cat > "$tmp/drive.zsh" <<'EOF'
zmodload zsh/zpty zsh/datetime
tmp=$1 n=0
zpty -b sh 'zsh -i'

drain() { local out; while zpty -rt sh out 2>/dev/null; do :; done }

lines() { REPLY=0; [[ -f $1 ]] && REPLY=$(wc -l < $1); }

wait_for() {
    local deadline=$(( EPOCHREALTIME + 10 ))
    while (( EPOCHREALTIME < deadline )); do
        eval "$1" && return 0
        sleep 0.05
        drain
    done
    return 1
}

# keys <keys>: types them on a fresh line, then logs the buffer.
keys() {
    zpty -wn sh "$1"$'\C-b'
    (( ++n ))
    wait_for 'lines $tmp/buffers; (( REPLY >= n ))' || return 1
    zpty -wn sh $'\r'
}

wait_for '[[ -f $tmp/startup ]]'
keys $'\e\C-t'
keys $'print aaa bbb ccc ddd\eиивц'
keys $'echo one two\eвшц'
keys $'echo one two\eмшцв'
keys $'echo b\eшa\e'
keys $'echo x\eФZ\e'
keys $'echo hiоОФZ\e'
keys $'echo hijJФZ\e'
keys 'echo jО'
keys 'echo хорошо'
keys $'echo abcd\e0wRjоJО\e'
keys $'echo abc\e0wRjJ\e'
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
line() { sed -n "$1p" "$tmp/buffers"; }
start() { sed -n "$1p" "$tmp/startup"; }
twin() { sed -n "$1p" "$tmp/twins"; }

case "$(uname)" in
    Darwin) yo=vi-goto-column ;;
    *) yo=vi-swap-case ;;
esac

check "the mirror waits for the first Esc" 1 "$(start 1)"
check "no twin before it" undefined-key "$(start 2)"
check "the first Esc mirrors once" 0 "$(twin 1)"
check "a leader sequence gets a twin" vi-yank-line-clipboard "$(twin 2)"
check "an escaped key gets a twin" vi-set-buffer "$(twin 3)"
check "Ё is the layout's ё key" "$yo" "$(twin 4)"
check "a text object gets a twin" select-in-word "$(twin 5)"
check "^ keeps its own widget" vi-first-non-blank "$(twin 6)"
check "ии then вц is bb dw" 'print aaa bbb ddd' "$(line 2)"
check "вшц is diw" 'echo one ' "$(line 3)"
check "мшцв is viwd" 'echo one ' "$(line 4)"
check "ш is i" 'echo ab' "$(line 5)"
check "Ф is A" 'echo xZ' "$(line 6)"
check "оО leaves insert mode" 'echo hiZ' "$(line 7)"
check "jJ still does" 'echo hiZ' "$(line 8)"
check "jО is typed as is" 'echo jО' "$(line 9)"
check "Russian text is typed as is" 'echo хорошо' "$(line 10)"
check "R overwrites with j, о, J and О" 'echo jоJО' "$(line 11)"
check "jJ leaves R mode too" 'echo bc' "$(line 12)"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
