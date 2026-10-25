#!/usr/bin/env bash
# Exercises generate.sh against a throwaway copy of the repo. It runs under the
# bash running this file, so `/bin/bash theme/generate_test.sh` covers 3.2.
set -eu

src=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0

check() {
    local what="$1"; shift
    if "$@"; then
        echo "ok   $what"
    else
        echo "FAIL $what"
        fails=$((fails + 1))
    fi
}

mkdir "$tmp/pristine"
tar -C "$src" --exclude=.git -cf - . | tar -C "$tmp/pristine" -xf -
repo="$tmp/repo"

fresh() { rm -rf "$repo"; cp -R "$tmp/pristine" "$repo"; }
gen() { "$BASH" "$repo/theme/generate.sh" "$@" > "$tmp/out" 2>&1; }
said() { grep -qF -- "$1" "$tmp/out"; }
unchanged() { cmp -s "$tmp/pristine/$1" "$repo/$1"; }
edited() { ! unchanged "$1"; }
no_partial_files() { [ -z "$(find "$repo" -name '*.generating.*')" ]; }

# rewrite <file> <sed script>, portably: BSD and GNU sed disagree on -i.
rewrite() {
    sed "$2" "$repo/$1" > "$tmp/rewrite"
    cat "$tmp/rewrite" > "$repo/$1"
}

# refuses <what> <message> [args...]: generate.sh fails and says <message>.
refuses() {
    local what="$1" msg="$2" rc=0
    shift 2
    gen "$@" || rc=$?
    check "$what" [ "$rc" -ne 0 ]
    check "  ...saying: $msg" said "$msg"
}

fresh
check "a clean tree is up to date" gen --check
gen
check "regenerating it changes nothing" diff -rq "$tmp/pristine" "$repo"

fresh
echo 'x #ff0000' >> "$repo/theme/templates/tig.tpl"
refuses "a literal hex in a template" "literal colour in a template"
check "  ...before writing anything" unchanged tig/theme-dark.tigrc
refuses "  ...under --check too" "literal colour in a template" --check

for form in "'#d4d4d4'" '"#d4d4d4"' '#d4d4d4'; do
    fresh
    rewrite theme/palette.sh "s/ISG_FG=\$grey_d4/ISG_FG=$form/"
    refuses "a slot assigned $form" "slot assigned a literal hex"
done

fresh
echo 'x ${ISG_TYPO}' >> "$repo/theme/templates/tig.tpl"
refuses "an unknown slot in a template" 'unset placeholder ${ISG_TYPO}'
check "  ...leaves no partial file" no_partial_files
check "  ...and keeps the old output" unchanged tig/theme-dark.tigrc

fresh
rewrite theme/palette.sh 's/ISG_FG=\$grey_d4/ISG_FG=$grey_typo/'
refuses "a slot naming an unknown colour" "grey_typo: unbound variable"

fresh
rewrite theme/palette.sh "s/ISG_FG=\$grey_d4/ISG_FG=''/"
refuses "an empty slot" 'empty placeholder ${ISG_FG}'
check "  ...leaves no partial file" no_partial_files

fresh
echo '" by hand' >> "$repo/nvim/colors/vs_dark.vim"
refuses "a hand-edited output" "out of date: nvim/colors/vs_dark.vim" --check
check "  ...and --check leaves it alone" edited nvim/colors/vs_dark.vim
gen
check "regenerating restores it" unchanged nvim/colors/vs_dark.vim

fresh
refuses "an unknown argument" "usage: generate.sh" --bogus

[ "$fails" -eq 0 ] || { echo "$fails failed"; exit 1; }
