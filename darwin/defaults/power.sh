#!/usr/bin/env bash
# Power management — keep the machine awake with the lid closed (clamshell
# mode) so an external display stays lit, and stop the system from sleeping
# on AC power. Needs sudo; guarded with `|| true` so a missing/declined sudo
# doesn't abort defaults.sh (set -e).
# Revert with: sudo pmset -a disablesleep 0 && sudo pmset -c sleep 1

sudo pmset -a disablesleep 1 || true
sudo pmset -c sleep 0 || true
