#!/usr/bin/env bash
# Module: the keyboard remap (Darwin only).

[ "$RC_OS" = darwin ] || return 0

source "$RC_BOOT/keyremap/keyremap.sh"
step install_keyremap_darwin ensure_keyremap_darwin
