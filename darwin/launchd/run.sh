#!/usr/bin/env bash
# Runs one launchd job from $HOME with a login-like PATH, appending its
# output between start and exit lines to ~/Library/Logs/rc/NAME.log.
# The job's exit status is passed back, so launchctl print reports it.
set -uo pipefail

name="${1:?usage: run.sh NAME COMMAND [ARG...]}"
shift
[ "$#" -gt 0 ] || { echo "run.sh: no command for $name" >&2; exit 2; }

log_dir="${RC_JOB_LOG_DIR:-$HOME/Library/Logs/rc}"
log="$log_dir/$name.log"
max_bytes="${RC_JOB_LOG_MAX:-1048576}"

PATH="$HOME/go/bin:$HOME/.cargo/bin:$HOME/.local/bin"
PATH="$PATH:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin"
PATH="$PATH:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

mkdir -p "$log_dir"
if [ -f "$log" ] && [ "$(wc -c < "$log")" -gt "$max_bytes" ]; then
    mv -f "$log" "$log.1"
fi

stamp() { date '+%Y-%m-%dT%H:%M:%S%z'; }

cd "$HOME"
start="$(date +%s)"
echo "== $(stamp) start: $*" >> "$log"
"$@" >> "$log" 2>&1
status=$?
echo "== $(stamp) exit $status after $(($(date +%s) - start))s" >> "$log"
exit "$status"
