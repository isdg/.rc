#!/usr/bin/env bash
# Exercises plan-grill.sh with the hook JSON Claude Code sends.
set -euo pipefail

hook="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/plan-grill.sh")"
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

run() {
    jq -n --arg event "$1" --arg mode "$2" \
        '{hook_event_name: $event, permission_mode: $mode,
          tool_name: "EnterPlanMode"}' | bash "$hook"
}

context_for() {
    jq -r --arg event "$1" \
        'select(.hookSpecificOutput.hookEventName == $event)
         | .hookSpecificOutput.additionalContext'
}

out="$(run UserPromptSubmit plan)"
check "a plan-mode prompt names the grilling skill" \
    grep -q 'isg-skills:grilling' <<< "$(context_for UserPromptSubmit \
        <<< "$out")"

for mode in default auto acceptEdits bypassPermissions; do
    out="$(run UserPromptSubmit "$mode")"
    check "a prompt in $mode mode adds nothing" test -z "$out"
done

out="$(run PostToolUse auto)"
check "entering plan mode names the grilling skill" \
    grep -q 'isg-skills:grilling' <<< "$(context_for PostToolUse <<< "$out")"

check "other events add nothing" test -z "$(run Stop plan)"

[ "$fails" -eq 0 ] || { echo "$fails failed"; exit 1; }
