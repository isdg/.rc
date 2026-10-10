#!/usr/bin/env bash
# Module: Darwin system defaults.

[ "$RC_OS" = darwin ] || return 0

source "$RC_BOOT/macos/defaults.sh"
step apply_darwin_defaults ensure_darwin_defaults
