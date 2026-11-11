#!/usr/bin/env bash
# rcversion [repo]: the .rc version of a checkout, from its VERSION file, and
# origin/main's beside it when they differ: "0.11.0 (origin/main 0.11.2)".
# As fresh as the last fetch; no network.
set -euo pipefail

repo="${1:-${ISGRC:-$HOME/.rc}}"
here=""
read -r here 2>/dev/null < "$repo/VERSION" || true
if [ -z "$here" ]; then
    echo "rcversion: no VERSION in $repo" >&2
    exit 1
fi

there="$(git -C "$repo" show origin/main:VERSION 2>/dev/null)" || there=""
if [ -n "$there" ] && [ "$there" != "$here" ]; then
    echo "$here (origin/main $there)"
else
    echo "$here"
fi
