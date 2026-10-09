#!/usr/bin/env bash
# Module: Homebrew (Darwin only).

[ "$RC_OS" = darwin ] || return 0

source "$RC_BOOT/homebrew/homebrew.sh"
step install_homebrew ensure_homebrew
