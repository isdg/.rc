#!/usr/bin/env bash
# Claude Code hook: in plan mode, point Claude at the grilling skill before
# it drafts a plan. Runs on UserPromptSubmit and on PostToolUse for
# EnterPlanMode; hook JSON arrives on stdin.
set -euo pipefail

nudge="Plan mode: run the isg-skills:grilling interview before you draft \
or present a plan. Load it with the Skill tool unless it is already \
loaded in this session, and follow it until the user confirms the \
decisions."

input="$(cat)"
event="$(jq -r '.hook_event_name // empty' <<< "$input")"
mode="$(jq -r '.permission_mode // empty' <<< "$input")"

case "$event" in
    UserPromptSubmit) [ "$mode" = plan ] || exit 0 ;;
    PostToolUse) ;;
    *) exit 0 ;;
esac

jq -n --arg event "$event" --arg ctx "$nudge" \
    '{hookSpecificOutput: {hookEventName: $event, additionalContext: $ctx}}'
