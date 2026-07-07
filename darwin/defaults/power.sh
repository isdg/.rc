#!/usr/bin/env bash
# Power management — keep the machine awake with the lid closed (clamshell
# mode) while on AC power, so an external display stays lit. Needs sudo;
# guarded with `|| true` so a missing/declined sudo doesn't abort defaults.sh
# (set -e). Revert with: sudo pmset -c disablesleep 0

sudo pmset -c disablesleep 1 || true
