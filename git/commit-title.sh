#!/bin/sh
# commit-msg hook: fail a commit whose subject runs past 50 characters.
# Subjects git writes itself (merges, reverts, fixup!/squash!/amend!) pass.
set -eu

max=50
subject=$(git stripspace --strip-comments < "$1" | sed -n '1p')

case $subject in
    "Merge "* | "Revert "* | "fixup! "* | "squash! "* | "amend! "*) exit 0 ;;
esac

# Code points, not bytes: drop UTF-8 continuation bytes before counting.
length=$(printf '%s' "$subject" | LC_ALL=C tr -d '\200-\277' | wc -c)
length=$((length + 0))

if [ "$length" -gt "$max" ]; then
    printf 'commit-msg: the subject is %d characters, over %d:\n  %s\n' \
        "$length" "$max" "$subject" >&2
    echo 'Shorten it, or skip the check with --no-verify.' >&2
    exit 1
fi
